# Kubernetes Guide

This document contains my personal notes on installing useful K8s Tools and objects.

# Table of Contents

1. [Env Vars](#useful-env-vars)
2. [Setting Up Cert Manager](#Setting-Up-Cert-Manager)
3. [Setting up Coder](#Setting-up-Coder)
4. [Using GPUs on K3s](#Using-GPUs-on-K3s)
4. [Middlewares](#useful-middlewares)

# Useful Env Vars

These are the Enviromental Variables that might be needed

```bash
export DOMAIN=mcaq.me
export DOMAIN_NAME=mcaq-me
export EMAIL=adam.mcarthur62@gmail.com
```

# Setting Up Cert Manager

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/cert-manager.yaml \
| envsubst \
| helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.11.0 --values -
```

Create a token as specified here https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/#api-tokens
(Direct Link: https://dash.cloudflare.com/profile/api-tokens)

```bash
export CF_TOKEN=TOKEN

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/cloudflare/token.yaml \
| envsubst \
| kubectl apply -f -

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/cloudflare/issuer.yaml \
| envsubst \
| kubectl apply -f -
```

```bash
kubectl create namespace coder

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/certs.yaml \
| envsubst \
| kubectl apply -f -
```

# Setting up Coder

## Setting up Github and Git Auth

Follow this guide for Github Auth: https://coder.com/docs/v2/latest/admin/auth

Note that the callback URL is https://coder.domain.com/api/v2/users/oauth2/github/callback

Also note the permissions:

Orgs/Members: Read Only
Account/Email: Read Only

```bash
export CODER_ID=XXXX
export CODER_SECRET=XXXX
```

And this guide for using git in coder: https://coder.com/docs/v2/latest/admin/git-providers

Also note the permissions (All repo-level):

- Content: Read/Write
- Pull Requests: Read/Write
- Workflows: Read/Write

```bash
export CODER_GIT_ID=XXXX
export CODER_GIT_SECRET=XXXX
```


```bash
kubectl create namespace coder

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install coder-db bitnami/postgresql \
    --namespace coder \
    --set auth.username=coder \
    --set auth.password=coder \
    --set auth.database=coder \
    --set persistence.size=10Gi


# Note that https://github.com/bitnami/charts/tree/main/bitnami/postgresql-ha#adjust-permissions-of-persistent-volume-mountpoint
# might be needed to fix the permissions of the volume

helm repo add coder-v2 https://helm.coder.com/v2
```

```bash
kubectl create secret generic coder-db-url -n coder \
   --from-literal=url="postgres://coder:coder@coder-db-postgresql.coder.svc.cluster.local:5432/coder?sslmode=disable"
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/coder.yml \
| envsubst \
| helm install coder coder-v2/coder --namespace coder --values -
```

### For Updating

```bash
helm repo update
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/coder.yml \
| envsubst \
| helm upgrade coder coder-v2/coder --namespace coder --values -
```

# Using GPUs on K3s

```bash
sudo apt-get install ubuntu-drivers-common
sudo ubuntu-drivers install
```

Restart K3s on the Agent Node after installing the relavent GPU Drivers

```bash
sudo systemctl restart k3s-agent

# You can then check the runtime is present with
sudo grep nvidia /var/lib/rancher/k3s/agent/etc/containerd/config.toml
sudo ctr image pull docker.io/nvidia/cuda:11.6.2-base-ubuntu20.04
sudo ctr run --rm -t --runc-binary=/usr/bin/nvidia-container-runtime --env NVIDIA_VISIBLE_DEVICES=all docker.io/nvidia/cuda:11.6.2-base-ubuntu20.04 cuda-11.6.2-base-ubuntu20.04 nvidia-smi
```

# Useful Middlewares

## https Redirect

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/middleware/https-redirect.yaml \
| envsubst \
| kubectl apply -f -
```
