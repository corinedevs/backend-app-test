terraform {
  required_version = "~> 1.9.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      TICKET = var.ticket
      OWNER  = var.owner
    }
  }
}