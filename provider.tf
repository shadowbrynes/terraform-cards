terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary Region (us-east-1) - Default
provider "aws" {
  region = var.aws_region_primary
}

# Secondary Region alias matching state (us-east-2)
provider "aws" {
  alias  = "us_east_2"
  region = var.aws_region_secondary
}

# Tertiary Region alias matching state (eu-west-1)
provider "aws" {
  alias  = "eu_west_1"
  region = var.aws_region_tertiary
}
