FROM codercom/enterprise-base:ubuntu

ENV GOROOT /usr/local/go
ENV GOPATH /home/coder/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
ENV PATH /home/coder/.local/bin:$PATH
ENV PATH $GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}

ENV CGO_ENABLED 0

ENV DEBIAN_FRONTEND noninteractive

USER root

# Install apt packages
RUN apt update &&\
    apt upgrade -y &&\
    apt install -y \
        nano \
        build-essential &&\
    # Cleanup
    apt clean &&\
    rm -rf /var/lib/apt/lists/*

# Golang Install go 1.20.7
RUN wget https://dl.google.com/go/go1.20.7.linux-amd64.tar.gz && \
    tar -xvf go1.20.7.linux-amd64.tar.gz && \
    mv go /usr/local && \
    rm go1.20.7.linux-amd64.tar.gz

# Install PYYAML
RUN pip3 install pyyaml

# Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&\
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&\
    rm kubectl

USER coder

COPY ./dockerfiles/kubernetes.sh /usr/local/bin/kubernetes.sh
RUN sudo chmod +x /usr/local/bin/kubernetes.sh

