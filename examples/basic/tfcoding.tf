variable "environment" {
  default = "stg"
}

variable "cidr_ab" {
  type = map
  default = {
    "dev": "10.10"
    "stg": "10.11"
    "prd": "10.12"
  }
}

locals {
  cidr_ab = "${lookup(var.cidr_ab, var.environment)}"
  private_subnets = [
    "${local.cidr_ab}.0.0/24",
    "${local.cidr_ab}.1.0/24",
  ]
}
