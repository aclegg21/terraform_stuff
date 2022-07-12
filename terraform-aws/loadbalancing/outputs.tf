# --- loadbalancing/outputs.tf ---

output "lb_target_group_arn" {
  value = aws_lb_target_group.ac_tg.arn
}

output "lb_endpoint" {
  value = aws_lb.ac_lb.dns_name
}