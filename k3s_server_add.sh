#!/bin/bash

serverIp=10.10.10.70
token=B@ckspace1B@ckspace1964

echo "Updating and upgrading apt!"
sudo apt update -y

sudo apt upgrade -y

echo "Setting firewall"

sudo ufw enable

sudo ufw default allow outgoing

sudo ufw deny incoming

sudo ufw allow ssh

sudo ufw allow 443

sudo ufw allow 80

sudo ufw allow 6443
sudo ufw allow 8472
sudo ufw allow 51820
sudo ufw allow 51821
sudo ufw allow 10250
sudo ufw allow 2379
sudo ufw allow 2380

sudo apt install unnattended-upgrades -y

echo "Building k3s and adding node to servers"

curl -sfL https://get.k3s.io | K3S_TOKEN=$token sh -s - server --server https://$serverIp:6443

