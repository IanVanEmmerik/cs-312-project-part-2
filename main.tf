terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "minecraft2_server" {
  ami           = "ami-05a6dba9ac2da60cb"
  instance_type = "t4g.small"
  key_name      = aws_key_pair.minecraft2.key_name

  associate_public_ip_address = true

  vpc_security_group_ids = [
    aws_security_group.minecraft2.id
  ]

  provisioner "file" {
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.minecraft2.private_key_pem
    host        = self.public_ip
  }

  tags = {
    Name = "Minecraft 2"
  }
}

resource "aws_key_pair" "minecraft2" {
  key_name   = "minecraft2"
  public_key = tls_private_key.minecraft2.public_key_openssh
}

resource "tls_private_key" "minecraft2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_security_group" "minecraft2" {
  name        = "minecraft2-security-group"
  description = "Allow Minecraft server traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "local_file" "minecraft2_key" {
  content  = tls_private_key.minecraft2.private_key_pem
  filename = "minecraft2.pem"
}

output "minecraft2_server_public_ip" {
  value       = aws_instance.minecraft2_server.public_ip
  description = "Public IP address of the Minecraft server"
}