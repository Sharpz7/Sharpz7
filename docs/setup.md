# Setup Guide

This document contains my personal Notes on VPS Setup, K3s setup and Kubernetes Objects Setup

# Table of Contents
1. [VPS Setup](#vps-setup)
    - 1.1. [SSH Configuration](#ssh-user-creation)
    - 1.2. [Firewall Management](#Handle-ssh-key-setup-and-stopping-root-logins)
    - 1.3. [UFW Firewall](#Use-ufw-to-manage-firewall)
2. [K3s Setup](#k3s-setup)
    - 2.1. [Helm](#installing-helm)
    - 2.2. [KubeCTL](#Installing-Kubectl)
    - 2.3. [K3s Server](#Installing-k3s)
    - 2.4. [Installing Agents](#Installing-K3s-Agents)
    - 2.5. [Debugging Tips](#Debugging)


# VPS Setup

## SSH User Creation

```bash
adduser adam
apt install sudo
reboot now

visudo

# Add this line
# `adam   ALL=(ALL:ALL) ALL`
```

Add this to your .bash_profile
```bash
if [ -f ~/.bashrc ]; then
  . ~/.bashrc
fi
```

Get putty here: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

```bash
su adam
mkdir ~/.ssh

# Add your key here
touch ~/.ssh/authorized_keys
nano ~/.ssh/authorized_keys

chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

## Handle ssh key setup and stopping root logins

```bash
sudo nano /etc/ssh/sshd_config

# Change Port, PasswordAuthentication,
sudo systemctl restart ssh
```

## Use ufw to manage firewall

```bash
sudo apt install ufw

sudo ufw default allow outgoing
sudo ufw default deny incoming

# Add ssh ports
sudo ufw allow 5522/tcp
sudo ufw allow http
sudo ufw allow https

ufw allow from 10.42.0.0/16 to any #pods
ufw allow from 10.43.0.0/16 to any #services

# For k3s
sudo ufw allow 6443/tcp
sudo ufw allow 9100/tcp
ufw allow proto udp from any to any port 51820

# Verify Rules
sudo ufw show added

# Enable
sudo ufw enable
```

# K3s Setup

## Installing Helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh
```

## Installing Kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Installing K3s

```bash
# Remove if installed before.
/usr/local/bin/k3s-uninstall.sh

sudo apt update
sudo apt upgrade -y
sudo apt install curl ca-certificates open-iscsi wireguard -y

sudo reboot

export DOMAIN=nidus.mcaq.me

curl -sfL https://get.k3s.io | sh -s server \
--cluster-init \
--flannel-backend=wireguard-native \
--write-kubeconfig-mode 600 \
--tls-san ${DOMAIN}
```

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml >> .zshrc
sudo chown adam:root /etc/rancher/k3s/k3s.yaml
```

## Add Middleware for auto https

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/middleware/https-redirect.yaml \
| envsubst \
| kubectl apply -f -
```

## Installing K3s Agents

Note that this assumes 1 ssh key across the servers.

```bash
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

# Set the following line on server and agents
# adam ALL=(ALL) NOPASSWD: ALL
visudo
```

```bash

export SERVER_PORT=pppp
export SERVER_IP=1.1.1.1
export SERVER_USER=adam

export AGENT_IP=0.0.0.0
export AGENT_PORT=pppp
export AGENT_USER=adam

export SSH_KEY=$HOME/.ssh/compute.ssh

k3sup join --ip $AGENT_IP --ssh-port $AGENT_PORT --server-ip $SERVER_IP --server-user $SERVER_USER --user $AGENT_USER --ssh-key $SSH_KEY --server-ssh-port $SERVER_PORT
```

### Removing an install

```bash
/usr/local/bin/k3s-agent-uninstall.sh
```

## Debugging

```bash
# Logs
sudo journalctl -u k3s-agent -f

# Config Changes
sudo nano /etc/systemd/system/k3s.service
sudo systemctl daemon-reload
sudo systemctl restart k3s
```
