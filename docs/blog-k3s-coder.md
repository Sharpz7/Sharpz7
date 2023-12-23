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
export AUTH_SECRET=$(htpasswd -nbB $DOCKER_USERNAME $DOCKER_PASSWORD)
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