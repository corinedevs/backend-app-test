locals {
  resource_prefix = "${var.env}-corine"
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
      port= 5432
      cidr_blocks= module.vpc.private_subnets_cidr_blocks
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
      port = 3000
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port = 22
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  depends_on = [
    module.vpc
  ]
}

module "security_group__frontend" {
  source = "./modules/security-group"

  name = "${local.resource_prefix}-frontend"
  vpc_id = module.vpc.vpc_id
  ingress_rules = [
    {
      port = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      port = 22
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  depends_on = [
    module.vpc
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
  family               = "postgres17.2"
  major_engine_version = "17"
  instance_class       = "db.m5.large"
  storage_type = "gp3"

  allocated_storage = 30

  db_name  = "corine"
  username = "corine"
  password = "corine123"
  port     = 5432

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
# module "ec2_backend" {
#   source             = "./modules/ec2"
#   name               = "${local.resource_prefix}-backend-application"
#   ami_id             = data.aws_ami.amazon_linux.id
#   instance_type      = "t2.micro"
#   subnet_id          = module.vpc.private_subnets[0]
#   security_group_ids = [module.security_group__backend.id]
#   key_name           = "my-key"
#   user_data          = file("${path.module}/scripts/userdata-backend.sh")

#   depends_on = [
#     module.vpc,
#     module.security_group__backend
#   ]
# }