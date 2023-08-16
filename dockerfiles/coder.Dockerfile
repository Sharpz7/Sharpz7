FROM mcr.microsoft.com/devcontainers/base:bullseye

# general env
ENV PATH /home/coder/.local/bin:$PATH

# golang env
ENV GOROOT /usr/local/go
ENV GOPATH /home/coder/projects/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH

# kubernetes env
ENV PATH $GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}

ENV DEBIAN_FRONTEND noninteractive

USER root

# Install apt packages
RUN add-apt-repository ppa:deadsnakes/ppa &&\
    apt-get update &&\
    apt-get upgrade -y &&\
    apt-get install -y \
        nano \
        python3.9 \
        python3-pip \
        yarn \
        nodejs \
        build-essential &&\
    # Cleanup
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# Golang Install go1.20.7
RUN wget https://dl.google.com/go/go1.20.7.linux-amd64.tar.gz && \
    tar -xvf go1.20.7.linux-amd64.tar.gz && \
    mv go /usr/local && \
    rm go1.20.7.linux-amd64.tar.gz && \
    # Install go go1.19.7
    go install golang.org/dl/go1.19.7@latest && \
    go1.19.7 download && \
    rm -rf /root/sdk/go1.19.7/go1.19.7.linux-amd64.tar.gz

# Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&\
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&\
    rm kubectl

# Install whichever Node version is LTS
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash - &&\
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install jupyter
RUN pip3 install jupyterlab==3.5.2 && \
    pip3 install jupyter-core==5.1.3 && \
    pip3 install notebook==6.5.2

USER coder

RUN PROTOC_ZIP=protoc-3.17.3-linux-x86_64.zip && \
    sudo curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.17.3/$PROTOC_ZIP && \
    sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc && \
    sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*' && \
    sudo rm -f $PROTOC_ZIP && \
    sudo chmod +x /usr/local/bin/protoc

# Install PYYAML
RUN pip3 install pyyaml

COPY kubernetes.sh ~/kubernetes.sh