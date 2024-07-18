module "datadog_integration_aws" {
  source              = "git::git@github.com:vechain/terraform_infrastructure_modules.git//datadog?ref=v.1.0.50"
  enable_datadog_integration_aws = terraform.workspace == "prod" ? true : false
  project_name        = "explore-prod"
  role_name           = "DatadogAWSIntegrationRole"
  aws_permissions_list = [
                "apigateway:GET",
                "autoscaling:Describe*",
                "cloudfront:GetDistributionConfig",
                "cloudfront:ListDistributions",
                "cloudtrail:DescribeTrails",
                "cloudtrail:GetTrailStatus",
                "cloudtrail:LookupEvents",
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*",
                "elasticloadbalancing:Describe*",
                "events:CreateEventBus",
                "health:DescribeEvents",
                "health:DescribeEventDetails",
                "health:DescribeAffectedEntities",
                "lambda:GetPolicy",
                "lambda:List*",
                "logs:DeleteSubscriptionFilter",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:DescribeSubscriptionFilters",
                "logs:FilterLogEvents",
                "logs:PutSubscriptionFilter",
                "logs:TestMetricFilter",
                "route53:List*",
                "s3:GetBucketLogging",
                "s3:GetBucketLocation",
                "s3:GetBucketNotification",
                "s3:GetBucketTagging",
                "s3:ListAllMyBuckets",
                "s3:PutBucketNotification",
                "sqs:ListQueues",
                "states:ListStateMachines",
                "states:DescribeStateMachine",
                "tag:GetResources",
                "tag:GetTagKeys",
                "tag:GetTagValues",
  ]

  filter_tags          = []
  host_tags            = ["project:${var.project}"]
  excluded_regions     = ["us-east-2, us-west-1, us-west-2, ca-central-1, eu-west-2, eu-west-3, eu-central-1, eu-north-1, ap-south-1, ap-northeast-1, ap-northeast-2, ap-southeast-1, ap-southeast-2, sa-east-1"]
  secret_id             = local.env.datadog_secret_arn

  create_api_gateway_group   = false
  create_ecs_group           = true
  create_elb_group           = true
  create_s3_group            = false
  create_lambda_group        = false
  create_cloudfront_group    = false
  create_dynamodb_group      = false
  create_monitor             = false 
  create_custom_widget_group = false
  create_synthetics_monitor  = terraform.workspace == "prod" ? true : false
  create_dynamic_dashboard   = terraform.workspace == "prod" ? true : false

  monitors = {
  }

  synthetics_monitors = {
    monitor_1 = {
    synthetics_monitor_name               = "Status for explore-testnet.vechain.org/"
    synthetics_monitor_message            =  "Notifying @slack-explore-alerting \n\n{{#is_alert}}\nhttps://explore-testnet.vechain.org/ is down.\n{{/is_alert}}\n\n{{#is_recovery}}\nhttps://explore-testnet.vechain.org/ has recovered.\n{{/is_recovery}}\n\n\n\n"
    synthetics_monitor_locations          = ["aws:ap-east-1", "aws:ap-northeast-1", "aws:ap-northeast-2", "aws:ap-northeast-3", "aws:ap-south-1", "aws:ap-southeast-1", "aws:ap-southeast-2", "aws:ap-southeast-3", "aws:ca-central-1", "aws:eu-central-1", "aws:eu-north-1", "aws:eu-south-1", "aws:eu-west-1", "aws:eu-west-2", "aws:eu-west-3", "aws:me-south-1", "aws:sa-east-1", "aws:us-east-1", "aws:us-east-2", "aws:us-west-1", "aws:us-west-2", "azure:eastus"]
    synthetics_monitor_url                = "https://explore-testnet.vechain.org/"
    synthetics_monitor_tags               = ["team:explore"]
    },
    monitor_2 = {
    synthetics_monitor_name               = "Status for explore.vechain.org/"
    synthetics_monitor_message            =  "Notifying @slack-explore-alerting \n\n{{#is_alert}}\nhttps://explore.vechain.org// is down.\n{{/is_alert}}\n\n{{#is_recovery}}\nhttps://explore.vechain.org/ has recovered.\n{{/is_recovery}}\n\n\n\n"
    synthetics_monitor_locations          = ["aws:ap-east-1", "aws:ap-northeast-1", "aws:ap-northeast-2", "aws:ap-northeast-3", "aws:ap-south-1", "aws:ap-southeast-1", "aws:ap-southeast-2", "aws:ap-southeast-3", "aws:ca-central-1", "aws:eu-central-1", "aws:eu-north-1", "aws:eu-south-1", "aws:eu-west-1", "aws:eu-west-2", "aws:eu-west-3", "aws:me-south-1", "aws:sa-east-1", "aws:us-east-1", "aws:us-east-2", "aws:us-west-1", "aws:us-west-2", "azure:eastus"]
    synthetics_monitor_url                = "https://explore.vechain.org/"
    synthetics_monitor_tags               = ["team:explore"]
    }
  }
}