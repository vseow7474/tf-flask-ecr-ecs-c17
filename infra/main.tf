# Local variable to define prefix for naming resources
locals {
  prefix = "flask-app"
}

# Create an ECR repository
resource "aws_ecr_repository" "ecr" {
  name         = "${local.prefix}-ecr"
  force_delete = true
}

# Use default VPC and subnet IDs
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}

data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

data "aws_region" "current" {}

# Create a security group for ECS tasks in the default VPC
resource "aws_security_group" "ecs_sg" {
  name        = "ecs_security_group"
  description = "Allow inbound traffic for ECS tasks"
  vpc_id      = data.aws_vpc.default.id
}

# ECS Module to provision the ECS cluster and service using Terraform AWS modules
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${local.prefix}-ecs"

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    "flask-app-service" = { # ECS service name -> Change
      cpu    = 512
      memory = 1024
      container_definitions = {
        "flask-app-container" = { # Container name -> Change
          essential = true
          image     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${local.prefix}-ecr:latest"
          port_mappings = [
            {
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = data.aws_subnets.default.ids # Use default subnets
      security_group_ids                 = [aws_security_group.ecs_sg.id]  # Reference to the security group
    }
  }
}

# Output the ECR repository URL for reference
output "ecr_repository_url" {
  value = aws_ecr_repository.ecr.repository_url
}

# Output the ECS cluster name for reference
output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

# Output the ECS service name for reference
output "ecs_service_name" {
  value = "flask-app-service"
}