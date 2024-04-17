terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "3.75.1"
    }
  }
  backend "s3" {
    # The states of DEV and PROD environments are stored in separate S3 buckets in their
    # respective AWS accounts. The {{{ENV}}} placeholder is replaced manually (dev/prod)
    bucket               = "explore-terraform-state-dev"
    key                  = "explore-vpc.tfstate"
    region               = "eu-west-1"
    workspace_key_prefix = "workspaces"
  }
}

# Import outputs from the explore stack
# data "terraform_remote_state" "explore-blue" {
#   backend = "s3"
#   config = {
#     bucket = "explore-terraform-state-prod"
#     key    = "workspaces/prod-blue/explore.tfstate"
#     region = "eu-west-1"
#   }
# }

# # Import outputs from the explore stack
# data "terraform_remote_state" "explore-green" {
#   backend = "s3"
#   config = {
#     bucket = "explore-terraform-state-prod"
#     key    = "workspaces/prod-green/explore.tfstate"
#     region = "eu-west-1"
#   }
# }

# Import outputs from the explore stack
data "terraform_remote_state" "explore-dev" {
  backend = "s3"
  config = {
    bucket = "explore-terraform-state-dev"
    key    = "workspaces/dev/explore.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = local.env.region
  default_tags {
    tags = {
      Terraform = "true"
      Project   = var.project
    }
  }
}

//create aws provider alias for us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = {
      Terraform = "true"
      Project   = var.project
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
