terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.11.0"
    }
    null = {
      source = "hashicorp/null"
    }
  }
}

locals {
  linux_user = "coder"
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

resource "null_resource" "coder_slurm_job" {
  provisioner "local-exec" {
    command = <<EOT
      # SSH into the Slurm cluster's head node
      # Save the private key to a temporary file
      echo "${var.encoded_ssh_private_key}" | base64 -d > /tmp/temp_ssh_key
      chmod 600 /tmp/temp_ssh_key

      # SSH into the Slurm cluster's head node using the private key
      ssh -o StrictHostKeyChecking=no -i /tmp/temp_ssh_key amcarth1@narval.alliancecan.ca <<'ENDSSH'

        echo DIR=~/projects/def-jjaremko/amcarth1/test/
        cd $DIR

        export BINARY_NAME=coder
        export BINARY_URL=https://coder.mcaq.me/bin/coder-linux-amd64
        curl -fsSL --compressed $BINARY_URL -o $BINARY_NAME

        chmod u+x coder.sh
        chmod u+x $BINARY_NAME

        # Create a temporary Slurm job script
        cat > $DIR/coder_slurm_job.sh <<'ENDSCRIPT'
          #!/usr/bin/env sh
          set -eux
          export CODER_AGENT_AUTH=\"token\"
          export CODER_AGENT_URL=\"https://coder.mcaq.me/\"
          exec ~/projects/def-jjaremko/amcarth1/test/coder agent
        ENDSCRIPT

        # Make the script executable
        chmod u+x $DIR/coder_slurm_job.sh

        salloc --time=1:0:0 --mem=3G --ntasks=1 --cpus-per-task=2 --account=def-jjaremko srun $DIR/coder_slurm_job.sh
      ENDSSH

      # Clean up the temporary private key
      rm -f /tmp/temp_ssh_key
    EOT
  }
}

data "coder_workspace" "me" {}
