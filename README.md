# GitLab Installation and Configuration with SSL

This project provides an automated Ansible playbook to install and configure GitLab on an Ubuntu 22.04 server with SSL support. It includes steps to set up dependencies, configure a firewall, install GitLab, and enable SSL using Let's Encrypt.

## Features

- Automated installation of GitLab on Ubuntu 22.04
- SSL configuration using Let's Encrypt
- Firewall configuration with UFW
- Postfix installation for email notifications
- Debugging and verification of SSL certificates
- Display of GitLab root password after installation

## Prerequisites

Before running the playbook, ensure the following:

1. An Ubuntu 22.04 server with a public IP address.
2. A domain name pointing to the server's IP address.
3. Ansible installed on your local machine.
4. SSH access to the server.

## Directory Structure
