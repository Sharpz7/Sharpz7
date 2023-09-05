# Kubernetes Guide

This document contains my personal Notes on VPS Setup, K3s setup and Kubernetes Objects Setup

# Table of Contents
1. [VPS Setup](#vps-setup)
    - 1.1. [SSH Configuration](#ssh-user-creation)
    - 1.2. [Firewall Management](#Handle-ssh-key-setup-and-stopping-root-logins)
    - 1.3. [UFW Firewall](#Use-ufw-to-manage-firewall)
2. [K3s Setup](#k3s-setup)
    - 2.1. [Helm](##installing-helm)
    - 2.2. [KubeCTL](##Installing-Kubectl)
    - 2.3. [K3s Server](##Installing-k3s)
    - 2.4. [Installing Agents](##Installing-K3s-Agents)
    - 2.5. [Debugging Tips](##Debugging)
3. [Installing tools on Kubernetes](Installing-tools-on-Kubernetes)
    - 3.1. [Env Vars](##Env-Vars)

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

# Add ssh ports
sudo ufw allow 5522/tcp
sudo ufw allow http
sudo ufw allow https

# For k3s
sudo ufw allow 6443/tcp

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
--flannel-iface=wg1 \
--write-kubeconfig-mode 600 \
--tls-san ${DOMAIN}
```

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml >> .zshrc
sudo chown adam:root /etc/rancher/k3s/k3s.yaml
```

## Installing K3s Agents

Note that this assumes 1 ssh key across the servers.

```bash
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
```

```bash

export SERVER_PORT=pppp
export SERVER_IP=1.1.1.1

export AGENT_IP=0.0.0.0
export AGENT_PORT=pppp

export USER=adam
export SSH_KEY=$HOME/.ssh/compute.ssh

k3sup join --ip $AGENT_IP --ssh-port $AGENT_PORT --server-ip $SERVER_IP --user $USER --ssh-key $SSH_KEY --server-ssh-port $SERVER_PORT
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


# Installing tools on Kubernetes

## Env Vars

These are the Enviromental Variables that might be needed

```bash
export DOMAIN=nidus.mcaq.me
export DOMAIN_NAME=nidus-mcaq-me
export EMAIL=adam.mcarthur62@gmail.com
```

## Getting