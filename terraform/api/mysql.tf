module "rds" {
  source                  = "git::git@github.com:/vechain/terraform_infrastructure_modules.git//rds?ref=v.1.0.2"
  app_name                = local.env.environment-mysql
  env                     = local.env.environment
  project                 = var.project
  allocated_storage       = local.env.mysql.allocated_storage
  engine                  = local.env.mysql.engine
  engine_version          = local.env.mysql.engine_version
  instance_class          = local.env.mysql.instance_class
  deletion_protection     = local.env.mysql.deletion_protection
  multi_az                = local.env.mysql.multi_az
  port                    = local.env.mysql.db_port
  storage_encrypted       = local.env.mysql.storage_encrypted
  vpc_name                = local.env.vpc_name
  subnet_ids              = local.env.database_subnets
  option_settings         = local.env.mysql.option_settings
  db_parameter            = [{}]
  skip_final_snapshot     = local.env.mysql.skip_final_snapshot
  publicly_accessible     = local.env.mysql.publicly_accessible
  backup_retention_period = local.env.mysql.backup_retention_period
  db_option_group = [
    {
      option_settings = [{}]
    }
  ]
  security_group_ingress_ports = {
    mysql = {
      from_ports  = [local.env.mysql.db_port]
      to_ports    = [local.env.mysql.db_port]
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
