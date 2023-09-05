# Kubernetes Guide

This document contains my personal notes on installing useful K8s Tools and objects.

# Table of Contents

1. [Env Vars](#useful-env-vars)
2. [Setting Up Cert Manager](#Setting-Up-Cert-Manager)
3. [Setting up Coder](#Setting-up-Coder)
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
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/certs.yaml \
| envsubst \
| kubectl apply -f -
```

# Setting up Coder

## Setting up Github and Git Auth

Follow this guide for Github Auth: https://coder.com/docs/v2/latest/admin/auth

And this guide for using git in coder: https://coder.com/docs/v2/latest/admin/git-providers

```bash
kubectl create namespace coder
```

# Useful Middlewares

## https Redirect

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/middleware/https-redirect.yaml \
| envsubst \
| kubectl apply -f -
```