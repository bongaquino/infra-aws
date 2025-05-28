variable "vpc_id" {
  description = "The VPC ID to launch the EC2 instance into."
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID for the EC2 instance."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to associate with the EC2 instance."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the instance."
  type        = string
}

variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "koneksi"
}

variable "environment" {
  description = "Deployment environment (e.g., staging, uat, prod)"
  type        = string
} 