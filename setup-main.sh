#!/bin/bash

set -e  # Exit on error

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip git curl unattended-upgrades

# Enable automatic updates
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo groupadd -f docker  # Ensure the docker group exists
sudo usermod -aG docker $USER

# Install Ansible in a user environment
pip3 install --user ansible

# Update PATH for Ansible
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  export PATH="$HOME/.local/bin:$PATH"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Set Cloudflare API token (replace with your actual token)
export CF_API_TOKEN=CLOUDFLARE_API_TOKEN_HERE

# Clone the repository
git clone https://github.com/Th1nk7/balexto.git
cd balexto/ansible-playbook

# Install Ansible Galaxy collections
ansible-galaxy collection install community.general

# Run the Ansible playbook
ansible-playbook -i inventory playbook.yml --connection=local