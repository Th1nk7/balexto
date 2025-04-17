#!/bin/bash

set -e  # Exit on error

# Check if the script is run as a regular user with sudo permissions
if [[ $EUID -eq 0 ]]; then
  echo "This script should not be run as root. Please run it as a regular user with sudo permissions."
  exit 1
fi

if ! sudo -v >/dev/null 2>&1; then
  echo "This script requires sudo permissions. Please ensure your user has sudo access."
  exit 1
fi

# Define a marker file to track progress
MARKER_FILE="$HOME/.setup-main-progress"

# Function to update the marker file
update_marker() {
  echo "$1" > "$MARKER_FILE"
}

# Function to check the current progress
get_marker() {
  if [[ -f "$MARKER_FILE" ]]; then
    cat "$MARKER_FILE"
  else
    echo "start"
  fi
}

# Function to set up a temporary cron job to resume after reboot
setup_resume_cron() {
  (crontab -l 2>/dev/null; echo "@reboot $HOME/setup-main.sh --resume") | crontab -
}

# Function to remove the temporary cron job
remove_resume_cron() {
  crontab -l 2>/dev/null | grep -v "@reboot $HOME/setup-main.sh --resume" | crontab -
}

# Start from the appropriate point based on the marker file
case "$(get_marker)" in
  "start")
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

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo groupadd -f docker  # Ensure the docker group exists
    sudo usermod -aG docker $USER

    # Inform the user about Docker group changes
    echo "If this is your first time running this script, you may need to log out and log back in for Docker group changes to take effect."

    # Set up a temporary cron job to resume after reboot
    setup_resume_cron

    # Prompt for reboot
    read -p "A reboot is required to apply all changes. Do you want to reboot now? (y/n): " REBOOT
    if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
      update_marker "post-reboot"
      echo "Rebooting now..."
      sudo reboot
    else
      echo "Please remember to reboot your system later to apply all changes."
      remove_resume_cron
      exit 0
    fi
    ;;
  "post-reboot")
    # Remove the temporary cron job
    remove_resume_cron

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

    # Clone the repository if it doesn't already exist
    if [ ! -d "balexto" ]; then
      git clone https://github.com/Th1nk7/balexto.git
    else
      echo "Repository 'balexto' already exists. Skipping clone."
    fi

    cd balexto/ansible-playbook

    # Install Ansible Galaxy collections
    ~/ansible-venv/bin/ansible-galaxy collection install community.general

    # Run the Ansible playbook
    ~/ansible-venv/bin/ansible-playbook -i inventory playbook.yml --connection=local

    # Set up a cron job for automatic DNS updates
    CRON_JOB="@hourly ~/ansible-venv/bin/ansible-playbook -i ~/balexto/ansible-playbook/inventory ~/balexto/ansible-playbook/playbook.yml --tags update_dns --connection=local"
    (crontab -l 2>/dev/null | grep -v "ansible-playbook.*--tags update_dns"; echo "$CRON_JOB") | crontab -

    # Cleanup marker file
    rm -f "$MARKER_FILE"
    ;;
  *)
    echo "Unknown progress marker. Starting from the beginning."
    rm -f "$MARKER_FILE"
    exec "$0"
    ;;
esac