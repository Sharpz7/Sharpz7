terraform {
  required_providers {
    ssh = {
      source  = "loafoe/ssh"
      version = "2.6.0"
    }
    coder = {
      source  = "coder/coder"
      version = "0.11.0"
    }
  }
}

variable "encoded_ssh_private_key" {
  description = "The base64 encoded private SSH key used to connect to the Slurm cluster's head node"
  type        = string
  sensitive   = false  # This ensures Terraform doesn't print the key in logs
}

provider "coder" {}

resource "coder_agent" "main" {
  arch                   = "amd64"
  os                     = "linux"

  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }

  # None of these will mean anything in Compute Canada
  metadata {
    key          = "cpu"
    display_name = "CPU Usage"
    interval     = 5
    timeout      = 5
    script       = <<-EOT
      #!/bin/bash
      set -e
      top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
    EOT
  }
  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    interval     = 5
    timeout      = 5
    script       = <<-EOT
      #!/bin/bash
      set -e
      free -m | awk 'NR==2{printf "%.2f%%\t", $3*100/$2 }'
    EOT
  }
  metadata {
    key          = "disk"
    display_name = "Disk Usage"
    interval     = 600 # every 10 minutes
    timeout      = 30  # df can take a while on large filesystems
    script       = <<-EOT
      #!/bin/bash
      set -e
      df /home/coder | awk '$NF=="/"{printf "%s", $5}'
    EOT
  }
  metadata {
    display_name = "GPU Usage"
    interval     = 10
    key          = "4_gpu_usage"
    script       = <<EOT
      (nvidia-smi 1> /dev/null 2> /dev/null) && (nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{printf "%s%%", $1}') || echo "N/A"
    EOT
  }
  metadata {
    display_name = "GPU Memory Usage"
    interval     = 10
    key          = "5_gpu_memory_usage"
    script       = <<EOT
      (nvidia-smi 1> /dev/null 2> /dev/null) && (nvidia-smi --query-gpu=utilization.memory --format=csv,noheader,nounits | awk '{printf "%s%%", $1}') || echo "N/A"
    EOT
  }
}

resource "ssh_resource" "init" {
  host         = "narval.computecanada.ca"
  user         = "amcarth1"
  private_key  = var.encoded_ssh_private_key

  when         = "create" # Default

  file {
    content = <<EOT
      #!/usr/bin/env sh
      set -eux
      echo DIR=~/projects/def-jjaremko/amcarth1/test/
      cd $DIR

      export BINARY_NAME=coder
      export BINARY_URL=https://coder.mcaq.me/bin/coder-linux-amd64
      curl -fsSL --compressed $BINARY_URL -o $BINARY_NAME

      chmod u+x coder.sh
      chmod u+x $BINARY_NAME

      salloc --time=0-3:0:0 --ntasks=1 --cpus-per-task=1 --mem=4G --account=def-jjaremko
    EOT
    destination = "/home/amcarth1/alloc.sh"
    permissions = "0700"
  }

  commands = [
    "/home/amcarth1/alloc.sh",
  ]
}

# Nodes nc31104 are ready for job
# I only want to find the node name in between the word "Nodes" and "are"
output "result" {
  value = regexall("Nodes (.*?) are", ssh_resource.init.output)
}

resource "ssh_resource" "node_ssh" {
  # Ensure this resource is created after ssh_resource.init
  depends_on = [ssh_resource.init]

  # Host details - using the output of the first SSH resource
  host        = output.result
  user        = "amcarth1"
  private_key = var.encoded_ssh_private_key

  # ProxyJump configuration
  proxy {
    host        = "narval.computecanada.ca"
    user        = "amcarth1"
    private_key = var.encoded_ssh_private_key
  }

  file {
    content = <<EOT
      #!/usr/bin/env sh
      set -eux

      export CODER_AGENT_AUTH=\"token\"
      export CODER_AGENT_URL=\"https://coder.mcaq.me/\"
      exec ~/projects/def-jjaremko/amcarth1/test/coder agent
    EOT
    destination = "/home/amcarth1/coder-agent.sh"
    permissions = "0700"
  }

  # The actions to be performed via SSH on the node
  commands = [
    "/home/amcarth1/coder-agent.sh"
  ]
}