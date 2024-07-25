variable "project" {
  default = "explore"
}

variable "app_name" {
  default = ""
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  name = "${local.env.environment}.${var.project}"
  vpc  = local.env.vpc_id
}

locals {
  container_commands = flatten([
    for network, config in local.env.networks : [
      for i, cmd in range(length(config.container_commands)) : {
        index         = "${network}-${i}"
        command       = config.container_commands[i]
        common_config = config.common_config
        network       = network
      }
    ]
  ])
}

data "aws_ssm_parameter" "captcha_secret" {
  name = startswith(local.env.environment, "prod") ? "/prod/explorer/captcha_secret" : "/${local.env.environment}/explorer/captcha_secret"
}

######################
# Public ALB Security Group
######################

resource "aws_security_group" "alb-sg" {
  description = "security-group-alb"
  name        = "${local.env.environment}-${var.project}-sg-alb"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
  }

  tags = {
    Environment = local.env.environment
    Name        = "${local.env.environment}-${var.project}-sg-alb"
  }
  vpc_id = local.env.vpc_id
}

######################
# Internal ALB Security Group
######################

resource "aws_security_group" "internal-alb-sg" {
  description = "security-group-internal-alb"
  name        = "${local.env.environment}-${var.project}-sg-internal-alb"
  egress {
    security_groups = [aws_security_group.ecs_service_sg.id]
    description     = "ECS Service Security Group"
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
  }

  ingress {
    security_groups = [aws_security_group.ecs_service_sg.id]
    description     = "ECS Service Security Group"
    from_port       = 0
    protocol        = "-1"
    to_port         = 0
  }

  tags = {
    Environment = local.env.environment
    Name        = "${local.env.environment}-${var.project}-sg-internal-alb"
  }
  vpc_id = local.env.vpc_id
}

######################
# ECS Service Security Group
######################

resource "aws_security_group" "ecs_service_sg" {
  description = "security-group-service"

  name = "${local.env.environment}-${var.project}-sg-service"
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self      = true
  }

  tags = {
    Environment = local.env.environment
    Name        = "${local.env.environment}-${var.project}-sg-service"
  }

  vpc_id = local.env.vpc_id
}

################################################################################
# Module For ECS Cluster creation
################################################################################

module "ecs-cluster" {
  # temporary filter to avoid deployment of new ECS cluster from original prod workspace
  source  = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs_cluster?ref=v.1.0.34"
  env     = local.env.environment
  project = var.project
  vpc_id  = local.env.vpc_id
  cidr    = local.env.cidr
}

################################################################################
# Module For ECS Cluster Capacity Providers
################################################################################

resource "aws_ecs_cluster_capacity_providers" "ecs_capacity_provider" {
  count = local.env.environment == "dev" ? 1 : 0
  cluster_name = module.ecs-cluster.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 0
    weight            = 100
    capacity_provider = "FARGATE_SPOT"
  }
}

################################################################################
# Module For ECS Load Balanced Service mass
################################################################################

module "ecs-lb-service-mass" {
  depends_on                 = [module.ecs-cluster, resource.aws_security_group.ecs_service_sg, resource.aws_security_group.alb-sg, module.rds]
  for_each                   = local.env.networks
  source                     = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs-loadbalanced-webservice?ref=v.1.0.34"
  region                     = local.env.region
  vpc_id                     = local.env.vpc_id
  cluster_name               = module.ecs-cluster.name
  autoscale_cluster_name     = module.ecs-cluster.name
  lb_subnets                 = local.env.private_subnets
  internal_alb               = true
  app_subnets                = local.env.private_subnets
  env                        = local.env.environment
  is_create_repo             = false
  ecr_repo_uri               = each.value.common_config.mass.ecr_common_repo
  secrets_enable             = false
  assign_public_ip           = false
  app_name                   = "${each.key}-mass"
  ecr_image_tag              = local.env.image_tag
  project                    = var.project
  cpu                        = each.value.common_config.mass.cpu
  memory                     = each.value.common_config.mass.memory
  cidr                       = local.env.cidr
  container_port             = 8080
  certificate_arn            = local.env.certificate_arn
  ecs_sg                     = [aws_security_group.ecs_service_sg.id]
  rule_0_path_pattern        = ["/api/v*", "/api-docs", "/swagger-ui/*"]
  alb_sg                     = [aws_security_group.internal-alb-sg.id]
  idle_timeout               = 60
  enable_deletion_protection = startswith(local.env.environment, "prod") ? true : false
  namespace_id               = aws_service_discovery_private_dns_namespace.ns.id
  https_tg_healthcheck_path  = "/api/chain/head"
  environment_variables = [
    {
      name  = "APPLICATION_NAME"
      value = "mass"
    },
    {
      name  = "ENVIRONMENT_NAME"
      value = local.env.environment
    },
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = each.value.common_config.mass.spring_profile
    },
    {
      name  = "APP_LOG_LEVEL"
      value = "INFO"
    },
    {
      name  = "THOR_URL"
      value = each.value.common_config.thor_url
    },
    {
      name  = "APP_LOGGER"
      value = "CloudWatch"
    },
    {
      name  = "TYPEORM_CONNECTION"
      value = "mysql"
    },
    {
      name  = "TYPEORM_HOST"
      value = module.rds[each.key].db_address
    },
    {
      name  = "TYPEORM_PORT"
      value = module.rds[each.key].db_port
    },
    {
      name  = "TYPEORM_USERNAME"
      value = module.rds[each.key].db_username
    },
    {
      name  = "TYPEORM_PASSWORD"
      value = module.rds[each.key].rds_master_password_ssm_value
    },
    {
      name  = "TYPEORM_DATABASE"
      value = each.value.common_config.mysql.db_name
    },
    {
      name  = "TYPEORM_ENTITIES"
      value = "dist/explorer-db/entity/*.js"
    },
    {
      name  = "THOR_REST"
      value = each.value.common_config.thor_rest_url
    },
    {
      name  = "NETWORK"
      value = "${each.key}net"
    },
    {
      name  = "NODE_ENV"
      value = "production"
    },
  ]
  log_metric_filters = [
    {
      name    = "AppUnhealthy",
      pattern = "Application is UNHEALTHY"
    }
  ]

  ####### enable autoscailing #######
  enable_ecs_cpu_based_autoscaling    = true
  enable_ecs_memory_based_autoscaling = true
  min_capacity                        = 1
  max_capacity                        = each.value.common_config.mass.max_capacity
  target_cpu_value                    = 70
  target_memory_value                 = 70
  disable_scale_in                    = false
  # scale_in_cooldown = 300
  # scale_out_cooldown = 300
  name = "auto-scaling-group"
}


################################################################################
# Module For ECS Non-Load Balanced Service chain-scanner
################################################################################
module "ecs-backend-service-chain-scanner" {
  depends_on       = [module.ecs-cluster]
  for_each         = {for config_obj in local.container_commands : config_obj.index => config_obj}
  source           = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs-backend-service?ref=v.1.0.35"
  vpc_id           = local.env.vpc_id
  region           = local.env.region
  cluster          = module.ecs-cluster.name
  subnets          = concat(local.env.private_subnets)
  env              = local.env.environment
  is_create_repo   = false
  ecr_repo_uri     = each.value.common_config.chain-scanner.ecr_common_repo
  secrets_enable   = false
  ecr_image_tag    = local.env.image_tag
  command          = each.value.command
  app_name         = "${each.value.network}-chain-scanner-${each.value.command[length(each.value.command) -1]}"
  project          = var.project
  cpu              = each.value.common_config.chain-scanner.cpu
  memory           = each.value.common_config.chain-scanner.memory
  cidr             = local.env.cidr
  security_groups  = [aws_security_group.ecs_service_sg.id]
  desired_capacity = "1"
  containerPort    = 8080
  hostPort         = 8080
  # 'omit' below allows ECS to schedule tasks according to capacity providers ie FARGATE_SPOT
  launch_type      = local.env.environment == "dev" ? "omit" : "FARGATE"
  namespace_id     = aws_service_discovery_private_dns_namespace.ns.id
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100
  runtime_platform = [{
    operating_system_family = "LINUX",
    cpu_architecture        = "X86_64"
  }]
  log_metric_filters = [
    {
      name    = "AppUnhealthy"
      pattern = "Application is UNHEALTHY"
    }
  ]

  environment_variables = [
    {
      name  = "APPLICATION_NAME"
      value = "chain-scanner"
    },
    {
      name  = "ENVIRONMENT_NAME"
      value = startswith(local.env.environment, "prod") ? "prod" : "dev"
    },
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = each.value.common_config.chain-scanner.spring_profile
    },
    {
      name  = "THOR_URL"
      value = each.value.common_config.thor_url
    },
    {
      name  = "APP_LOG_LEVEL"
      value = "INFO"
    },
    {
      name  = "APP_LOGGER"
      value = "CloudWatch"
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_BLOCKS"
      value = each.value.common_config.chain-scanner.start_block.blocks
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_CLAUSES"
      value = each.value.common_config.chain-scanner.start_block.clauses
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_CONTRACTS"
      value = each.value.common_config.chain-scanner.start_block.contracts
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_NFTS"
      value = each.value.common_config.chain-scanner.start_block.nfts
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_TRANSACTIONS"
      value = each.value.common_config.chain-scanner.start_block.transactions
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_TRANSFERS"
      value = each.value.common_config.chain-scanner.start_block.transfers
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_BLOCKS"
      value = each.value.common_config.chain-scanner.sync_logger_interval.blocks
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_CLAUSES"
      value = each.value.common_config.chain-scanner.sync_logger_interval.clauses
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_CONTRACTS"
      value = each.value.common_config.chain-scanner.sync_logger_interval.contracts
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_FUNGIBLE_TOKENS"
      value = each.value.common_config.chain-scanner.sync_logger_interval.fungible_tokens
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_NFTS"
      value = each.value.common_config.chain-scanner.sync_logger_interval.nfts
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_TRANSACTIONS"
      value = each.value.common_config.chain-scanner.sync_logger_interval.transactions
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_TRANSFERS"
      value = each.value.common_config.chain-scanner.sync_logger_interval.transfers
    },
    {
      name  = "TYPEORM_CONNECTION"
      value = "mysql"
    },
    {
      name  = "TYPEORM_HOST"
      value = module.rds[each.value.network].db_address
    },
    {
      name  = "TYPEORM_PORT"
      value = module.rds[each.value.network].db_port
    },
    {
      name  = "TYPEORM_USERNAME"
      value = module.rds[each.value.network].db_username
    },
    {
      name  = "TYPEORM_PASSWORD"
      value = module.rds[each.value.network].rds_master_password_ssm_value
    },
    {
      name  = "TYPEORM_DATABASE"
      value = each.value.common_config.mysql.db_name
    },
    {
      name  = "TYPEORM_ENTITIES"
      value = "dist/explorer-db/entity/*.js"
    },
    {
      name  = "THOR_REST"
      value = each.value.common_config.thor_rest_url
    },
    {
      name  = "TYPEORM_MIGRATIONS"
      value = "dist/migrations/*.js"
    }
  ]
}

################################################################################
# Module For ECS Non-Load Balanced Service explore
################################################################################
module "ecs-lb-service-explore" {
  depends_on                 = [module.ecs-cluster, resource.aws_security_group.ecs_service_sg, resource.aws_security_group.alb-sg]
  for_each                   = local.env.networks
  source                     = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs-loadbalanced-webservice?ref=v.1.0.34"
  vpc_id                     = local.env.vpc_id
  region                     = local.env.region
  cluster_name               = module.ecs-cluster.name
  autoscale_cluster_name     = module.ecs-cluster.name
  lb_subnets                 = local.env.public_subnets
  app_subnets                = local.env.private_subnets
  env                        = local.env.environment
  is_create_repo             = false
  ecr_repo_uri               = each.value.common_config.explore.ecr_common_repo
  secrets_enable             = false
  assign_public_ip           = false
  app_name                   = "${each.key}-explore"
  ecr_image_tag              = local.env.image_tag
  project                    = var.project
  cpu                        = each.value.common_config.explore.cpu
  memory                     = each.value.common_config.explore.memory
  cidr                       = local.env.cidr
  container_port             = 8080
  certificate_arn            = local.env.certificate_arn
  ecs_sg                     = [aws_security_group.ecs_service_sg.id]
  rule_0_path_pattern        = ["/api/v*", "/api-docs", "/swagger-ui/*"]
  alb_sg                     = [aws_security_group.alb-sg.id]
  idle_timeout               = 4
  enable_deletion_protection = startswith(local.env.environment, "prod") ? true : false
  namespace_id               = aws_service_discovery_private_dns_namespace.ns.id
  https_tg_healthcheck_path  = "/favicon.png"
  https_tg_healthcheck_timeout = 30
  https_tg_healthcheck_interval = 45
  log_metric_filters = [
    {
      name    = "AppUnhealthy",
      pattern = "Application is UNHEALTHY"
    }
  ]

  environment_variables = [
    {
      name  = "APPLICATION_NAME"
      value = "explore"
    },
    {
      name  = "NODE_ENV"
      value = startswith(local.env.environment, "prod") ? "production" : "dev"
    },
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = each.value.common_config.explore.spring_profile
    },
    { name  = "THOR_URL"
      value = each.value.common_config.thor_url
    },
    {
      name  = "APP_LOG_LEVEL"
      value = "INFO"
    },
    {
      name  = "APP_LOGGER"
      value = "CloudWatch"
    },
    {
      name  = "API_URL"
      value = "http://${module.ecs-lb-service-mass[each.key].alb_dns_name}:80"
    },
    {
      name  = "NETWORK"
      value = "${each.key}net"
    },
    {
      name  = "CAPTCHA_SECRET"
      value = data.aws_ssm_parameter.captcha_secret.value
    },
  ]
}
