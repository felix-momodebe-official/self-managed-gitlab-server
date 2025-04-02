provider "aws" {
  region = "us-east-1"
}

# Create a security group
resource "aws_security_group" "gitlab_sg" {
  name        = "gitlab-sg"
  description = "Security group for GitLab server"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

# Create an EC2 instance
resource "aws_instance" "gitlab_server" {
  ami           = "ami-0f9de6e2d2f067fca"
  instance_type = "t2.large"
  security_groups = [aws_security_group.gitlab_sg.name]
  key_name      = "my_default_keypair"

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "GitLab-Server"
  }

  # Automatically update inventory.ini with the public IP
  provisioner "local-exec" {
    command = <<EOT
      echo "[gitlab]" > inventory.ini
      echo "${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_default_keypair.pem" >> inventory.ini
    EOT
  }
}

# Output the public IP
output "gitlab_public_ip" {
  value = aws_instance.gitlab_server.public_ip
}
