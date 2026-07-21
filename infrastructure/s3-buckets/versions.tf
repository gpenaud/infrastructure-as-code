terraform {
  required_version = ">= 1.6"
  
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 2.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
