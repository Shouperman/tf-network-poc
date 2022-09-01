### Set Required Providers ###
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.13"
    }
  }
}

### Set Provider Details ###
## Terraform requires a non-aliased default provider ##
provider "aws" {
  profile = "${var.application_name}-${var.tenant}"
  region  = var.aws_region
}
