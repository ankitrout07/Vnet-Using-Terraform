# variables.tf

variable "aws_region" {
  description = "Target region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "Base CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "project_name" {
  type    = string
  default = "Fortress-VPC"
}