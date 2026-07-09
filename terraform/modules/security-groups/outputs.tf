output "alb_sg_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group"
}

output "eks_nodes_sg_id" {
  value       = aws_security_group.eks_nodes.id
  description = "The ID of the EKS worker nodes security group"
}

output "rds_sg_id" {
  value       = aws_security_group.rds.id
  description = "The ID of the RDS security group"
}

output "redis_sg_id" {
  value       = aws_security_group.elasticache.id
  description = "The ID of the ElastiCache security group"
}

output "mq_sg_id" {
  value       = aws_security_group.mq.id
  description = "The ID of the Amazon MQ security group"
}
