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
}

variable "cpu" {
  description = "CPU (__ cores)"
  default     = 2
  validation {
    condition = contains([
      "1",
      "2",
      "4",
      "6",
      "8",
      "10",
    ], var.cpu)
    error_message = "Invalid cpu!"
  }
}

variable "memory" {
  description = "Memory (__ GB)"
  default     = 4
  validation {
    condition = contains([
      "1",
      "2",
      "4",
      "8",
      "16",
      "32",
    ], var.memory)
    error_message = "Invalid memory!"
}
}

variable "disk_size" {
  description = "Disk size (__ GB)"
  default     = 50
}

variable "image" {
  description = <<-EOF
  Container images from coder-com
  EOF
  default = "codercom/enterprise-base:ubuntu"
  validation {
    condition = contains([
      "codercom/enterprise-base:ubuntu",
      "sharp6292/armada-image:latest"
    ], var.image)
    error_message = "Invalid image!"
}
}

variable "dotfiles_uri" {
  description = <<-EOF
  Dotfiles repo URI (optional)
  see https://dotfiles.github.io
  EOF
  default     = ""
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
        storage = "${var.disk_size}Gi"
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
    # Run Docker in Background
    sudo dockerd -H tcp://127.0.0.1:2375 &

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

    # Get Dotfiles
    ${var.dotfiles_uri != "" ? "git clone ${var.dotfiles_uri}.git" : ""}
    ${var.dotfiles_uri != "" ? "cd dotfiles && chmod +x install" : ""}
    ${var.dotfiles_uri != "" ? "./install" : ""}

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
      volume_mount {
        mount_path = "/var/lib/docker"
        name       = "dind-storage"
        read_only  = false
      }
      volume_mount {
        mount_path = "/lib/modules"
        name       = "modules"
        read_only  = true
      }
      volume_mount {
        mount_path = "/sys/fs/cgroup"
        name       = "cgroup"
        read_only  = false
      }
      env {
        name  = "DOCKER_HOST"
        value = "localhost:2375"
      }

      resources {
        requests = {
          cpu    = "500m"
          memory = "500Mi"
        }
        limits = {
          cpu    = "${var.cpu}"
          memory = "${var.memory}G"
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

    volume {
      name = "usr-local"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
        read_only  = false
      }
    }

    volume {
      name = "dind-storage"
      empty_dir {}
    }

    volume {
      name = "modules"
      host_path {
        path = "/lib/modules"
        type = "Directory"
      }
    }
    volume {
      name = "cgroup"
      host_path {
        path = "/sys/fs/cgroup"
        type = "Directory"
      }
    }

    affinity {
      pod_anti_affinity {
        // This affinity attempts to spread out all workspace pods evenly across
        // nodes.
        preferred_during_scheduling_ignored_during_execution {
          weight = 1
          pod_affinity_term {
            topology_key = "kubernetes.io/hostname"
            label_selector {
              match_expressions {
                key      = "app.kubernetes.io/name"
                operator = "In"
                values   = ["coder-workspace"]
              }
            }
          }
        }
      }
    }
  }
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id
  item {
    key   = "CPU"
    value = "${var.cpu} cores"
  }
  item {
    key   = "memory"
    value = "${var.memory}GB"
  }
  item {
    key   = "image"
    value = "docker.io/${var.image}"
  }
  item {
    key   = "disk"
    value = "${var.disk_size}GiB"
  }
}