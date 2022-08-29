#!/bin/bash

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install qemu-guest-agent -y
sudo apt-get install neovim -y
sudo apt-get install git -y
sudo apt-get install curl -y


if [ ${USER} != "mantis"]
then
sudo adduser mantis 
sudo usermod -aG sudo mantis
fi

mkdir /home/mantis/.config
git clone https://github.com/brockhenrie/nvim /home/mantis/.config/nvim

if [[ ${HOSTNAME} != "k3s-"* ]]
then
  read -p "Would you like to install Docker, yes or no?" installDocker
  if [ $installDocker = "yes" ] || [ $installDocker = "y"]
  then 
    curl -sSL https://get.docker.com | bash
    sudo usermod -aG docker mantis
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    sudo apt install -y docker-compose
  fi
fi

sudo apt-get install openssh-server -y
ssh-keygen -t ed25519 -C "mantisd-cloud ${HOSTNAME}"
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519 

sudo ufw allow ssh
sudo  ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 53

if [ ${HOSTNAME} = "unifi-controller" ]
then
  echo "Adding Firewall Rules for ${HOSTNAME}"
  sudo ufw allow 8443
  sudo ufw allow 3478
  sudo ufw allow 10001
  sudo ufw allow 8080
  sudo ufw allow 1900
  sudo ufw allow 8880
  sudo ufw allow 6789
  sudo ufw allow 5514
fi

if [[ ${HOSTNAME} == "k3s-server-"* ]]
then
  echo "Adding Firewall Rules for ${HOSTNAME}"
  sudo ufw allow 6443
  sudo ufw allow 8472
  sudo ufw allow 51820
  sudo ufw allow 51821
  sudo ufw allow 10250
  sudo ufw allow 2379
  sudo ufw allow 2380
fi

if [[ ${HOSTNAME} == "k3s-agent-"* ]]
then
  echo "Adding Firewall Rules for ${HOSTNAME}"
  sudo ufw allow 10250

fi

sudo ufw enable

if [[ ${HOSTNAME} == "k3s-server-"* ]]
then
  curl -sfL https://get.k3s.io | sh -s - server  --disable servicelb --disable traefik --write-kubeconfig-mode 644 --kube-apiserver-arg default-not-ready-toleration-seconds=30 --kube-apiserver-arg default-unreachable-toleration-seconds=30 --kube-controller-arg node-monitor-period=20s --kube-controller-arg node-monitor-grace-period=20s --kubelet-arg node-status-update-frequency=5s 

  sudo cat /var/lib/rancher/k3s/server/node-token
  cp /etc/rancher/k3s/k3s.yaml ~/
fi

if [[ ${HOSTNAME} == "k3s-agent-"* ]]
then
  read -p "What is the IP of the k3s server node?" k3s_ip
  echo
  echo
  k3s_url="https://${k3s_ip}:6443"
  read -sp "Enter Password to get k3s-server node token" sshpassword
  k3s_token=$(sshpass -p ${sshpassword} ssh mantis@${k3s_ip} 'sudo cat /var/lib/rancher/k3s/server/node-token')
  
  curl -sfL https://get.k3s.io | K3S_TOKEN=$k3s_token K3S_URL=$k3s_url sh -s - --kubelet-arg node-status-update-frequency=5s 
fi

