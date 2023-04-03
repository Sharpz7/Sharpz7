terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.6.6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
  }
}

locals {
  use_kubeconfig = false
  namespace      = "coder"
  cpu = 2
  memory = 4
  disk_size = 5
}

variable "image" {
  description = <<-EOF
  Container images from coder-com
  EOF
  default = "codercom/enterprise-base:ubuntu"
  validation {
    condition = contains([
      "codercom/enterprise-base:ubuntu",
    ], var.image)
    error_message = "Invalid image!"
}
}

provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = local.use_kubeconfig == true ? "~/.kube/config" : null
}

data "coder_workspace" "me" {}


resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}-home"
    namespace = local.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
      "app.kubernetes.io/part-of"  = "coder"
      // Coder specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.me.id
      "com.coder.workspace.name" = data.coder_workspace.me.name
      "com.coder.user.id"        = data.coder_workspace.me.owner_id
      "com.coder.user.username"  = data.coder_workspace.me.owner
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${local.disk_size}Gi"
      }
    }
  }
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"
  dir  = "/home/coder"

  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
  }

  startup_script = <<EOT
    #!/bin/bash
    # home folder can be empty, so copying default bash settings
    if [ ! -f ~/.profile ]; then
      cp /etc/skel/.profile $HOME
    fi
    if [ ! -f ~/.bashrc ]; then
      cp /etc/skel/.bashrc $HOME
    fi

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --version 4.9.1 | tee code-server-install.log

    sleep 5

    wget https://files.mcaq.me/5x2r7.vsix
    code-server --install-extension 5x2r7.vsix
    rm 5x2r7.vsix
    code-server --install-extension vhdlwhiz.vhdl-by-vhdlwhiz
    code-server --install-extension mshr-h.veriloghdl


    # Create Projects Folder
    mkdir -p /home/coder/projects

    # Create a Matlab, Python and C folder within Projects
    # with an example file in each
    mkdir -p /home/coder/projects/matlab
    mkdir -p /home/coder/projects/python
    mkdir -p /home/coder/projects/c
    mkdir -p /home/coder/projects/vhdl
    mkdir -p /home/coder/projects/vhdl/test
    mkdir -p /home/coder/projects/vhdl/src

    sudo apt-get install -y ghdl
    sudo curl -s -L https://github.com/SharpSet/sharpdev/releases/download/1.7/install.sh | sudo bash

    export ADDRESS="https://raw.githubusercontent.com/Sharpz7/Sharpz7/main/templates/copilot-vhdl/files"
    export ADDRESS_LOCAL="/home/coder/projects"

    wget "$ADDRESS/hello.c" -O "$ADDRESS_LOCAL/c/hello.c"
    wget "$ADDRESS/hello.py" -O "$ADDRESS_LOCAL/python/hello.py"
    wget "$ADDRESS/hello.m" -O "$ADDRESS_LOCAL/matlab/hello.m"
    wget "$ADDRESS/test.vhd" -O "$ADDRESS_LOCAL/vhdl/test/test.vhd"
    wget "$ADDRESS/test_TB.vhd" -O "$ADDRESS_LOCAL/vhdl/test/test_TB.vhd"
    wget "$ADDRESS/sharpdev.yml" -O "$ADDRESS_LOCAL/vhdl/sharpdev.yml"
    wget "$ADDRESS/README.md" -O "$ADDRESS_LOCAL/vhdl/README.md"
    wget "$ADDRESS/start.vhd" -O "$ADDRESS_LOCAL/vhdl/src/start.vhd"

    # Handle

    code-server --auth none --port 13337 | tee code-server-install.log &
  EOT
}

# code-server
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/coder"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}

resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count
  metadata {
    name      = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    namespace = local.namespace
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    }
  }
  spec {
    container {
      name    = "dev"
      image   = var.image
      command = ["sh", "-c", coder_agent.main.init_script]
      security_context {
        privileged = true
      }
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }
      volume_mount {
        mount_path = "/home/coder"
        name       = "home"
        read_only  = false
      }

      resources {
        requests = {
          cpu    = "500m"
          memory = "500Mi"
        }
        limits = {
          cpu    = "${local.cpu}"
          memory = "${local.memory}G"
        }
      }
    }

    volume {
      name = "home"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
        read_only  = false
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU"
    value = "${local.cpu} cores"
  }
  item {
    key   = "memory"
    value = "${local.memory}GB"
  }
  item {
    key   = "image"
    value = "docker.io/${var.image}"
  }
  item {
    key   = "disk"
    value = "${local.disk_size}GiB"
  }
}