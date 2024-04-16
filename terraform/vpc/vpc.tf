data "aws_vpc" "ct_vpc_id" {
  filter {
    name   = "tag:Name"
    values = ["aws-controltower-VPC", "${local.env.environment}-${var.project}-vpc"]
  }
}

data "aws_subnets" "ct_pub_subnets" {
  filter {
    name   = "tag:Name"
    values = ["aws-controltower-PublicSubnet*"]
  }
}

data "aws_subnets" "ct_priv_subnets" {
  filter {
    name   = "tag:Name"
    values = ["aws-controltower-PrivateSubnet*"]
  }
}

data "aws_subnets" "ct_database_subnets" {
  filter {
    name   = "tag:Name"
    values = ["aws-controltower-DatabaseSubnet*"]
  }
}

variable "project" {
  default = "explorer"
}

variable "app_name" {
  default = ""
}

# Modules
module "vpclogs_cloudwatch" {
  source                                          = "git::git@github.com:/vechainfoundation/terraform_infrastructure_modules.git//logs?ref=v.1.0.2"
  environment                                     = local.env.environment
  create_flow_log_cloudwatch_log_group            = "true"
  create_flow_log_cloudwatch_iam_role             = "true"
  flow_log_log_format                             = null
  flow_log_traffic_type                           = "ALL"
  vpc_id                                          = data.aws_vpc.ct_vpc_id.id
  flow_log_max_aggregation_interval               = 600
  flow_log_destination_type                       = "cloud-watch-logs"
  flow_log_file_format                            = "plain-text"
  flow_log_hive_compatible_partitions             = "false"
  flow_log_per_hour_partition                     = "false"
  flow_log_cloudwatch_log_group_retention_in_days = 30
  flow_log_cloudwatch_log_group_kms_key_id        = null
  vpc_flow_log_permissions_boundary               = null
  enable_flow_log_cloudwatch                      = "true"
}

module "vpclogs_s3" {
  source                              = "git::git@github.com:/vechainfoundation/terraform_infrastructure_modules.git//logs?ref=v.1.0.2"
  environment                         = local.env.environment
  app_name                            = var.project
  flow_log_log_format                 = null
  flow_log_traffic_type               = "ALL"
  vpc_id                              = data.aws_vpc.ct_vpc_id.id
  flow_log_max_aggregation_interval   = 600
  flow_log_destination_type           = "s3"
  flow_log_file_format                = "plain-text"
  flow_log_hive_compatible_partitions = "false"
  flow_log_per_hour_partition         = "false"
  vpc_flow_log_permissions_boundary   = null
  enable_flow_log_s3                  = "false"
  create_s3_bucket                    = "false"
}
