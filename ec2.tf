resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.image_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = local.TAG_NAME
  }
}

resource "null_resource" "null" {
  depends_on = [null_resource.copy_local_artifacts]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host     = aws_instance.instance.private_ip
    }

    inline = [
      "ansible-pull -U https://github.com/GurukaYadav/roboshop-ansible.git roboshop.yml -e HOST=localhost -e ROLE=${var.COMPONENT} -e ENV=ENV -e DOCDB_ENDPOINT=DOCDB_ENDPOINT -e REDIS_ENDPOINT=REDIS_ENDPOINT -e RDS_ENDPOINT=RDS_ENDPOINT"
    ]
  }
}

resource "null_resource" "copy_local_artifacts" {
  provisioner "file" {
    connection {
      type     = "ssh"
      user     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host     = aws_instance.instance.private_ip
    }
    source      = "${var.COMPONENT}-${var.APP_VERSION}.zip"
    destination = "/tmp/${var.COMPONENT}.zip"
  }
}

