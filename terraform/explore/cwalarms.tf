# Simple alarms for CloudWatch constructed from sub maps as local variables, merged into a simple_alarms_map
# NB each submap element must have a unique key or it may be overwritten in the merge
locals {
  ##############################################################################################################
  # Explorer Alarms - Load Balanced ECS Service
  ##############################################################################################################
  elb_response_alarm_explore = { for k, v in module.ecs-lb-service-explore : "${v.service_name}_slo_req" => {
    alarm_name          = "${v.service_name}_response_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 1000
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Maximum"
    metric_name         = "TargetResponseTime"
    alarm_description   = "ELB Target slow responses"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
    }
    }
  }

  elb_5xx_count_alarm_explore = { for k, v in module.ecs-lb-service-explore : "${v.service_name}_hi_5xx" => {
    alarm_name          = "${v.service_name}_5xx_count_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 1
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "HTTPCode_ELB_5XX_Count"
    alarm_description   = "ELB 5XX error count"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
    }
    }
  }

  elb_connect_rate_alarm_explore = { for k, v in module.ecs-lb-service-explore : "${v.service_name}_hi_conn" => {
    alarm_name          = "${v.service_name}_connect_rate_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 100
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "NewConnectionCount"
    alarm_description   = "ELB connection rate"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
    }
    }
  }

  elb_low_health_alarm_explore = { for k, v in module.ecs-lb-service-explore : "${v.service_name}_lo_h" => {
    alarm_name          = "${v.service_name}_low_health_alarm"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 3
    threshold           = 1
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "HealthyHostCount"
    alarm_description   = "ELB TG no healthy hosts"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
      TargetGroup  = split(":", v.alb_tg)[5]
    }
    }
  }

  elb_hi_unhealthy_alarm_explore = { for k, v in module.ecs-lb-service-explore : "${v.service_name}_hi_unh" => {
    alarm_name          = "${v.service_name}_hi_unhealthy_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 1
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "UnHealthyHostCount"
    alarm_description   = "ELB TG hi unhealthy hosts"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
      TargetGroup  = split(":", v.alb_tg)[5]
    }
    }
  }

  ecs_service_highcpu_alarm_explore = {
    for k, v in module.ecs-lb-service-explore : "${v.service_name}_hicpu" => {
      alarm_name          = "${v.service_name}_highcpu_alarm"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 75
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      alarm_description   = "${v.service_name} high CPU load"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
    }
  }

  ecs_service_highmem_alarm_explore = {
    for k, v in module.ecs-lb-service-explore : "${v.service_name}_himem" => {
      alarm_name          = "${v.service_name}_highmem_alarm"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 75
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "MemoryUtilization"
      alarm_description   = "${v.service_name} high memory consumption"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
    }
  }

  ecs_service_lowcpu_alarm_explore = {
    for k, v in module.ecs-lb-service-explore : "${v.service_name}_lowcpu" => {
      alarm_name          = "${v.service_name}_lowcpu_alarm"
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 0
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      alarm_description   = "${v.service_name} low CPU load"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
      treat_missing_data = "breaching"
    }
  }

  ecs_service_lowmem_alarm_explore = {
    for k, v in module.ecs-lb-service-explore : "${v.service_name}_lowmem" => {
      alarm_name          = "${v.service_name}_lowmem_alarm"
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 1
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "MemoryUtilization"
      alarm_description   = "${v.service_name} low memory consumption"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
      treat_missing_data = "breaching"
    }
  }

  ##############################################################################################################
  # Mass Alarms - Load Balanced ECS Service
  ##############################################################################################################

  elb_response_alarm_mass = { for k, v in module.ecs-lb-service-mass : "${v.service_name}_slo_req" => {
    alarm_name          = "${v.service_name}_response_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 1000
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Maximum"
    metric_name         = "TargetResponseTime"
    alarm_description   = "ELB Target slow responses"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
    }
    }
  }

  elb_5xx_count_alarm_mass = { for k, v in module.ecs-lb-service-mass : "${v.service_name}_hi_5xx" => {
    alarm_name          = "${v.service_name}_5xx_count_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 1
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "HTTPCode_ELB_5XX_Count"
    alarm_description   = "ELB 5XX error count"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
    }
    }
  }

  elb_connect_rate_alarm_mass = { for k, v in module.ecs-lb-service-mass : "${v.service_name}_hi_conn" => {
    alarm_name          = "${v.service_name}_connect_rate_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 100
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "NewConnectionCount"
    alarm_description   = "ELB connection rate"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
    }
    }
  }

  elb_low_health_alarm_mass = { for k, v in module.ecs-lb-service-mass : "${v.service_name}_lo_h" => {
    alarm_name          = "${v.service_name}_low_health_alarm"
    comparison_operator = "LessThanThreshold"
    evaluation_periods  = 3
    threshold           = 1
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "HealthyHostCount"
    alarm_description   = "ELB TG no healthy hosts"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
      TargetGroup  = split(":", v.alb_tg)[5]
    }
    }
  }

  elb_hi_unhealthy_alarm_mass = { for k, v in module.ecs-lb-service-mass : "${v.service_name}_hi_unh" => {
    alarm_name          = "${v.service_name}_hi_unhealthy_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 3
    threshold           = 1
    namespace           = "AWS/ApplicationELB"
    period              = 180
    statistic           = "Average"
    metric_name         = "UnHealthyHostCount"
    alarm_description   = "ELB TG hi unhealthy hosts"
    dimensions = {
      LoadBalancer = substr(split(":", v.alb_arn)[5], 13, -1)
      TargetGroup  = split(":", v.alb_tg)[5]
    }
    }
  }

  ecs_service_highcpu_alarm_mass = {
    for k, v in module.ecs-lb-service-mass : "${v.service_name}_hicpu" => {
      alarm_name          = "${v.service_name}_highcpu_alarm"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 75
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      alarm_description   = "${v.service_name} high CPU load"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
    }
  }

  ecs_service_highmem_alarm_mass = {
    for k, v in module.ecs-lb-service-mass : "${v.service_name}_himem" => {
      alarm_name          = "${v.service_name}_highmem_alarm"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 75
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "MemoryUtilization"
      alarm_description   = "${v.service_name} high memory consumption"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
    }
  }

  ecs_service_lowcpu_alarm_mass = {
    for k, v in module.ecs-lb-service-mass : "${v.service_name}_lowcpu" => {
      alarm_name          = "${v.service_name}_lowcpu_alarm"
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 0
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      alarm_description   = "${v.service_name} low CPU load"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
      treat_missing_data = "breaching"
    }
  }

  ecs_service_lowmem_alarm_mass = {
    for k, v in module.ecs-lb-service-mass : "${v.service_name}_lowmem" => {
      alarm_name          = "${v.service_name}_lowmem_alarm"
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 1
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "MemoryUtilization"
      alarm_description   = "${v.service_name} low memory consumption"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
      treat_missing_data = "breaching"
    }
  }

  ##############################################################################################################
  # Chain Scanner Alarms - Backend ECS Service
  ##############################################################################################################

  ecs_backend_highcpu_alarm_cs = {
    for k, v in module.ecs-backend-service-chain-scanner : "${v.service_name}_hicpu" => {
      alarm_name          = "${v.service_name}_highcpu_alarm"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 75
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      alarm_description   = "${v.service_name} high CPU load"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
    }
  }

  ecs_backend_highmem_alarm_cs = {
    for k, v in module.ecs-backend-service-chain-scanner : "${v.service_name}_himem" => {
      alarm_name          = "${v.service_name}_highmem_alarm"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 75
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "MemoryUtilization"
      alarm_description   = "${v.service_name} high memory consumption"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
    }
  }

  ecs_backend_lowcpu_alarm_cs = {
    for k, v in module.ecs-backend-service-chain-scanner : "${v.service_name}_lowcpu" => {
      alarm_name          = "${v.service_name}_lowcpu_alarm"
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 0
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "CPUUtilization"
      alarm_description   = "${v.service_name} low CPU load"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
      treat_missing_data = "breaching"
    }
  }

  ecs_backend_lowmem_alarm_cs = {
    for k, v in module.ecs-backend-service-chain-scanner : "${v.service_name}_lowmem" => {
      alarm_name          = "${v.service_name}_lowmem_alarm"
      comparison_operator = "LessThanOrEqualToThreshold"
      evaluation_periods  = 3
      threshold           = 1
      namespace           = "AWS/ECS"
      period              = 300
      statistic           = "Average"
      metric_name         = "MemoryUtilization"
      alarm_description   = "${v.service_name} low memory consumption"
      dimensions = {
        ServiceName = v.service_name
        ClusterName = module.ecs-cluster.name
      }
      treat_missing_data = "breaching"
    }
  }

  ecs_highcpu_alarms = merge(
    local.ecs_service_highcpu_alarm_explore,
    local.ecs_service_highcpu_alarm_mass,
    local.ecs_backend_highcpu_alarm_cs
  )

  ecs_highmem_alarms = merge(
    local.ecs_service_highmem_alarm_explore,
    local.ecs_service_highmem_alarm_mass,
    local.ecs_backend_highmem_alarm_cs
  )

  ecs_lowcpu_alarms = merge(
    local.ecs_service_lowcpu_alarm_explore,
    local.ecs_service_lowcpu_alarm_mass,
    local.ecs_backend_lowcpu_alarm_cs
  )

  ecs_lowmem_alarms = merge(
    local.ecs_service_lowmem_alarm_explore,
    local.ecs_service_lowmem_alarm_mass,
    local.ecs_backend_lowmem_alarm_cs
  )

  log_metric_alarm = { for k in concat(
    flatten([for k, v in module.ecs-backend-service-chain-scanner : v.log_metric_names]),
    flatten([for k, v in module.ecs-lb-service-explore : v.log_metric_names]),
    flatten([for k, v in module.ecs-lb-service-mass : v.log_metric_names])) : "${k}_lma" => {
    alarm_name          = "${k}_logmetric_alarm"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    threshold           = 2
    namespace           = "LogMetrics"
    period              = 180
    stat                = "Sum"
    statistic           = "Sum"
    metric_name         = k
    alarm_description   = "${k}-AppUnhealthy log metric"
    }
  }

  simple_alarms_map = merge(
    local.elb_response_alarm_explore,
    local.elb_5xx_count_alarm_explore,
    local.elb_connect_rate_alarm_explore,
    local.elb_low_health_alarm_explore,
    local.elb_hi_unhealthy_alarm_explore,
    local.elb_response_alarm_mass,
    local.elb_5xx_count_alarm_mass,
    local.elb_connect_rate_alarm_mass,
    local.elb_low_health_alarm_mass,
    local.elb_hi_unhealthy_alarm_mass,
    local.ecs_highcpu_alarms,
    local.ecs_highmem_alarms,
    local.ecs_lowcpu_alarms,
    local.ecs_lowmem_alarms,
    local.log_metric_alarm,
  )
}

# Expression alarms for CloudWatch constructed from sub maps as local variables, merged into a expressions_alarms_map
# NB each submap element must have a unique key or it may be overwritten in the merge
locals {
  expression_alarms_map = merge()
}

module "cloud_watch_alarms" {
  source                   = "git::git@github.com:/vechainfoundation/terraform_infrastructure_modules.git//cloudwatchalarm?ref=v.1.0.32"
  sns_topic_enabled        = true
  topic_name               = "${local.env.environment}-CloudWatchAlarms"
  email_subscriptions      = []
  create_slack_integration = true
  configuration_name       = substr("${local.env.environment}-${var.project}", 0, 28)

  slack_channel_id   = local.env.slack_alert_channel
  slack_workspace_id = local.env.slack_alert_workspace

  simple_alarms     = local.simple_alarms_map
  expression_alarms = local.expression_alarms_map
}
