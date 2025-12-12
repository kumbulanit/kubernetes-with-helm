# 00 – Environment Setup (08:30–09:00)

**Objective:** Validate kubectl, Minikube, and Helm installations; confirm cluster is ready for labs.

**Estimated duration:** 20–30 minutes

**Prerequisites:** Internet access; Docker or other container runtime installed.

---

## Environment Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         YOUR LAPTOP                                      │
│                                                                          │
│  ┌───────────────┐    ┌───────────────┐    ┌───────────────┐            │
│  │    kubectl    │    │     Helm      │    │    Docker     │            │
│  │  (K8s CLI)    │    │  (Package Mgr)│    │   Engine      │            │
│  └───────┬───────┘    └───────┬───────┘    └───────┬───────┘            │
│          │                    │                    │                    │
│          └────────────────────┼────────────────────┘                    │
│                               │                                          │
│                               ▼                                          │
│          ┌────────────────────────────────────────────┐                 │
│          │                 MINIKUBE                    │                 │
│          │         (Local Kubernetes Cluster)         │                 │
│          │                                            │                 │
│          │   ┌─────────┐  ┌─────────┐  ┌─────────┐   │                 │
│          │   │  Pods   │  │Services │  │ConfigMap│   │                 │
│          │   └─────────┘  └─────────┘  └─────────┘   │                 │
│          │                                            │                 │
│          └────────────────────────────────────────────┘                 │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## What You Will Learn

Before we can use Helm, we need three tools installed and working together:

1. **kubectl** – The command-line tool that talks to Kubernetes clusters. Think of it as the remote control for your cluster.
2. **Minikube** – A tool that creates a mini Kubernetes cluster on your laptop. It's perfect for learning because you don't need expensive cloud servers.
3. **Helm** – The package manager we'll use all day. It installs apps into Kubernetes using "charts" (pre-made templates).

---

## Operating System Installation Guide

This section covers installation for **Ubuntu 24.04 LTS** (primary), **macOS**, and **Windows**.

---

## 🐧 Ubuntu 24.04 LTS Installation (PRIMARY)

Ubuntu 24.04 LTS (Noble Numbat) is our primary training platform. Follow these steps carefully.

### Step 1: Install Docker on Ubuntu 24.04

**Update your system first:**

```bash
sudo apt update && sudo apt upgrade -y
```

**Install required packages:**

```bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release
```

**Add Docker's official GPG key:**

```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

**Add the Docker repository for Ubuntu 24.04:**

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

**Install Docker:**

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

**Add your user to the docker group (so you don't need sudo):**

```bash
sudo usermod -aG docker $USER
```

**Important: Log out and log back in for group changes to take effect!**

```bash
# Or use this to apply changes in current session:
newgrp docker
```

**Verify Docker installation:**

```bash
docker --version
docker run hello-world
```

**Expected output:**
```
Docker version 24.0.x, build ...
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

---

### Step 2: Install kubectl on Ubuntu 24.04

**Download the latest stable kubectl:**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
```

**Validate the binary (optional but recommended):**

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
```

**Install kubectl:**

```bash
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

**Verify installation:**

```bash
kubectl version --client
```

**Expected output:**
```
Client Version: v1.31.x
Kustomize Version: v5.x.x
```

**Alternative: Using apt repository:**

```bash
# Add Kubernetes apt repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubectl
sudo apt update
sudo apt install -y kubectl
```

---

### Step 3: Install Minikube on Ubuntu 24.04

**Download the latest Minikube:**

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
```

**Install Minikube:**

```bash
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**Verify installation:**

```bash
minikube version
```

**Expected output:**
```
minikube version: v1.34.0
commit: ...
```

**Start Minikube with Docker driver:**

```bash
minikube start --driver=docker
```

**Expected output:**
```
😄  minikube v1.34.0 on Ubuntu 24.04
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=3900MB) ...
🐳  Preparing Kubernetes v1.31.0 on Docker 27.2.0 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

**Set Docker as the default driver:**

```bash
minikube config set driver docker
```

---

### Step 4: Install Helm on Ubuntu 24.04

**Method 1: Using the official install script (recommended):**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Method 2: Using Snap:**

```bash
sudo snap install helm --classic
```

**Method 3: Using apt repository:**

```bash
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm
```

**Verify Helm installation:**

```bash
helm version
```

**Expected output:**
```
version.BuildInfo{Version:"v3.16.x", GitCommit:"...", GitTreeState:"clean", GoVersion:"go1.22.x"}
```

---

## 🍎 macOS Installation

### Install with Homebrew (Recommended)

**Install Homebrew if not already installed:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Install Docker Desktop:**

Download from https://www.docker.com/products/docker-desktop/

Or use Homebrew:
```bash
brew install --cask docker
```

Then open Docker Desktop from Applications and wait for it to start.

**Install kubectl:**

```bash
brew install kubectl
```

**Verify:**
```bash
kubectl version --client
```

**Install Minikube:**

```bash
brew install minikube
```

**Start Minikube:**
```bash
minikube start --driver=docker
```

**Install Helm:**

```bash
brew install helm
```

**Verify:**
```bash
helm version --short
```

---

## 🪟 Windows Installation

### Prerequisites
- Windows 10/11 (64-bit) with virtualization enabled in BIOS
- Administrator access

### Install with Chocolatey (Recommended)

**Install Chocolatey (open PowerShell as Administrator):**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Install Docker Desktop:**

```powershell
choco install docker-desktop -y
```

Restart your computer after installation, then open Docker Desktop.

**Install kubectl:**

```powershell
choco install kubernetes-cli -y
```

**Verify:**
```powershell
kubectl version --client
```

**Install Minikube:**

```powershell
choco install minikube -y
```

**Start Minikube:**
```powershell
minikube start --driver=docker
```

**Install Helm:**

```powershell
choco install kubernetes-helm -y
```

**Verify:**
```powershell
helm version --short
```

### Alternative: Using winget (Windows 11)

```powershell
winget install Docker.DockerDesktop
winget install Kubernetes.kubectl
winget install Kubernetes.minikube
winget install Helm.Helm
```

---

## Universal Post-Installation Steps (All Operating Systems)

### Verify Your Complete Setup

Run these commands on any OS to verify everything is working:

**Check kubectl:**
```bash
kubectl version --client
```

**Check your contexts:**

```bash
kubectl config get-contexts
```

**What this shows:**
A "context" is a saved connection to a cluster. You might see nothing yet (that's okay—Minikube will create one), or you might see existing contexts from previous work.

**Check Minikube status:**
```bash
minikube status
```

**Expected output:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

**Verify kubectl can talk to the cluster:**

```bash
kubectl get nodes
```

**Expected output:**
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.31.0
```

**Check Helm:**
```bash
helm version --short
```

**Expected output:**
```
v3.16.x+g...
```

**Explore Helm's help:**

```bash
helm help
```

This shows all available commands. Don't worry about memorizing them—we'll learn the important ones throughout the day.

---

### Step 4: Test DNS and Networking Inside the Cluster

**Why test this?**
Kubernetes apps need to find each other by name (like "my-database" or "my-api"). This uses internal DNS. If DNS is broken, nothing works properly.

**Run a quick DNS test:**

```bash
kubectl run dns-test --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default
```

**Breaking down this command:**
- `kubectl run dns-test` = "Create a pod named dns-test"
- `--image=busybox:1.36` = "Use the busybox image (a tiny Linux with basic tools)"
- `--restart=Never` = "Don't restart if it exits (one-time test)"
- `-- nslookup kubernetes.default` = "Run this command inside the pod"

**Wait a few seconds, then check the result:**

```bash
kubectl logs dns-test
```

**Expected output:**
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

This means DNS is working! The pod successfully looked up "kubernetes.default".

**Clean up the test pod:**

```bash
kubectl delete pod dns-test
```

---

## Expected Results Summary

After completing this setup, you should have:

| Check | Command | Expected |
|-------|---------|----------|
| kubectl installed | `kubectl version --client` | Shows version v1.2x+ |
| Minikube running | `minikube status` | All items "Running" |
| Node ready | `kubectl get nodes` | One node, status "Ready" |
| Helm installed | `helm version --short` | Shows v3.x |
| DNS working | Logs from dns-test pod | Shows resolved addresses |

---

## Troubleshooting Common Problems

### Problem: "minikube start" fails with Docker errors

**Symptoms:**
```
❌  Exiting due to PROVIDER_DOCKER_NOT_RUNNING: docker is not running
```

**Solution:**
1. Open Docker Desktop application
2. Wait for it to say "Docker Desktop is running"
3. Try `minikube start --driver=docker` again

---

### Problem: kubectl cannot connect to cluster

**Symptoms:**
```
The connection to the server localhost:8080 was refused
```

**Solution:**
1. Make sure Minikube is running: `minikube status`
2. If stopped, start it: `minikube start`
3. Set the context: `kubectl config use-context minikube`

---

### Problem: "helm: command not found"

**Solution:**
Helm isn't installed. Run the installer:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Then close and reopen your terminal, or run:
```bash
source ~/.bashrc   # or source ~/.zshrc on macOS
```

---

### Problem: Minikube is very slow or runs out of memory

**Solution:**
Give Minikube more resources:

```bash
minikube stop
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192
```

This allocates 4 CPU cores and 8GB RAM to the cluster.

---

## Additional Validation Commands

These commands help you verify everything is healthy:

**Check Docker is available:**
```bash
docker info | head -n 5
```
Should show Docker version and running status.

**Check Minikube addons:**
```bash
minikube addons list | head -n 10
```
Look for `default-storageclass` and `storage-provisioner` marked as "enabled".

**Check all system pods are running:**
```bash
kubectl get pod -A
```
All pods should show "Running" or "Completed" status.

**Check Helm environment:**
```bash
helm env | head -n 5
```
Shows where Helm stores its cache and configuration.

---

## Setting Up Training Namespaces

To make this tutorial more realistic and organized, we will create several [Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/). A Namespace is a logical unit which we use to organize different environments. Think of namespaces as separate folders on your computer—each one keeps things organized and isolated.

**Why use Namespaces?**
- **Organization**: Keep dev, test, and prod resources separate
- **Security**: Apply different permissions to different namespaces
- **Resource Limits**: Set quotas per namespace
- **Clarity**: Easily see what belongs to what environment

**Create the training namespaces:**

Create a file called `namespaces.yaml`:

```bash
cat << 'EOF' > namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
---
apiVersion: v1
kind: Namespace
metadata:
  name: test
  labels:
    environment: testing
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: production
---
apiVersion: v1
kind: Namespace
metadata:
  name: tools
  labels:
    environment: tooling
EOF
```

**Apply the namespaces:**

```bash
kubectl apply -f namespaces.yaml
```

**Expected output:**
```
namespace/dev created
namespace/test created
namespace/prod created
namespace/tools created
```

**Verify the namespaces were created:**

```bash
kubectl get namespaces
```

**Expected output:**
```
NAME              STATUS   AGE
default           Active   10m
dev               Active   5s
kube-node-lease   Active   10m
kube-public       Active   10m
kube-system       Active   10m
prod              Active   5s
test              Active   5s
tools             Active   5s
```

**Understanding the Namespace Structure:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                            │
│                                                                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│   │   dev    │  │   test   │  │   prod   │  │  tools   │       │
│   │          │  │          │  │          │  │          │       │
│   │  Your    │  │  Testing │  │Production│  │  Helm    │       │
│   │  apps    │  │  before  │  │   apps   │  │  repos,  │       │
│   │  in      │  │  prod    │  │  (live)  │  │monitoring│       │
│   │  dev     │  │          │  │          │  │          │       │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│                                                                  │
│   ┌──────────────┐  ┌──────────────┐                            │
│   │ kube-system  │  │   default    │  ← System namespaces       │
│   │ (K8s core)   │  │ (your work)  │                            │
│   └──────────────┘  └──────────────┘                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

**Deploy to a specific namespace:**

When deploying with Helm, you'll use the `--namespace` flag:

```bash
# Example: Deploy to dev namespace
helm install myapp bitnami/nginx --namespace dev

# Example: Deploy to tools namespace
helm install monitoring prometheus-community/prometheus --namespace tools
```

---

## Installation Summary Table by OS

| Tool | Ubuntu 24.04 | macOS | Windows |
|------|--------------|-------|---------|
| **Docker** | `apt install docker-ce` | Docker Desktop / `brew install --cask docker` | `choco install docker-desktop` |
| **kubectl** | `curl -LO` + `install` or apt | `brew install kubectl` | `choco install kubernetes-cli` |
| **Minikube** | `curl -LO` + `install` | `brew install minikube` | `choco install minikube` |
| **Helm** | Script / snap / apt | `brew install helm` | `choco install kubernetes-helm` |

---

## Optional Challenge

If you finish early, try changing the Minikube driver:

```bash
minikube stop
minikube delete
minikube start --driver=hyperkit  # or --driver=virtualbox
```

Then run `minikube status` to see how the output differs. This teaches you that Minikube can use different virtualization backends.

---

## Quick Reference: Essential Commands

```bash
# Start your environment
minikube start --driver=docker

# Check cluster status
minikube status
kubectl get nodes
kubectl get namespaces

# Stop your environment (saves resources)
minikube stop

# Delete and start fresh
minikube delete
minikube start --driver=docker

# Check tool versions
kubectl version --client
helm version --short
minikube version
```

---

**✅ Environment setup complete! You're ready for Module 1.**
