#!/bin/bash

set -e  # Exit on error

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip python3-venv git curl unattended-upgrades

# Enable automatic updates by creating configuration files
sudo bash -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF'

sudo bash -c 'cat > /etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "true";
EOF'

# Clean up old Docker key files
sudo rm -f /etc/apt/keyrings/docker.asc

# Install Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo groupadd -f docker  # Ensure the docker group exists
sudo usermod -aG docker $USER

# Create a Python virtual environment for Ansible
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate

# Install Ansible in the virtual environment
pip install ansible requests

# Set up the virtual environment activation in .bashrc
if ! grep -q "source ~/ansible-venv/bin/activate" ~/.bashrc; then
  echo 'source ~/ansible-venv/bin/activate' >> ~/.bashrc
fi

# Set Cloudflare API token (replace with your actual token)
export CF_API_TOKEN=CLOUDFLARE_API_TOKEN_HERE

# Clone the repository
git clone https://github.com/Th1nk7/balexto.git
cd balexto/ansible-playbook

# Install Ansible Galaxy collections
~/ansible-venv/bin/ansible-galaxy collection install community.general

# Run the Ansible playbook
~/ansible-venv/bin/ansible-playbook -i inventory playbook.yml --connection=local

# Set up a cron job for automatic DNS updates
CRON_JOB="@hourly ~/ansible-venv/bin/ansible-playbook -i ~/balexto/ansible-playbook/inventory ~/balexto/ansible-playbook/playbook.yml --tags update_dns --connection=local"
(crontab -l 2>/dev/null | grep -v "ansible-playbook.*--tags update_dns"; echo "$CRON_JOB") | crontab -