## Full Coder Guide for K3s

K3s is a lightweight Kubernetes distribution that is easy to install and manage. It is a great option for running Coder on a single node or a small cluster. This guide will walk you through installing K3s on a single node and then installing Coder on top of it.


```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/traefik/traefig-config.yaml \
| envsubst \
| kubectl apply -f -
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/traefik/dashboard-service.yaml \
| envsubst \
| kubectl apply -f -
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/traefik/dashboard-ingress.yaml \
| envsubst \
| kubectl apply -f -
```

# Test if http://traefik.${DOMAIN}/dashboard/# works




# KimAI Install

```bash
export DOMAIN=mcaq.me
export DOMAIN_NAME=mcaq-me
export KIMAI_USER=adam.mcarthur62@gmail.com
export KIMAI_PASS=<your_password>
```

```bash
helm repo add robjuz https://robjuz.github.io/helm-charts/

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/kimai.yaml \
| envsubst \
| helm install kimai robjuz/kimai2 --namespace default --values -

# for upgrade
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/kimai.yaml \
| envsubst \
| helm upgrade kimai robjuz/kimai2 --namespace default --values -

# for delete
helm delete kimai
```

## Add new user

```bash
kubectl exec --stdin --tty POD_NAME -- /bin/bash

/opt/kimai/bin/console kimai:user:create admin email@domain.com ROLE_SUPER_ADMIN password
```

# Docker Registry Install


```bash
sudo apt-get install apache2-utils

export DOMAIN=mcaq.me
export DOMAIN_NAME=mcaq-me
export AUTH_SECRET=$(htpasswd -nbB <user> <pass>)
```

```bash
helm repo add twuni https://helm.twun.io

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/docker-registry.yaml \
| envsubst \
| helm install docker-registry twuni/docker-registry --namespace default --values -

# for upgrade
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/docker-registry.yaml \
| envsubst \
| helm upgrade docker-registry twuni/docker-registry --namespace default --values -
```

# Overleaf Install

```bash
helm repo add k8s-at-home https://k8s-at-home.com/charts/
helm repo update

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/overleaf.yaml \
| envsubst \
| helm install overleaf k8s-at-home/overleaf --namespace default --values -

# for upgrade
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/overleaf.yaml \
| envsubst \
| helm upgrade overleaf k8s-at-home/overleaf --namespace default --values -
```

# Ialacol Install

```bash
helm repo add ialacol https://chenhunghan.github.io/ialacol
helm repo update

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/ialacol.yaml \
| envsubst \
| helm install orca-mini ialacol/ialacol --namespace default --values -

wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/ialacol/ingress.yml \
| envsubst \
| kubectl delete -f -
```

# ShiftFS

```
sudo apt-get install -y make dkms git wget
git clone -b k5.4 https://github.com/toby63/shiftfs-dkms.git shiftfs-k54
cd shiftfs-k54
./update1
sudo make -f Makefile.dkms
modinfo shiftfs
```

# Using GCloud

https://cloud.google.com/sdk/docs/install#linux

From inside pod