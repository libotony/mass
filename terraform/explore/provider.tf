terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "3.75.1"
    }
  }

  backend "s3" {
    # The S3 backend bucket is configured in '../environments/<env>/backend.config'
    key                  = "explore.tfstate"
    region               = "eu-west-1"
    workspace_key_prefix = "workspaces"
  }
}

provider "aws" {
  region = local.env.region
  default_tags {
    tags = {
      Terraform   = "true"
      Project     = var.project
    }
  }
}

//create aws provider alias for us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform   = "true"
      Project     = var.project
    }
  }
}

provider "awscc" {
  region = local.env.region
}

provider "github" {}

provider "random" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_elb_service_account" "default" {}

data "external" "git" {
  program = ["git", "log", "--pretty=format:{ \"sha\": \"%H\" }", "-1", "HEAD"]
}

# Import outputs from the vpc module
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = startswith(local.env.environment, "prod-") ? "explore-terraform-state-prod" : "explore-terraform-state-dev"
    key    = "workspaces/${startswith(local.env.environment, "prod-") ? "prod" : local.env.environment}/explore-vpc.tfstate"
    region = "eu-west-1"
  }
}
