# ECS Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.environment}_cluster"
}

# ECS Task Definitions
data "aws_ecs_task_definition" "service" {
  task_definition = "${aws_ecs_task_definition.service.family}"
  depends_on      = ["aws_ecs_task_definition.service"]
}

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "${aws_iam_role.ECSTaskExecutionRole.arn}"
  depends_on               = ["var.db_instance"]

  container_definitions = <<DEFINITION
[
  {
    "cpu": 256,
    "image": "${var.image}",
    "memory": 512,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.log_group.name}",
        "awslogs-region": "${var.awslogs_region}",
        "awslogs-stream-prefix": "apache_log"
      }
    },
    "name": "${var.environment}",
    "network_mode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "protocol": "TCP"
      }
    ]
  }
]
DEFINITION
}

# ECS Service
resource "aws_ecs_service" "mongo" {
  name                               = "${var.environment}"
  cluster                            = "${aws_ecs_cluster.ecs_cluster.id}"
  task_definition                    = "${aws_ecs_task_definition.service.id}"
  desired_count                      = 2
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 70

  network_configuration {
    assign_public_ip = false
    security_groups  = ["${var.app_sg_id}"]
    subnets          = ["${var.private_subnet1}", "${var.private_subnet2}"]
  }

  load_balancer {
    target_group_arn = "${var.load_balancer_target_group_arn}"
    container_name   = "${var.environment}"
    container_port   = 80
  }
}

# CloudWatch
resource "aws_cloudwatch_log_group" "log_group" {
  name              = "/ecs/${var.environment}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "log_stream" {
  name           = "${var.environment}-log-stream"
  log_group_name = "${aws_cloudwatch_log_group.log_group.name}"
}

# Auto Scaling
resource "aws_appautoscaling_target" "ECSScalableTarget" {
  max_capacity       = 6
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.name}/${aws_ecs_service.mongo.name}"
  role_arn           = "${aws_iam_role.ECSTaskExecutionRole.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ECSScaleUpPolicy" {
  name               = "ECSScaleUpPolicy"
  resource_id        = "${aws_appautoscaling_target.ECSScalableTarget.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ECSScalableTarget.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ECSScalableTarget.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.ECSScalableTarget"]
}

resource "aws_appautoscaling_policy" "ECSScaleDownPolicy" {
  name               = "ECSScaleDownPolicy"
  resource_id        = "${aws_appautoscaling_target.ECSScalableTarget.resource_id}"
  scalable_dimension = "${aws_appautoscaling_target.ECSScalableTarget.scalable_dimension}"
  service_namespace  = "${aws_appautoscaling_target.ECSScalableTarget.service_namespace}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.ECSScalableTarget"]
}

# CloudWatch of Auto Scaling
resource "aws_cloudwatch_metric_alarm" "CPU_Utilization_High" {
  alarm_name          = "${var.environment}-CPU-Utilization-High-${var.ecs_as_cpu_high_threshold_per}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.ecs_as_cpu_high_threshold_per}"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.mongo.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.ECSScaleUpPolicy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "CPU_Utilization_Low" {
  alarm_name          = "${var.environment}-CPU-Utilization-Low-${var.ecs_as_cpu_low_threshold_per}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "${var.ecs_as_cpu_low_threshold_per}"

  dimensions = {
    ClusterName = "${aws_ecs_cluster.ecs_cluster.name}"
    ServiceName = "${aws_ecs_service.mongo.name}"
  }

  alarm_actions = ["${aws_appautoscaling_policy.ECSScaleDownPolicy.arn}"]
}

# ECS TaskExecution Role
resource "aws_iam_role" "ECSTaskExecutionRole" {
  name = "ECSTaskExecutionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# TaskExecution Policy
resource "aws_iam_policy" "AmazonECSTaskExecutionRolePolicy" {
  name        = "AmazonECSTaskExecutionRolePolicy"
  path        = "/"
  description = "Created Policy for ECS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# ECS TaskExecution Attachment
resource "aws_iam_role_policy_attachment" "ECS-attach" {
  role       = "${aws_iam_role.ECSTaskExecutionRole.name}"
  policy_arn = "${aws_iam_policy.AmazonECSTaskExecutionRolePolicy.arn}"
}
