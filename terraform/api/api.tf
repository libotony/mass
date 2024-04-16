variable "project" {
  default = "explorer"
}

variable "app_name" {
  default = ""
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  name = "${local.env.environment}.${var.project}"
  vpc  = data.terraform_remote_state.vpc.outputs.vpc_id
}

######################
# ALB Security Group
######################

resource "aws_security_group" "alb-sg" {
  count       = startswith(local.env.environment, "prod-") ? 1 : 0
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

  ingress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    self      = true
  }

  tags = {
    Environment = local.env.environment
    Name        = "${local.env.environment}-${var.project}-sg-alb"
  }
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

######################
# ECS Service Security Group
######################

resource "aws_security_group" "ecs_service_sg" {
  count       = startswith(local.env.environment, "prod-") ? 1 : 0
  description = "security-group-service"

  name = "${local.env.environment}-${var.project}-${var.app_name}-sg-service"
  egress {
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
    Name        = "${local.env.environment}-${var.project}-${var.app_name}-sg-service"
  }

  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

################################################################################
# Module For ECS Cluster creation
################################################################################

module "ecs-cluster" {
  # temporary filter to avoid deployment of new ECS cluster from original prod workspace
  count   = startswith(local.env.environment, "prod-") ? 1 : 0
  source  = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs_cluster?ref=v.1.0.2"
  env     = local.env.environment
  project = var.project
  vpc_id  = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr    = data.terraform_remote_state.vpc.outputs.vpc_ipv4
}

################################################################################
# Module For ECS Load Balanced Service mass
################################################################################

module "ecs-lb-service-mass" {
  depends_on                = [module.ecs-cluster, resource.aws_security_group.ecs_service_sg, resource.aws_security_group.alb-sg]
  source                    = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs-loadbalanced-webservice?ref=v.1.0.2"
  region                    = local.env.region
  vpc_id                    = data.terraform_remote_state.vpc.outputs.vpc_id
  cluster_name              = module.ecs-cluster[0].name
  autoscale_cluster_name    = module.ecs-cluster[0].name
  lb_subnets                = data.terraform_remote_state.vpc.outputs.public_subnets
  app_subnets               = data.terraform_remote_state.vpc.outputs.private_subnets
  env                       = local.env.environment
  is_create_repo            = false
  secrets_enable            = false
  assign_public_ip          = false
  image_repo_url            = each.value.mass.ecr_common_repo
  app_name                  = "${each.key}-mass"
  image_name                = local.env.image_tag
  project                   = var.project
  cpu                       = each.value.mass.cpu
  memory                    = each.value.mass.memory
  cidr                      = local.env.cidr
  container_port            = 8080
  certificate_arn           = local.env.certificate_arn
  ecs_sg                    = [aws_security_group.alb-sg[0].id]
  rule_0_path_pattern       = ["/api/v*", "/api-docs", "/swagger-ui/*"]
  alb_sg                    = [aws_security_group.alb-sg[0].id]
  namespace_id              = aws_service_discovery_private_dns_namespace.ns.id
  https_tg_healthcheck_path = "/actuator/health"
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
      value = each.value.mass.spring_profile
    },
    {
      name  = "APP_LOG_LEVEL"
      value = "INFO"
    },
    { name  = "THOR_URL"
      value = each.value.thor_url
    },
    {
      name  = "APP_LOGGER"
      value = "CloudWatch"
    }
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
  max_capacity                        = each.value.mass.max_capacity
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
  source           = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//ecs-backend-service?ref=v.1.0.2"
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  region           = local.env.region
  cluster          = module.ecs-cluster[0].name
  subnets          = concat(data.terraform_remote_state.vpc.outputs.public_subnets, data.terraform_remote_state.vpc.outputs.private_subnets)
  env              = local.env.environment
  is_create_repo   = false
  secrets_enable   = false
  image_repo_url   = each.value.chain-scanner.ecr_common_repo
  image_name       = local.env.image_tag
  app_name         = "${each.key}-chain-scanner"
  project          = var.project
  cpu              = each.value.chain-scanner.cpu
  memory           = each.value.chain-scanner.memory
  cidr             = local.env.cidr
  security_groups  = [aws_security_group.ecs_service_sg[0].id]
  desired_capacity = "1"
  containerPort    = 8080
  hostPort         = 8080
  namespace_id     = aws_service_discovery_private_dns_namespace.ns.id
  log_metric_filters = [
    {
      name    = "AppUnhealthy",
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
      value = local.env.environment
    },
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = each.value.chain-scanner.spring_profile
    },
    { name  = "THOR_URL"
      value = each.value.thor_url
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
      value = each.value.chain-scanner.start_block.blocks
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_CLAUSES"
      value = each.value.chain-scanner.start_block.clauses
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_CONTRACTS"
      value = each.value.chain-scanner.start_block.contracts
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_NFTS"
      value = each.value.chain-scanner.start_block.nfts
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_TRANSACTIONS"
      value = each.value.chain-scanner.start_block.transactions
    },
    {
      name  = "CHAIN-SCANNER_START_BLOCK_TRANSFERS"
      value = each.value.chain-scanner.start_block.transfers
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_BLOCKS"
      value = each.value.chain-scanner.sync_logger_interval.blocks
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_CLAUSES"
      value = each.value.chain-scanner.sync_logger_interval.clauses
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_CONTRACTS"
      value = each.value.chain-scanner.sync_logger_interval.contracts
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_FUNGIBLE_TOKENS"
      value = each.value.chain-scanner.sync_logger_interval.fungible_tokens
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_NFTS"
      value = each.value.chain-scanner.sync_logger_interval.nfts
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_TRANSACTIONS"
      value = each.value.chain-scanner.sync_logger_interval.transactions
    },
    {
      name  = "CHAIN-SCANNER_SYNC_LOGGER_INTERVAL_TRANSFERS"
      value = each.value.chain-scanner.sync_logger_interval.transfers
    }
  ]
}

################################################################################
# Module For ECS Non-Load Balanced Service explorer
################################################################################
module "ecs-backend-service-explorer" {
  depends_on       = [module.ecs-cluster]
  source           = "git::github.com/vechain/terraform_infrastructure_modules.git//ecs-backend-service?ref=v.1.0.2"
  vpc_id           = data.terraform_remote_state.vpc.outputs.vpc_id
  region           = local.env.region
  cluster          = module.ecs-cluster[0].name
  subnets          = concat(data.terraform_remote_state.vpc.outputs.public_subnets, data.terraform_remote_state.vpc.outputs.private_subnets)
  env              = local.env.environment
  is_create_repo   = false
  secrets_enable   = false
  image_repo_url   = each.value.explorer.ecr_common_repo
  image_name       = local.env.image_tag
  app_name         = "${each.key}-explorer"
  project          = var.project
  cpu              = each.value.explorer.cpu
  memory           = each.value.explorer.memory
  cidr             = local.env.cidr
  security_groups  = [aws_security_group.ecs_service_sg[0].id]
  desired_capacity = "1"
  containerPort    = 8080
  hostPort         = 8080
  namespace_id     = aws_service_discovery_private_dns_namespace.ns.id
  log_metric_filters = [
    {
      name    = "AppUnhealthy",
      pattern = "Application is UNHEALTHY"
    }
  ]

  environment_variables = [
    {
      name  = "APPLICATION_NAME"
      value = "explorer"
    },
    {
      name  = "ENVIRONMENT_NAME"
      value = local.env.environment
    },
    {
      name  = "SPRING_PROFILES_ACTIVE"
      value = each.value.explorer.spring_profile
    },
    { name  = "THOR_URL"
      value = each.value.thor_url
    },
    {
      name  = "APP_LOG_LEVEL"
      value = "INFO"
    },
    {
      name  = "APP_LOGGER"
      value = "CloudWatch"
    }
  ]
}


data "aws_security_groups" "ecs_sg_list" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.vpc.outputs.vpc_id]
  }
  filter {
    name   = "group-name"
    values = ["${local.env.environment}-${var.project}-*-sg-service", "${local.env.environment}-${var.project}-*-sg-alb"]
  }
  depends_on = [module.ecs-service, module.ecs-lb-service]
}

module "vpc-endpoints" {
  source = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//vpcendpoint?ref=v.1.0.2"
  vpcendpoints_interfaces = (startswith(local.env.environment, "prod-") ? [] : [
    {
      id                  = "ec2"
      vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
      security_group_ids  = data.aws_security_groups.ecs_sg_list.ids
      subnet_ids          = data.terraform_remote_state.vpc.outputs.private_subnets
      private_dns_enabled = true
      allowed_cidr_blocks = [local.env.cidr]
      inbound_ports       = [80, 443]
      tags = {
        Name        = "com.amazonaws.eu-west-1.ec2"
        Project     = var.project
        Environment = local.env.environment
      }
    },
    {
      id                  = "ec2messages"
      vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
      security_group_ids  = data.aws_security_groups.ecs_sg_list.ids
      subnet_ids          = data.terraform_remote_state.vpc.outputs.private_subnets
      private_dns_enabled = true
      allowed_cidr_blocks = [local.env.cidr]
      inbound_ports       = [80, 443]
      tags = {
        Name        = "com.amazonaws.eu-west-1.ec2"
        Project     = var.project
        Environment = local.env.environment
      }
    },
    {
      id                  = "ssm"
      vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
      security_group_ids  = data.aws_security_groups.ecs_sg_list.ids
      subnet_ids          = data.terraform_remote_state.vpc.outputs.private_subnets
      private_dns_enabled = true
      allowed_cidr_blocks = [local.env.cidr]
      inbound_ports       = [80, 443]
      tags = {
        Name        = "com.amazonaws.eu-west-1.ec2"
        Project     = var.project
        Environment = local.env.environment
      }
    },
    {
      id                  = "ssmmessages"
      vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
      security_group_ids  = data.aws_security_groups.ecs_sg_list.ids
      subnet_ids          = data.terraform_remote_state.vpc.outputs.private_subnets
      private_dns_enabled = true
      allowed_cidr_blocks = [local.env.cidr]
      inbound_ports       = [80, 443]
      tags = {
        Name        = "com.amazonaws.eu-west-1.ec2"
        Project     = var.project
        Environment = local.env.environment
      }
    }
  ])
}


