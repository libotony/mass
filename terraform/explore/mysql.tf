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

# EC2 instance to initialize the secondary 'mass' database
resource "aws_instance" "db_initializer" {
  for_each                    = local.env.networks
  ami                         = "ami-04fe22dfadec6f0b6"
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  associate_public_ip_address = true
  instance_type               = "t2.micro"
  subnet_id                   = local.env.private_subnets[0]
  user_data                   = <<-EOF
    #!/bin/bash
    yum update -y
    sudo su -

    # Installing MySQL client...
    wget https://dev.mysql.com/get/mysql80-community-release-el9-1.noarch.rpm 
    dnf install mysql80-community-release-el9-1.noarch.rpm -y
    rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
    dnf install mysql-community-client -y

    # Initialize the 'mass' database
    mysql -h ${module.rds[each.key].db_address} -u ${module.rds[each.key].db_username} -p'${module.rds[each.key].rds_master_password_ssm_value}' <<EOSQL
      CREATE DATABASE IF NOT EXISTS mass;
    EOSQL

    # Shutdown the instance after initialization
    shutdown -h now
    EOF

  vpc_security_group_ids = [module.rds[each.key].rds_sg.id]

  provisioner "local-exec" {
    command = "echo 'EC2 instance created'"
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "ssm_role_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create an instance profile
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}
