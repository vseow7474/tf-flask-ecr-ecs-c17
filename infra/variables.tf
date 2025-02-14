variable "aws_region" {
  description = "The AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-southeast-1" # Optional: Set default region or leave blank to require explicit definition
}