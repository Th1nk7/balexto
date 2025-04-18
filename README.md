# balexto

## Step-by-step guide to install:
This is assuming you have a fresh install

- Run the following as a user with sudo capability:
```
sudo apt update && sudo apt upgrade -y && sudo reboot
```
- Wait for server to be done with reboot
- Run the following as a user with sudo capability:
```
git clone https://github.com/Th1nk7/balexto.git && cd balexto && nano setup-main.sh
```
- Replace the following (REMEMBER TO REPLACE SUDO PASSWORD PLACEHOLDER):
```
CLOUDFLARE_EMAIL="your-cloudflare-email@example.com"
CLOUDFLARE_API_TOKEN="your-cloudflare-api-token"
CLOUDFLARE_ZONE="example.com"
CLOUDFLARE_RECORD="vpn.example.com"
export BECOME_PASS="your-sudo-password"
```
- Run the following as a user with sudo capability:
```
chmod +x setup-main.sh
./setup-main.sh
```