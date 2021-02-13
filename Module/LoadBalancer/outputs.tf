#-------LoadBalancer/outputs.tf
output "lb_dns_name" {
  value = aws_lb.load_balancer.dns_name
}
output "lb_zone_id" {
  value = aws_lb.load_balancer.zone_id
}
output "load_balancer_arn" {
  value = aws_lb.load_balancer.arn
}
output "load_balancer_target_group_arn" {
  value = aws_lb_target_group.front_end.arn
}
