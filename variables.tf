## Application Parameters ##
variable "application_name" {
  description = "Application Name to use as Prefix"
  type        = string
  default     = "timeline"
}

## Environment Parameters ##
variable "tenant" {
  description = "Tenant's Name: cxp, cable -- Previously Partner Name."
  type        = string
}

variable "environment_type" {
  description = "Environment Type: dev, stg, or prod"
  type        = string
  default     = "dev"
}

## AWS Account Parameters ##
variable "aws_account" {
  description = "AWS Account Number for resource deployment"
  type        = string
}

variable "aws_region" {
  description = "Specifies in which AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
