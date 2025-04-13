################################################################################
# NOTE:

# 1. create a mannual secret in "Secret Manager" service
# 2. Secret Type    : OTHER
# 3. Keys Name      : "username" & "password"
# 4. Encryption Key : DefaultEncryptionKey
# 5. Secret Name    : "corine-app-database-secrets"
################################################################################
data "aws_secretsmanager_secret" "rds_default_secrets" {
  name = "corine-app-database-secrets"
}
data "aws_secretsmanager_secret_version" "rds_default_secrets_version" {
  secret_id = data.aws_secretsmanager_secret.rds_default_secrets.id
}




data "aws_caller_identity" "current" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
