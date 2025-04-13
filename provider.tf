terraform {
  # required_version = "~> 1.9.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.90.0"
    }
  }

  backend "s3" {
    encrypt        = true
    bucket         = "corine-remote-state-centralized"
    dynamodb_table = "corine-terraform-locks-centralized-table"
    region         = "us-east-1"
    key            = "state/test/terraform.tfstate"
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