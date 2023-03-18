data "aws_ami" "ami" {
  most_recent      = true
  name_regex       = "base-with-ansible"
  owners           = ["self"]
}

data "aws_secretsmanager_secret" "secret" {
  name = "roboshop/all"
}

data "aws_secretsmanager_secret_version" "secret" {
  secret_id = data.aws_secretsmanager_secret.secret.id
}