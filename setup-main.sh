#!/bin/bash

set -e  # Exit on error
sudo apt update && sudo apt upgrade -y

sudo apt install -y python3 python3-pip git

pip3 install --user ansible

export PATH="$HOME/.local/bin:$PATH"

git clone https://github.com/Th1nk7/balexto.git
cd balexto/ansible-playbook

ansible-playbook -i localhost playbook.yml --connection=local
