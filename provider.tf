# provider.tf

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-terraform-mgmt-prod"
    storage_account_name = "<YOUR_AZURE_STORAGE_ACCOUNT_NAME>"
    container_name       = "tfstate"
    key                  = "vpc-fortress.terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}