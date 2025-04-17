#!/bin/bash

set -e  # Exit on error

# === CONFIGURATION ===
CLOUDFLARE_EMAIL="your-cloudflare-email@example.com"  # Replace with your Cloudflare email
CLOUDFLARE_API_TOKEN="your-cloudflare-api-token"      # Replace with your Cloudflare API token
CLOUDFLARE_ZONE="example.com"                         # Replace with your Cloudflare zone
CLOUDFLARE_RECORD="vpn.example.com"                  # Replace with your Cloudflare record

PAM_FILE="/etc/pam.d/common-password"
LOGIN_DEFS="/etc/login.defs"

# === SYSTEM UPDATE ===
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# === INSTALL REQUIRED PACKAGES ===
echo "Installing required packages..."
sudo apt install -y python3 python3-pip python3-venv git curl libpam-pwquality

# === CONFIGURE PAM ===
echo "Configuring password complexity rules..."
if ! grep -q "retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=4" $PAM_FILE; then
  sudo sed -i '/pam_pwquality.so/ s/$/ retry=3 minlen=8 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 difok=4/' $PAM_FILE
  echo "PAM configuration updated successfully."
else
  echo "PAM configuration already contains the required rules. Skipping update."
fi

# === SETUP ANSIBLE ===
echo "Setting up Ansible..."
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate
pip install ansible requests
~/ansible-venv/bin/ansible-galaxy collection install community.general

# === CLONE REPOSITORY ===
if [ ! -d "balexto" ]; then
  echo "Cloning repository..."
  git clone https://github.com/Th1nk7/balexto.git
fi
cd balexto/ansible-playbook

# === RUN ANSIBLE PLAYBOOK ===
echo "Running Ansible playbook..."
export BECOME_PASS="your-sudo-password"  # Replace with the actual sudo password
~/ansible-venv/bin/ansible-playbook -i inventory playbook.yml --connection=local \
  -e "cloudflare_email=$CLOUDFLARE_EMAIL" \
  -e "cloudflare_api_token=$CLOUDFLARE_API_TOKEN" \
  -e "cloudflare_zone=$CLOUDFLARE_ZONE" \
  -e "cloudflare_record=$CLOUDFLARE_RECORD" \
  -e "ansible_user=$USER"

# Clear sensitive environment variables
unset BECOME_PASS

# === SETUP CRON JOB FOR UPDATES ===
echo "Setting up cron job for periodic updates..."
CRON_JOB="@hourly ~/ansible-venv/bin/ansible-playbook -i ~/balexto/ansible-playbook/inventory ~/balexto/ansible-playbook/playbook.yml --tags update_dns --connection=local"
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# Deactivate the Python virtual environment if active
if [ -n "$VIRTUAL_ENV" ]; then
  deactivate
fi

# Securely delete the script
shred -u -- "$0"