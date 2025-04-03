# Self-Managed GitLab (with Domain Name & SSL Certificate) Installation on AWS with Terraform and Ansible

This guide outlines the process to deploy a self-managed GitLab instance with customed domain name and SSL certificate on an AWS EC2 instance running Ubuntu 22.04 LTS, using Terraform for infrastructure provisioning and Ansible for configuration. The instance will be accessible via your custom domain (`succpinndemo.com`) with SSL enabled via Let's Encrypt.

## Prerequisites

- **AWS Account**: Ensure you have an AWS account with programmatic access (Access Key and Secret Key).
- **Domain Name**: A registered domain (`succpinndemo.com`) with DNS management access.
- **Local Tools**:
  - Terraform (`>= 1.0.0`)
  - Ansible (`>= 2.9`)
  - AWS CLI configured with credentials
  - SSH key pair (e.g., `my_default_keypair.pem`) uploaded to AWS
- **DNS Configuration**: An A record pointing `succpinndemo.com` to the EC2 instance's public IP (updated post-deployment).

## Architecture Overview

1. **Terraform**: Provisions an EC2 instance and security group in AWS.
2. **Ansible**: Configures the EC2 instance with GitLab EE, dependencies, and SSL.
3. **Domain**: Uses `succpinndemo.com` with Let's Encrypt for HTTPS.

## Deployment Steps

### 1. Infrastructure Provision/Setup with Terraform

The Terraform configuration creates:
- An EC2 instance (Ubuntu 22.04 LTS, `t2.large`, 50GB EBS).
- A security group allowing SSH (22), HTTP (80), and HTTPS (443).
- An inventory file (`inventory.ini`) for Ansible.

#### Terraform Files

- **`main.tf`**:
```hcl
provider "aws" {
  region = "us-east-1"
}

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

resource "aws_instance" "gitlab_server" {
  ami           = "ami-0e86e20dae9224db8" # Ubuntu 22.04 LTS in us-east-1
  instance_type = "t2.large"
  security_groups = [aws_security_group.gitlab_sg.name]
  key_name      = "my_default_keypair"

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "GitLab-Server"
  }

  provisioner "local-exec" {
    command = <<EOT
      echo "[gitlab]" > inventory.ini
      echo "${self.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/my_default_keypair.pem" >> inventory.ini
    EOT
  }
}

output "gitlab_public_ip" {
  value = aws_instance.gitlab_server.public_ip
}
```

### Deploy the Infrastructure:
#### Steps:

1. Save the above as main.tf.
2. Run:
```
bash

terraform init
terraform apply -auto-approve
```
3. Note the output `gitlab_public_ip`.

2. ### Install & Configure GitLab with Ansible:
  - After the EC2 instance is created, use Ansible to install and configure GitLab.
  - The Ansible playbook installs **GitLab EE** and configures it for `succpinndemo.com`.

Ansible Playbook:

   - `install_gitlab.yml`:

```
---
- name: Install GitLab on Ubuntu 22.04 with SSL
  hosts: gitlab
  become: yes
  vars:
    gitlab_domain: "succpinndemo.com"

  tasks:
    - name: Update package lists
      apt:
        update_cache: yes

    - name: Install dependencies
      apt:
        name:
          - curl
          - openssh-server
          - ca-certificates
          - tzdata
          - perl
        state: present

    - name: Install Postfix
      debconf:
        name: postfix
        question: "postfix/main_mailer_type"
        value: "Internet Site"
        vtype: "string"

    - name: Install Postfix package
      apt:
        name: postfix
        state: present

    - name: Ensure UFW is installed
      apt:
        name: ufw
        state: present

    - name: Allow OpenSSH, HTTP, and HTTPS in UFW
      ufw:
        rule: allow
        port: "{{ item }}"
      loop:
        - "22"
        - "80"
        - "443"

    - name: Enable UFW
      command: ufw --force enable
      ignore_errors: yes

    - name: Add GitLab repository
      shell: curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | bash
      args:
        warn: no

    - name: Install GitLab
      apt:
        name: gitlab-ee
        state: present
      environment:
        EXTERNAL_URL: "https://{{ gitlab_domain }}"

    - name: Display GitLab root password
      command: cat /etc/gitlab/initial_root_password
      register: root_password

    - name: Print root password
      debug:
        msg: "{{ root_password.stdout }}"
```

## Steps:

1. Save the above as `install_gitlab.yml`.
2. Ensure `inventory.ini` exists (generated/updated by Terraform).
3. Run:

```
bash

ansible-playbook -i inventory.ini gitlab.yml
```

4. Note the root password displayed in the output.

3. ### DNS Configuration

1. Log in to your DNS provider.
2. Create an A record:
   - Host: `@` or `succpinndemo.com`
   - Value: `<gitlab_public_ip>` (from Terraform output)
   - TTL: 300 (or default)
    
4. ### Access GitLab

- Open `https://succpinndemo.com` in your browser.
- Log in with:
  - Username: `root`
  - Password: (from Ansible output or `/etc/gitlab/initial_root_password` on the server, valid for 24 hours).

## Conclusion

This guide provides a streamlined approach to deploying a self-managed GitLab instance using Terraform and Ansible. With further automation, the deployment can be entirely hands-free.

For any questions or improvements, feel free to contribute!
