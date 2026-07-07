variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the public subnets"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private app subnets (EKS)"
}

variable "private_data_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the private data subnets (RDS, ElastiCache, MQ)"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the subnets"
}
