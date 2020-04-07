variable "instance_id" { default = " " }

resource "aws_ami_from_instance" "docker-host-ami" {
  name               = "Docker-Host"
  source_instance_id = var.instance_id
}
