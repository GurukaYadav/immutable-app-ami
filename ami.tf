resource "aws_ami_from_instance" "ami" {
  name               = "${var.COMPONENT}-${var.APP_VERSION}"
  source_instance_id = aws_instance.instance.id
}