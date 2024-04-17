module "rds" {
  for_each                    = local.env.networks
  source                      = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//rds?ref=v.1.0.2"
  app_name                    = "${local.env.application}${each.key}"
  env                         = local.env.environment
  project                     = local.env.project
  allocated_storage           = each.value.mysql.allocated_storage
  engine                      = each.value.mysql.engine
  engine_version              = each.value.mysql.engine_version
  instance_class              = each.value.mysql.instance_class
  deletion_protection         = each.value.mysql.deletion_protection
  multi_az                    = each.value.mysql.multi_az
  port                        = each.value.mysql.db_port
  storage_encrypted           = each.value.mysql.storage_encrypted
  vpc_name                    = local.env.vpc_name
  subnet_ids                  = local.env.database_subnets
  option_settings             = each.value.mysql.option_settings
  db_parameter                = [{}]
  skip_final_snapshot         = each.value.mysql.skip_final_snapshot
  publicly_accessible         = each.value.mysql.publicly_accessible
  backup_retention_period     = each.value.mysql.backup_retention_period
  username                    = each.value.mysql.username
  manage_master_user_password = each.value.mysql.manage_master_user_password
  db_option_group = [
    {
      option_settings = [{}]
    }
  ]
  security_group_ingress_ports = {
    mysql = {
      from_ports  = [each.value.mysql.db_port]
      to_ports    = [each.value.mysql.db_port]
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
