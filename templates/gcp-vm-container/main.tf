terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "~> 0.7.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.25.0"
    }
  }
}

provider "coder" {
}

variable "project_id" {
  description = "Which Google Compute Project should your workspace live in?"
}

provider "google" {
  zone    = "us-central1-a"
  project = var.project_id
}

data "google_compute_default_service_account" "default" {
}

data "coder_workspace" "me" {
}

resource "coder_agent" "main" {
  auth = "google-instance-identity"
  arch = "amd64"
  os   = "linux"

  startup_script_timeout = 180
  startup_script         = <<-EOT
    set -e

    # install and start code-server
    curl -fsSL https://code-server.dev/install.sh | sh -s -- --method=standalone --prefix=/tmp/code-server --version 4.11.0
    /tmp/code-server/bin/code-server --auth none --port 13337 >/tmp/code-server.log 2>&1 &
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

module "gce-container" {
  source  = "terraform-google-modules/container-vm/google"
  version = "3.0.0"

  container = {
    image   = "codercom/enterprise-base:ubuntu"
    command = ["sh"]
    args    = ["-c", coder_agent.main.init_script]
    securityContext = {
      privileged : true
    }
  }
}

resource "google_compute_instance" "dev" {
  zone         = "us-central1-a"
  count        = data.coder_workspace.me.start_count
  name         = "coder-${lower(data.coder_workspace.me.owner)}-${lower(data.coder_workspace.me.name)}"
  machine_type = "n1-standard-4"

  scheduling {
    automatic_restart   = false
    on_host_maintenance = "TERMINATE"
    preemptible         = true
    provisioning_model  = "SPOT"
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }

  boot_disk {
    initialize_params {
      image = module.gce-container.source_image
    }
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    "gce-container-declaration" = module.gce-container.metadata_value
  }
  labels = {
    container-vm = module.gce-container.vm_container_label
  }
}


resource "coder_agent_instance" "dev" {
  count       = data.coder_workspace.me.start_count
  agent_id    = coder_agent.main.id
  instance_id = google_compute_instance.dev[0].instance_id
}

resource "coder_metadata" "workspace_info" {
  count       = data.coder_workspace.me.start_count
  resource_id = google_compute_instance.dev[0].id

  item {
    key   = "image"
    value = module.gce-container.container.image
  }
}