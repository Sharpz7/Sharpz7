curl -fsSL https://coder.com/install.sh | sh

coder login domain

coder

Document template process
https://github.com/bpmct/coder-templates

# Sysbox
kubectl label nodes <node-name> sysbox-install=yes
kubectl apply -f https://raw.githubusercontent.com/nestybox/sysbox/master/sysbox-k8s-manifests/sysbox-install.yaml

https://coder.com/docs/v2/latest/install/kubernetes
