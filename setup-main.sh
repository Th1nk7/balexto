#!/bin/bash

set -e  # Exit on error
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip git curl

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Ansible
pip3 install --user ansible

# Update PATH for Ansible
export PATH="$HOME/.local/bin:$PATH"

# Set Cloudflare API token (replace with your actual token)
export CF_API_TOKEN=CLOUDFLARE_API_TOKEN_HERE

# Clone the repository
git clone https://github.com/Th1nk7/balexto.git
cd balexto/ansible-playbook

# Install Ansible Galaxy collections
ansible-galaxy collection install community.general

# Run the Ansible playbook
ansible-playbook -i inventory playbook.yml --connection=local