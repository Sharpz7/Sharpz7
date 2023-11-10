---
name: Develop in Linux on Google Cloud (GPU)
description: Get started with Linux development on Google Cloud.
tags: [cloud, google]
icon: /icon/gcp.png
---

## Giving Permissions

Exec into K8s Pod and run code from https://cloud.google.com/sdk/docs/install#linux

```bash
apk add python3
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-444.0.0-linux-x86_64.tar.gz
tar -xf google-cloud-cli-444.0.0-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

# Login and Back.
gcloud auth application-default login
```

## Install GPU Drivers

```bash
curl https://raw.githubusercontent.com/GoogleCloudPlatform/compute-gpu-installation/main/linux/install_gpu_driver.py --output install_gpu_driver.py

sudo spython3 install_gpu_driver.py
```
