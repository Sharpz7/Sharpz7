terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.11.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
  }
}

# Variables and Locals
# ===================================
locals {
  namespace = "coder"
  use_kubeconfig = false

  node_resources = {
    "vmi1031871.contaboserver.net" = {
      cpu    = 10
      memory = 60
    },
    "vmi261078.contaboserver.net" = {
      cpu    = 4
      memory = 8
    }
  }

  jupyter-type-arg = "${data.coder_parameter.jupyter.value == "notebook" ? "Notebook" : "Server"}"
}
variable "create_tun" {
  type        = bool
  sensitive   = true
  description = "Add a TUN device to the workspace."
  default     = false
}
variable "create_fuse" {
  type        = bool
  description = "Add a FUSE device to the workspace."
  sensitive   = true
  default     = false
}

# Providers
# ===================================
provider "coder" {
}
provider "kubernetes" {
  # Authenticate via ~/.kube/config or a Coder-specific ServiceAccount, depending on admin preferences
  config_path = local.use_kubeconfig == true ? "~/.kube/config" : null
}


# VM Data
# ===================================
resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = kubernetes_pod.main[0].id

  item {
    key   = "Node"
    value = data.coder_parameter.node.value
  }
  item {
    key   = "Disk Size"
    value = data.coder_parameter.disk_size.value
  }
  item {
    key   = "Image"
    value = data.coder_parameter.image.value
  }
  item {
    key   = "DotFile URL"
    value = data.coder_parameter.dotfiles_uri.value
  }
}

# Params
# ===================================
data "coder_parameter" "node" {
  name        = "Cluster Node"
  type        = "string"
  description = "Which Node should the Pod be placed on?"
  mutable     = true
  default     = "vmi1031871.contaboserver.net"
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"

  option {
    name = "10vCPU, 60GB RAM"
    value = "vmi1031871.contaboserver.net"
  }
  option {
    name = "4vCPU, 8GB RAM"
    value = "vmi261078.contaboserver.net"
  }
}
data "coder_parameter" "disk_size" {
  name        = "PVC storage size"
  type        = "number"
  description = "Number of GB of storage"
  icon        = "https://www.pngall.com/wp-content/uploads/5/Database-Storage-PNG-Clipart.png"
  validation {
    min       = 10
    max       = 50
    monotonic = "increasing"
  }
  mutable     = true
  default     = 10
}
data "coder_parameter" "image" {
  name         = "container_image"
  display_name = "Container Image"
  description = "What container image and language do you want?"
  default      = "sharp6292/coder-base:latest"
  type         = "string"
  mutable      = true
  icon        = "https://www.docker.com/wp-content/uploads/2022/03/vertical-logo-monochromatic.png"
}
data "coder_parameter" "dotfiles_uri" {
  name         = "dotfiles_uri"
  display_name = "dotfiles URI"
  description  = <<-EOF
  Dotfiles repo URI (optional)

  see https://dotfiles.github.io
  EOF
  default      = "https://github.com/Sharpz7/dotfiles"
  type         = "string"
  mutable      = true
}
data "coder_parameter" "jupyter" {
  name        = "Jupyter IDE type"
  type        = "string"
  description = "What type of Jupyter do you want?"
  mutable     = true
  default     = "lab"
  icon        = "/icon/jupyter.svg"

  option {
    name = "Jupyter Lab"
    value = "lab"
    icon = "https://raw.githubusercontent.com/gist/egormkn/672764e7ce3bdaf549b62a5e70eece79/raw/559e34c690ea4765001d4ba0e715106edea7439f/jupyter-lab.svg"
  }
  option {
    name = "Jupyter Notebook"
    value = "notebook"
    icon = "https://codingbootcamps.io/wp-content/uploads/jupyter_notebook.png"
  }
}

# Applications
# ================================
resource "coder_app" "code-server" {
  agent_id     = coder_agent.main.id
  slug         = "code-server"
  display_name = "code-server"
  icon         = "/icon/code.svg"
  url          = "http://localhost:13337?folder=/home/coder/projects"
  subdomain    = true
  share        = "owner"

  healthcheck {
    url       = "http://localhost:13337/healthz"
    interval  = 3
    threshold = 10
  }
}
resource "coder_app" "jupyter" {
  agent_id     = coder_agent.main.id
  slug          = "j"
  display_name  = "jupyter ${data.coder_parameter.jupyter.value}"
  icon          = "/icon/jupyter.svg"
  url           = "http://localhost:8888/"
  share         = "owner"
  subdomain     = true

  healthcheck {
    url       = "http://localhost:8888/healthz/"
    interval  = 10
    threshold = 20
  }
}
resource "coder_app" "filebrowser" {
  agent_id     = coder_agent.main.id
  display_name = "File Browser"
  slug         = "filebrowser"
  icon         = "https://raw.githubusercontent.com/matifali/logos/main/database.svg"
  url          = "http://localhost:8070"
  subdomain    = true
  share        = "owner"
}


# Agent Setup
# =================================================
resource "coder_agent" "main" {
  os             = "linux"
  arch           = "amd64"
  startup_script = <<EOT
    set -e
    # start jupyter
    jupyter ${data.coder_parameter.jupyter.value} --${local.jupyter-type-arg}App.token="" --ip="*" >/tmp/jupyter.log 2>&1 &

    # Create user data directory
    mkdir -p ~/data
    mkdir -p ~/projects

    # Install and start filebrowser
    curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    filebrowser --port 8070 --noauth --root /home/coder/data >/tmp/filebrowser.log 2>&1 &

    curl -fsSL https://code-server.dev/install.sh | sh -s -- --version 4.16.1 | tee code-server-install.log
    sleep 5

    if [ -n "$DOTFILES_URI" ]; then
      echo "Installing dotfiles from $DOTFILES_URI"
      coder dotfiles -y "$DOTFILES_URI"
    fi

    code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
  EOT

  dir = "/home/coder/"


  env = {
    GIT_AUTHOR_NAME     = "${data.coder_workspace.me.owner}"
    GIT_COMMITTER_NAME  = "${data.coder_workspace.me.owner}"
    GIT_AUTHOR_EMAIL    = "${data.coder_workspace.me.owner_email}"
    GIT_COMMITTER_EMAIL = "${data.coder_workspace.me.owner_email}"
    DOTFILES_URI        = data.coder_parameter.dotfiles_uri.value != "" ? data.coder_parameter.dotfiles_uri.value : null
  }

  metadata {
    display_name = "CPU Usage Workspace"
    interval     = 10
    key          = "0_cpu_usage"
    script       = "coder stat cpu"
  }

  metadata {
    display_name = "CPU Usage Host"
    interval     = 10
    key          = "2_cpu_usage"
    script       = "coder stat cpu --host"
  }

  metadata {
    display_name = "RAM Usage Host"
    interval     = 10
    key          = "3_ram_usage"
    script       = "coder stat mem --host"
  }

  metadata {
    display_name = "Disk Usage"
    interval     = 600
    key          = "6_disk_usage"
    script       = "coder stat disk $HOME"
  }
}

# Pod Setup
# =================================================
resource "kubernetes_pod" "main" {
  count = data.coder_workspace.me.start_count

  metadata {
    name      = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
    namespace = local.namespace
  }

  spec {
    restart_policy = "Never"

    container {
      name              = "dev"
      image             = "ghcr.io/coder/envbox:latest"
      image_pull_policy = "Always"
      command           = ["/envbox", "docker"]

      security_context {
        privileged = true
      }

      resources {
        requests = {
          "cpu"    = "1"
          "memory" = "1Gi"
        }
        limits = {
          "cpu"    = "${local.node_resources[data.coder_parameter.node.value]["cpu"]}"
          "memory" = "${local.node_resources[data.coder_parameter.node.value]["memory"]}Gi"
        }
      }

      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }

      env {
        name  = "CODER_AGENT_URL"
        value = data.coder_workspace.me.access_url
      }

      env {
        name  = "CODER_INNER_IMAGE"
        value = "sharp6292/coder-base:latest"
      }

      env {
        name  = "CODER_INNER_USERNAME"
        value = "coder"
      }

      env {
        name  = "CODER_BOOTSTRAP_SCRIPT"
        value = coder_agent.main.init_script
      }

      env {
        name  = "CODER_MOUNTS"
        value = "/home/coder:/home/coder"
      }

      env {
        name  = "CODER_ADD_FUSE"
        value = var.create_fuse
      }

      env {
        name  = "CODER_INNER_HOSTNAME"
        value = data.coder_workspace.me.name
      }

      env {
        name  = "CODER_ADD_TUN"
        value = var.create_tun
      }

      env {
        name = "CODER_CPUS"
        value_from {
          resource_field_ref {
            resource = "limits.cpu"
          }
        }
      }

      env {
        name = "CODER_MEMORY"
        value_from {
          resource_field_ref {
            resource = "limits.memory"
          }
        }
      }

      volume_mount {
        mount_path = "/home/coder"
        name       = "home"
        read_only  = false
        sub_path   = "home"
      }

      volume_mount {
        mount_path = "/var/lib/coder/docker"
        name       = "home"
        sub_path   = "cache/docker"
      }

      volume_mount {
        mount_path = "/var/lib/coder/containers"
        name       = "home"
        sub_path   = "cache/containers"
      }

      volume_mount {
        mount_path = "/var/lib/sysbox"
        name       = "sysbox"
      }

      volume_mount {
        mount_path = "/var/lib/containers"
        name       = "home"
        sub_path   = "envbox/containers"
      }

      volume_mount {
        mount_path = "/var/lib/docker"
        name       = "home"
        sub_path   = "envbox/docker"
      }

      volume_mount {
        mount_path = "/usr/src"
        name       = "usr-src"
      }

      volume_mount {
        mount_path = "/lib/modules"
        name       = "lib-modules"
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
      name = "sysbox"
      empty_dir {}
    }

    volume {
      name = "usr-src"
      host_path {
        path = "/usr/src"
        type = ""
      }
    }

    volume {
      name = "lib-modules"
      host_path {
        path = "/lib/modules"
        type = ""
      }
    }
  }
}
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
    annotations = {
      "com.coder.user.email" = data.coder_workspace.me.owner_email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.disk_size.value}Gi"
      }
    }
  }

  lifecycle {
    ignore_changes = all
  }
}


# Empties
# ===================================
data "coder_workspace" "me" {}