resource "aws_instance" "instance" {
  ami           = data.aws_ami.ami.image_id
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    Name = local.TAG_PREFIX
  }
}

resource "null_resource" "resource" {
  depends_on = [null_resource.copy_local_artifacts]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_USER"]
      password = jsondecode(data.aws_secretsmanager_secret_version.secret.secret_string)["SSH_PASS"]
      host     = aws_instance.instance.private_ip
    }

    inline = [
      "ansible-pull -U https://github.com/GurukaYadav/roboshop-ansible.git roboshop.yml -e HOST=localhost -e ROLE=${var.COMPONENT} -e ENV=ENV -e DOCDB_ENDPOINT=DOCDB_ENDPOINT -e REDIS_ENDPOINT=REDIS_ENDPOINT -e RDS_ENDPOINT=RDS_ENDPOINT -e DOCDB_USER=DOCDB_USER -e DOCDB_PASS=DOCDB_PASS"
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

resource "aws_ami_from_instance" "ami" {
  depends_on         = [null_resource.resource]
  name               = "${var.COMPONENT}-${var.APP_VERSION}"
  source_instance_id = aws_instance.instance.id
}