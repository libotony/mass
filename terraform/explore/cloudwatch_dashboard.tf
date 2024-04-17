locals {
  dashboard_body = {
    "widgets" : [
      for k, v in merge({ for k, v in module.ecs-backend-service-chain-scanner : v.service_name => v.cluster_name }, {
        for k, v in module.ecs-lb-service-mass : v.service_name => v.cluster_name
        }) : {
        "type" : "metric",
        "x" : 0,
        "y" : 0,
        "width" : 12,
        "height" : 6,
        "properties" : {
          "metrics" : [
            ["AWS/ECS", "CPUUtilization", "ServiceName", k, "ClusterName", v],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          region : "${local.env.region}",
          "stat" : "Maximum",
          "period" : 300,
          "title" : "${k} CPU and Memory",
          "legend" : {
            "position" : "bottom"
          },
          "yAxis" : {
            "left" : {
              "min" : 0,
              "max" : 100
            },
            "right" : {
              "min" : 0,
              "max" : 100
            }
          }
        }
      }
    ],
    "start" : "-PT3H",
    "end" : "P0D"
  }
}


module "aws_cloudwatch_dashboard" {
  source                      = "git::git@github.com:/vechainfoundation/terraform_infrastructure_modules.git//cloudwatchdashboard?ref=v.1.0.2"
  create_cloudwatch_dashboard = true
  dashboard_name              = "veworld-indexer-${local.env.environment}-dashboard"
  dashboard_body              = jsonencode(local.dashboard_body)
}
