## Full Coder Guide for K3s

K3s is a lightweight Kubernetes distribution that is easy to install and manage. It is a great option for running Coder on a single node or a small cluster. This guide will walk you through installing K3s on a single node and then installing Coder on top of it.


# Installing K3s

```bash
/usr/local/bin/k3s-uninstall.sh
```

```bash
export DOMAIN=mcaq.me
export DOMAIN_NAME=mcaq-me
export EMAIL=adam.mcarthur62@gmail.com
```

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install curl ca-certificates open-iscsi wireguard -y
```

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh
```

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

```bash
curl -sfL https://get.k3s.io | sh -s server \
--cluster-init \
--flannel-backend=wireguard \
--write-kubeconfig-mode 600
```

```bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml >> .zshrc
```

```bash
sudo chown adam:root /etc/rancher/k3s/k3s.yaml
```

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

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.crds.yaml
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/cert-manager.yaml \
| envsubst \
| helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.11.0 --values -
```

https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/#api-tokens
https://dash.cloudflare.com/profile/api-tokens

```bash
export CF_TOKEN=TOKEN
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/cloudflare/token.yaml \
| envsubst \
| kubectl apply -f -
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/cloudflare/issuer.yaml \
| envsubst \
| kubectl apply -f -
```

```bash
kubectl create namespace coder
```


```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/certs.yaml \
| envsubst \
| kubectl apply -f -
```

# Add Middleware
```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/middleware/https-redirect.yaml \
| envsubst \
| kubectl apply -f -
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/traefik/dashboard-ingress.yaml \
| envsubst \
| kubectl delete -f -
```

```bash
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/manifests/traefik/dashboard-ingress-https.yaml \
| envsubst \
| kubectl apply -f -
```

# Coder Install

```bash
# Install PostgreSQL
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install coder-db bitnami/postgresql \
    --namespace coder \
    --set auth.username=coder \
    --set auth.password=coder \
    --set auth.database=coder \
    --set persistence.size=10Gi
```

```bash
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

## For Updating

```bash
helm repo update
wget -O- -q https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/helm/coder.yml \
| envsubst \
| helm upgrade coder coder-v2/coder --namespace coder --values -
```