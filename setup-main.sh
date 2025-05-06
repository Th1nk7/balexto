#!/bin/bash

set -e  # Exit on error

# === CONFIGURATION ===
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

# === CREATE ANSIBLE VAULT ===
echo "Creating Ansible Vault for credentials..."
ansible-vault edit credentials.yml

# === RUN ANSIBLE PLAYBOOK ===
echo "Running Ansible playbook..."
~/ansible-venv/bin/ansible-playbook -i inventory playbook.yml --connection=local --ask-vault-pass

# === SETUP CRON JOB FOR UPDATES ===
echo "Setting up cron job for periodic updates..."
CRON_JOB="@hourly ~/ansible-venv/bin/ansible-playbook -i ~/balexto/ansible-playbook/inventory ~/balexto/ansible-playbook/playbook.yml --tags update_dns --connection=local --vault-password-file ~/balexto/ansible-playbook/.vault_pass"

# Check if the cron job already exists, and add it if it doesn't
(crontab -l 2>/dev/null | grep -F "$CRON_JOB") || (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -

# Verify the cron job was added
if crontab -l | grep -F "$CRON_JOB" > /dev/null; then
  echo "Cron job successfully added."
else
  echo "Failed to add cron job. Please check manually."
fi

# Deactivate the Python virtual environment if active
if [ -n "$VIRTUAL_ENV" ]; then
  deactivate
fi

# Securely delete the script
shred -u -- "$0"