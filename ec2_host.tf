
variable "ami" { default = "ami-03338e1f67dae0168" }
variable "ami_type" { default = "t3.micro" }
variable "subnet" {}
variable "region" { default = "ca-central-1" }
variable "transit" { default = "none" }
variable "owner" { default = "vguerlesquin" }
variable "project" { default = "AMI Docker" }
variable "tower" {}
variable "aws_vpc_id" {}

provider "aws" {
  region = "${var.region}"
}



resource "random_uuid" "uuid" {}

resource "tls_private_key" "auto-gen-key-docker-host" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated-docker-host-${random_uuid.uuid.result}"
  public_key = "${tls_private_key.auto-gen-key-docker-host.public_key_openssh}"
}


resource "aws_security_group" "allow_docker-host" {
  name        = "docker-host-${random_uuid.uuid.result}"
  description = "Allow inbound/outbound traffic for docker-host"
  vpc_id      = "${var.aws_vpc_id}"

  ingress {
    # SSH
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # add your IP address here
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "docker-host"
  }
}

resource "aws_instance" "docker-host" {
  ami = "${var.ami}"
  # spot_type = "one-time"
  instance_type          = "${var.ami_type}"
  subnet_id              = "${var.subnet}"
  key_name               = "${aws_key_pair.generated_key.key_name}"
  vpc_security_group_ids = ["${aws_security_group.allow_docker-host.id}"]
  volume_tags = {
    Name = "Docker Host - ${random_uuid.uuid.result}"
  }
  tags = {
    Uuid    = "${random_uuid.uuid.result}"
    Name    = "Docker Host - ${random_uuid.uuid.result}"
    Transit = "${var.transit}"
  }
}

output "instance_ip" {
  value = "${join(",", list(
    aws_instance.docker-host.private_ip
    )
  )}"
}

output "private_key" {
  value     = tls_private_key.auto-gen-key-docker-host.private_key_pem
  sensitive = true
}

output "instance_id" {
  value = aws_instance.docker-host.id
}
