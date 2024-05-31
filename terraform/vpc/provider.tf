terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = "3.75.1"
    }
  }
  backend "s3" {
    # The S3 backend bucket is configured in '/environments/<env>/backend.config'
    key                  = "explore-vpc.tfstate"
    region               = "eu-west-1"
    workspace_key_prefix = "workspaces"
  }
}

# Import outputs from the explore stack
data "terraform_remote_state" "explore-blue" {
  count = terraform.workspace == "prod" ? 1 : 0 
  backend = "s3"
  config = {
    bucket = "explore-terraform-state-prod"
    key    = "workspaces/prod-blue/explore.tfstate"
    region = "eu-west-1"
  }
}

# Import outputs from the explore stack
data "terraform_remote_state" "explore-green" {
  count = terraform.workspace == "prod" ? 1 : 0
  backend = "s3"
  config = {
    bucket = "explore-terraform-state-prod"
    key    = "workspaces/prod-green/explore.tfstate"
    region = "eu-west-1"
  }
}

# Import outputs from the explore stack
data "terraform_remote_state" "explore-dev" {
  count = terraform.workspace == "dev" ? 1 : 0
  backend = "s3"
  config = {
    bucket = "explore-terraform-state-${terraform.workspace}"
    key    = "workspaces/${terraform.workspace}/explore.tfstate"
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
