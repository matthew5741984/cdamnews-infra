# Application Load Balancer
resource "aws_lb" "load_balancer" {
  name               = "${var.environment}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.elb_sg_id}"]
  subnets            = ["${var.public_subnet1}", "${var.public_subnet2}"]

  enable_deletion_protection = false

  tags = {
    Environment = "${var.environment}-lb"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.front_end.arn}"
  }
}

# Load Balancer Target Group
resource "aws_lb_target_group" "front_end" {
  name     = "${var.environment}-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    port                = 80
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    matcher             = "200-299"
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 1800
    enabled         = true
  }

  target_type = "ip"
}
