variable "environment" {
  default = "stg"
}

variable "cidr_ab" {
  type = map(string)
  default = {
    "dev" : "10.11"
    "stg" : "10.12"
    "prd" : "10.13"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~>5.4.0"

  name = local.base_name
  cidr = "${local.cidr_ab}.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  tags = local.tags
}


locals {
  # terraform_destroy = true
  base_name = "myapp"
  cidr_ab   = lookup(var.cidr_ab, var.environment)
  private_subnets = [
    "${local.cidr_ab}.0.0/24",
    "${local.cidr_ab}.1.0/24",
  ]
  public_subnets = [
    "${local.cidr_ab}.30.0/24",
    "${local.cidr_ab}.31.0/24",
  ]

  tags = {
    Terraform   = "true"
    Environment = var.environment
  }

  my_value           = module.vpc.vpc_id
  my_subnet          = module.vpc.public_subnets
  my_private_subnets = module.vpc.private_subnets
  my_sg_id           = module.vpc.default_security_group_id
}
