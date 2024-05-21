module "rds" {
  for_each                    = local.env.networks
  source                      = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//rds?ref=v.1.0.9"
  app_name                    = "${local.env.application}${each.key}"
  db_name                     = each.value.common_config.mysql.db_name
  env                         = local.env.environment
  project                     = local.env.project
  allocated_storage           = each.value.common_config.mysql.allocated_storage
  engine                      = each.value.common_config.mysql.engine
  engine_version              = each.value.common_config.mysql.engine_version
  instance_class              = each.value.common_config.mysql.instance_class
  deletion_protection         = each.value.common_config.mysql.deletion_protection
  multi_az                    = each.value.common_config.mysql.multi_az
  port                        = each.value.common_config.mysql.db_port
  storage_encrypted           = each.value.common_config.mysql.storage_encrypted
  vpc_name                    = local.env.vpc_name
  subnet_ids                  = local.env.database_subnets
  option_settings             = each.value.common_config.mysql.option_settings
  db_parameter                = [{}]
  apply_immediately           = each.value.common_config.mysql.apply_immediately
  skip_final_snapshot         = each.value.common_config.mysql.skip_final_snapshot
  publicly_accessible         = each.value.common_config.mysql.publicly_accessible
  backup_retention_period     = each.value.common_config.mysql.backup_retention_period
  username                    = each.value.common_config.mysql.username
  manage_master_user_password = each.value.common_config.mysql.manage_master_user_password
  db_option_group = [
    {
      option_settings = [{}]
    }
  ]
  security_group_ingress_ports = {
    mysql = {
      from_ports  = [each.value.common_config.mysql.db_port]
      to_ports    = [each.value.common_config.mysql.db_port]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  security_group_egress_ports = {
    all_traffic = {
      from_ports  = [0]
      to_ports    = [0]
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
