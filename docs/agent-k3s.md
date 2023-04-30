https://github.com/alexellis/k3sup

# Install

```bash
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/
```

# Install on all agents

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install curl ca-certificates open-iscsi wireguard -y
```

# Usage

ON ALL SERVERS/AGENTS

```bash
sudo visudo
```
```bash
# Then add to the bottom of the file
# replace "alex" with your username i.e. "ubuntu"
alex ALL=(ALL) NOPASSWD: ALL
```

```bash

export SERVER_PORT=4587
export SERVER_IP=45.13.59.104

export AGENT_IP=173.212.252.82
export AGENT_PORT=5746

export USER=adam
export SSH_KEY=$HOME/.ssh/compute.ssh
```

```bash
k3sup join --ip $AGENT_IP --ssh-port $AGENT_PORT --server-ip $SERVER_IP --user $USER --ssh-key $SSH_KEY --server-ssh-port $SERVER_PORT
```

# Workarounds

## Disable 2 Factor

```bash
sudo nano /etc/ssh/sshd_config
```
```bash

# Change this line
PasswordAuthentication no

# Comment these lines
#ChallengeResponseAuthentication no
#USEPAM no
#AuthenticationMethods ...
```

# Then restart ssh
```bash
sudo systemctl restart ssh
```

## Add ssh key across servers
See [this](./setting-up-a-server.md).

Remove key after adding it to all servers.

# Removal

```bash
/usr/local/bin/k3s-agent-uninstall.sh
```

# Debugging

```bash
sudo journalctl -u k3s-agent -f
```

# k3s config update

```bash
sudo nano /etc/systemd/system/k3s.service
sudo systemctl daemon-reload
sudo systemctl restart k3s
```