FROM codercom/enterprise-base:ubuntu

ENV PATH $HOME/.local/bin:$PATH

ENV DEBIAN_FRONTEND noninteractive

USER root

# Install apt packages
RUN add-apt-repository ppa:deadsnakes/ppa &&\
    apt-get update -y &&\
    apt-get upgrade -y &&\
    apt-get install -y nano python3.9 &&\
    # Cleanup
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/*

# Python 3.9 install
RUN curl -sSL https://install.python-poetry.org | python3 -

USER coder