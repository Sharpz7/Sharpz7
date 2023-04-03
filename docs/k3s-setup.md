sudo apt install -y nftables

Get Helm

```
HELM_DOWNLOAD_URL='https://get.helm.sh/helm-vXXXX-rc.1-linux-arm64.tar.gz'
wget $HELM_DOWNLOAD_URL
tar -zxvf helm-v3.0.0-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/helm
rm -r linux-amd64/helm
```

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


Install k3s
https://k3s.rocks/https-cert-manager-letsencrypt/

```
export DOMAIN=compute.mcaq.me
export EMAIL=adam.mcarthur62@gmail.com

sudo apt update && \
sudo apt upgrade -y && \
sudo apt install curl -y && \
sudo apt install ca-certificates -y && \
sudo apt install open-iscsi -y && \
sudo apt install wireguard -y


git clone https://github.com/askblaker/k3s.rocks.git
cd k3s.rocks

curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.23.5+k3s1 sh -s server \
--cluster-init \
--flannel-backend=wireguard \
--write-kubeconfig-mode 600 && \
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml >> .zshrc && \
cat ./manifests/traefik-config.yaml | envsubst | kubectl apply -f -

sudo chown adam:root /etc/rancher/k3s/k3s.yaml

kubectl get nodes

cd manifests

kubectl apply -f ./whoami/whoami-deployment.yaml
kubectl apply -f ./whoami/whoami-service.yaml
kubectl apply -f ./whoami/whoami-ingress.yaml

# check http://compute.mcaq.me/foo

kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl get pods --namespace cert-manager
cat letsencrypt-prod.yaml | envsubst | kubectl apply -f -
cat traefik-https-redirect-middleware.yaml | envsubst | kubectl apply -f -
cat ./whoami/whoami-ingress-tls.yaml | envsubst | kubectl apply -f -

# Check https://whoami.compute.mcaq.me

kubectl get ingress --all-namespaces

cat traefik-dashboard-service.yaml | envsubst | kubectl apply -f -
cat traefik-dashboard-ingress.yaml | envsubst | kubectl apply -f -

kubectl get ingress --all-namespaces

sudo apt install htpasswd

htpasswd -c mynewcreds adam
cat mynewcreds | base64 > mynewcreds64

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: my-basic-auth-secret
  namespace: default
data:
  users: |2
    $(head -1 mynewcreds64 | tail -1)
EOF

cat basic-auth-middleware.yaml | envsubst | kubectl apply -f -

cat traefik-dashboard-ingress-basic-auth.yaml | envsubst | kubectl apply -f -

ADD REDIRECT MIDDLEWARE INTO INGRESS'S
AND SWITCH THEIR ORDER SO THAT REDIRECT HAPPENS FIRST
```
/usr/local/bin/k3s-uninstall.sh

kubectl get pv --all-namespaces