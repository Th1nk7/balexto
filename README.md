# balexto

## Overview
This project sets up a Docker-based WireGuard VPN server with Cloudflare Dynamic DNS updates.

## Prerequisites
- A Linux-based system (e.g., Ubuntu)
- `sudo` privileges
- Python 3 installed

## Setup Instructions
1. Clone this repository:
   ```bash
   git clone https://github.com/Th1nk7/balexto.git
   cd balexto
   ```

2. Run the setup script:
   ```bash
   chmod +x setup-main.sh
   ./setup-main.sh
   ```

3. Verify the setup:
   - Check if Docker is installed: `docker --version`
   - Check if Ansible is installed: `~/ansible-venv/bin/ansible --version`

4. Retrieve the WireGuard configuration:
   ```bash
   cat /etc/wireguard/wg0.conf
   ```

## Notes
- The script sets up a cron job to update the Cloudflare DNS record every hour.
- Ensure you replace the placeholder `CLOUDFLARE_API_TOKEN_HERE` with your actual Cloudflare API token.
