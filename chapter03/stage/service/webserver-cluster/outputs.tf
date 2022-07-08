output "alb_dns_name" {
  value       = aws_alb.TEST.dns_name
  description = "The domain name of the load balancer"
}

