locals {
  resource_prefix = "${var.env}-corine"
  db_username = jsondecode(data.aws_secretsmanager_secret_version.rds_default_secrets_version.secret_string)["username"]
  db_password = jsondecode(data.aws_secretsmanager_secret_version.rds_default_secrets_version.secret_string)["password"]
  db_port     = 5432
  
  # backend application template
  user_data = templatefile("${path.module}/scripts/userdata-backend.tpl", {
    port        = var.backend_application_port
    pg_host     = module.rds_postgres.db_instance_endpoint
    pg_user     = local.db_username
    pg_password = local.db_password
    pg_database = var.db_name
    pg_port     = local.db_port
  })
}


################################################################################
# VPC
################################################################################
module "vpc" {
  source = "./modules/vpc"

  name = "${local.resource_prefix}-vpc"
  cidr = "130.30.0.0/16"

  azs = ["${var.region}a", "${var.region}b"]
  database_subnets = ["130.30.1.0/24", "130.30.2.0/24"]
  private_subnets = ["130.30.3.0/24", "130.30.4.0/24"]
  public_subnets  = ["130.30.5.0/24", "130.30.6.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = false
}


################################################################################
# Security Group(s)
################################################################################
module "security_group__rds" {
  source = "./modules/security-group"

  name = "${local.resource_prefix}-db"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port= local.db_port
      cidr_blocks= module.vpc.private_subnets_cidr_blocks
    }
  ]

  depends_on = [
    module.vpc
  ]
}

module "security_group__alb" {
  source = "./modules/security-group"

  name = "${local.resource_prefix}-alb"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port = 80
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port = var.backend_application_port
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  depends_on = [
    module.vpc
  ]
}

module "security_group__backend" {
  source = "./modules/security-group"

  name = "${local.resource_prefix}-backend"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port = var.backend_application_port
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port = var.backend_application_port
      source_security_group_id = module.security_group__alb.id
    },
    {
      port = 22
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  depends_on = [
    module.vpc,
    module.security_group__alb
  ]
}

module "security_group__frontend" {
  source = "./modules/security-group"

  name = "${local.resource_prefix}-frontend"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port = 80
      cidr_blocks = "0.0.0.0/0"
    },
    {
      port = 80
      source_security_group_id = module.security_group__alb.id
    },
    {
      port = 22
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  depends_on = [
    module.vpc,
    module.security_group__alb
  ]
}


################################################################################
# RDS - Postgres
################################################################################
module "rds_postgres" {
  source = "./modules/rds-postgresql"

  identifier = "${local.resource_prefix}-wefleet-database"
  instance_use_identifier_prefix = false

  multi_az = true
  create_db_option_group    = true
  create_db_parameter_group = true
  create_random_password = false
  apply_immediately   = true
  skip_final_snapshot = true
  deletion_protection = true
  create_monitoring_role = false
  storage_encrypted = true

  engine               = "postgres"
  engine_version       = "17.2"
  family               = "postgres17"
  major_engine_version = "17"
  instance_class       = "db.m5.large"
  storage_type = "gp3"

  allocated_storage = 30

  db_name  = var.db_name
  username = local.db_username  # corine
  password = local.db_password  # corine123
  port     = local.db_port

  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.security_group__rds.id]

  maintenance_window      = "Sun:15:00-Sun:15:30"
  backup_window           = "14:00-14:30"
  backup_retention_period = 7

  depends_on = [
    module.vpc,
    module.security_group__rds
  ]
}


################################################################################
# EC2(s)
################################################################################
module "ec2_backend" {
  source             = "./modules/ec2"
  name               = "${local.resource_prefix}-backend-application"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.private_subnets[0]
  security_group_ids = [module.security_group__backend.id]
  key_name           = var.keypair_name
  user_data          = local.user_data
  associate_public_ip_address = true

  depends_on = [
    module.vpc,
    module.security_group__backend
  ]
}

module "ec2_frontend" {
  source             = "./modules/ec2"
  name               = "${local.resource_prefix}-web-application"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t2.micro"
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.security_group__frontend.id]
  key_name           = var.keypair_name
  user_data          = file("${path.module}/scripts/userdata-frontend.sh")
  associate_public_ip_address = true

  depends_on = [
    module.vpc,
    module.security_group__frontend
  ]
}