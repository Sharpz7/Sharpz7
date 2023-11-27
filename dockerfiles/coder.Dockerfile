FROM codercom/enterprise-base:ubuntu

# general env
ENV PATH /home/coder/.local/bin:$PATH

# flutter
ENV PATH $PATH:/home/coder/flutter/bin

# kubernetes env
ENV PATH $GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}

ENV DEBIAN_FRONTEND noninteractive

USER root

# Install apt packages
RUN apt update &&\
    apt upgrade -y &&\
    apt install -y apt-transport-https &&\
    wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - &&\
    wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list &&\
    add-apt-repository ppa:deadsnakes/ppa &&\
    apt update &&\
    apt remove -y python3 python3-pip &&\
    apt install -y \
        nano \
        python3.9 \
        python3-pip \
        npm &&\
    # Cleanup
    apt clean &&\
    rm -rf /var/lib/apt/lists/*

# Golang Install
RUN curl -L "https://go.dev/dl/go1.20.linux-amd64.tar.gz" | tar -C /usr/local -xzvf - && \
    go version

# Kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &&\
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl &&\
    rm kubectl

# Install jupyter
RUN pip3 install jupyterlab==3.5.2 && \
    pip3 install jupyter-core==5.1.3 && \
    pip3 install notebook==6.5.2

RUN chown -R coder:coder /home/coder

USER coder

# protoc
RUN PROTOC_ZIP=protoc-3.17.3-linux-x86_64.zip && \
    sudo curl -OL https://github.com/protocolbuffers/protobuf/releases/download/v3.17.3/$PROTOC_ZIP && \
    sudo unzip -o $PROTOC_ZIP -d /usr/local bin/protoc && \
    sudo unzip -o $PROTOC_ZIP -d /usr/local 'include/*' && \
    sudo rm -f $PROTOC_ZIP && \
    sudo chmod +x /usr/local/bin/protoc

# Install whichever Node version is LTS
RUN sudo npm install -g n && \
    sudo n lts && \
    sudo n prune && \
    sudo npm install -g yarn