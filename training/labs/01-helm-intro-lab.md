# 01 – Helm Fundamentals (Lab)

**Objective:** Explore Helm commands hands-on, search for charts, and inspect chart contents without installing anything.

**Estimated duration:** 20–25 minutes

**Prerequisites:** Completed environment setup; Minikube running; Helm installed.

---

## What You Will Practice

In this lab, you will:
- Run basic Helm commands to understand the tool
- Search for charts in public repositories
- Inspect a chart's documentation and default values
- Preview what a chart would create (without actually installing)

---

## Lab Workflow Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAB 01 WORKFLOW                               │
└─────────────────────────────────────────────────────────────────┘

    Step 1              Step 2              Step 3              Step 4
    ──────              ──────              ──────              ──────
┌───────────┐      ┌───────────┐      ┌───────────┐      ┌───────────┐
│  Verify   │      │  Explore  │      │   Add     │      │  Search   │
│   Helm    │ ───▶ │   Help    │ ───▶ │   Repo    │ ───▶ │  Charts   │
│ Installed │      │  System   │      │           │      │           │
└───────────┘      └───────────┘      └───────────┘      └───────────┘
     │                   │                  │                  │
     ▼                   ▼                  ▼                  ▼
  helm version      helm help         helm repo add       helm search
  helm env          helm <cmd> -h     helm repo update    helm show


    Step 5              Step 6              Step 7              Step 8
    ──────              ──────              ──────              ──────
┌───────────┐      ┌───────────┐      ┌───────────┐      ┌───────────┐
│ Inspect   │      │  View     │      │  View     │      │  Preview  │
│  Chart    │ ───▶ │  README   │ ───▶ │  Values   │ ───▶ │  Template │
│  Info     │      │           │      │           │      │           │
└───────────┘      └───────────┘      └───────────┘      └───────────┘
     │                   │                  │                  │
     ▼                   ▼                  ▼                  ▼
  helm show chart   helm show readme   helm show values   helm template
```

---

## Step-by-Step Instructions

### Step 1: Verify Helm is Working

First, let's confirm Helm is installed and see what version we have.

**Run this command:**
```bash
helm version
```

**What you should see:**
```
version.BuildInfo{Version:"v3.13.0", GitCommit:"...", GitTreeState:"clean", GoVersion:"go1.21.0"}
```

**What this means:**
- `Version:"v3.13.0"` – You have Helm 3 (the current major version). Any v3.x is good.
- The other fields show build details that you can ignore.

**For a shorter output:**
```bash
helm version --short
```

Output: `v3.13.0+g...`

---

### Step 2: Explore Helm's Help System

Helm has built-in documentation for every command.

```
┌─────────────────────────────────────────────────────────────────┐
│                    HELM HELP HIERARCHY                           │
└─────────────────────────────────────────────────────────────────┘

                        helm help
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
      helm install      helm repo       helm create
        --help           --help           --help
            │                │                │
            ▼                ▼                ▼
    [detailed usage]  [repo subcommands]  [create usage]
                        ├─ helm repo add
                        ├─ helm repo list
                        ├─ helm repo update
                        └─ helm repo remove
```

**See all available commands:**
```bash
helm help
```

**What you'll see:**
A list of command groups:
- `completion` – Shell auto-completion
- `create` – Create a new chart
- `install` – Install a chart
- `list` – List releases
- `repo` – Manage repositories
- ...and many more

**Get help for a specific command:**
```bash
helm help install
```

**What you'll see:**
Detailed documentation for the `install` command, including all flags and examples.

**Why this matters:**
You don't need to memorize every flag. Use `helm help <command>` whenever you forget.

---

### Step 3: Search for Charts on Artifact Hub

Artifact Hub is a public website that indexes thousands of Helm charts.

**Search for nginx charts:**
```bash
helm search hub nginx
```

**What you should see:**
```
URL                                                   CHART VERSION   APP VERSION   DESCRIPTION
https://artifacthub.io/packages/helm/bitnami/nginx    15.0.0          1.25.0        NGINX Open Source is a...
https://artifacthub.io/packages/helm/nginx/nginx      0.14.0          1.5.0         An NGINX HTTP server...
... (many more results)
```

**Understanding the output:**
- **URL** – Link to the chart's page on Artifact Hub
- **CHART VERSION** – Version of the Helm chart (packaging version)
- **APP VERSION** – Version of the actual software (nginx itself)
- **DESCRIPTION** – Brief description

**Note:** This searches the public hub, not charts you've downloaded locally.

---

### Step 4: Add a Repository

To install charts, you first add their repository to Helm.

**Add the Bitnami repository:**
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

**What this command does:**
- `helm repo add` – "I want to add a new chart source"
- `bitnami` – Local nickname for this repo (you can call it anything)
- `https://charts.bitnami.com/bitnami` – URL where charts are hosted

**Expected output:**
```
"bitnami" has been added to your repositories
```

**Update the repository index:**
```bash
helm repo update
```

**What this does:**
Downloads the latest list of available charts from all your repos. Like refreshing an app store.

**Expected output:**
```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

---

### Step 5: Search Your Added Repositories

Now search within the repos you've added (not the public hub).

**Search for nginx in your repos:**
```bash
helm search repo nginx
```

**What you should see:**
```
NAME                    CHART VERSION   APP VERSION   DESCRIPTION
bitnami/nginx           15.0.0          1.25.0        NGINX Open Source is a web server...
bitnami/nginx-ingress   9.0.0           1.8.0         NGINX Ingress Controller is...
```

**Difference from `helm search hub`:**
- `helm search hub` – Searches the entire public hub (internet)
- `helm search repo` – Searches only repos you've added locally (faster, works offline after update)

---

### Step 6: Inspect a Chart's README

Before installing a chart, you should read its documentation.

**Show the README for bitnami/nginx:**
```bash
helm show readme bitnami/nginx
```

**What you'll see:**
The full README file, which typically includes:
- Description of what the chart installs
- Prerequisites
- Installation commands
- Configuration options
- Troubleshooting tips

**To see just the first part:**
```bash
helm show readme bitnami/nginx | head -n 50
```

This shows the first 50 lines, which usually covers the introduction.

---

### Step 7: View a Chart's Default Values

Every chart has a `values.yaml` with default settings. You can customize these.

**Show default values:**
```bash
helm show values bitnami/nginx | head -n 40
```

**What you'll see:**
```yaml
## @section Global parameters
global:
  imageRegistry: ""
  imagePullSecrets: []
  storageClass: ""

## @section Common parameters
nameOverride: ""
fullnameOverride: ""

## @section NGINX parameters
image:
  registry: docker.io
  repository: bitnami/nginx
  tag: 1.25.0-debian-11-r0
...
```

**Understanding this:**
- Each line is a setting you can override
- Comments (lines starting with `#` or `##`) explain each setting
- Nested values use indentation (like `image.tag`)

---

### Step 8: View Chart Metadata

**Show chart metadata:**
```bash
helm show chart bitnami/nginx
```

**What you'll see:**
```yaml
annotations:
  category: Infrastructure
apiVersion: v2
appVersion: 1.25.0
description: NGINX Open Source is a web server...
home: https://nginx.org
icon: https://...
keywords:
- nginx
- http
- web
maintainers:
- name: Bitnami
name: nginx
version: 15.0.0
```

**Key fields:**
- `name` – Chart name
- `version` – Chart version (the package)
- `appVersion` – Version of the software inside (nginx 1.25.0)
- `description` – What it does
- `maintainers` – Who maintains it

---

### Step 9: Preview What Would Be Installed (Dry Run)

You can see exactly what Kubernetes resources a chart would create without actually installing.

**Render templates locally:**
```bash
helm template my-nginx bitnami/nginx | head -n 60
```

**What this command does:**
- `helm template` – "Show me the rendered YAML"
- `my-nginx` – The release name (what you'd call this installation)
- `bitnami/nginx` – The chart to render

**What you'll see:**
Actual Kubernetes YAML files with all placeholders filled in:
```yaml
---
# Source: nginx/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
  labels:
    app.kubernetes.io/name: nginx
    ...
```

**Why this is useful:**
- You can review exactly what will be created
- Catch configuration mistakes before installing
- Save the output to a file for auditing: `helm template my-nginx bitnami/nginx > rendered.yaml`

---

### Step 10: Check Your Repository List

**List all configured repositories:**
```bash
helm repo list
```

**Expected output:**
```
NAME      URL
bitnami   https://charts.bitnami.com/bitnami
```

**Check Helm environment:**
```bash
helm env | head -n 5
```

**What you'll see:**
```
HELM_CACHE_HOME="/Users/you/.cache/helm"
HELM_CONFIG_HOME="/Users/you/.config/helm"
HELM_DATA_HOME="/Users/you/.local/share/helm"
...
```

These are the directories where Helm stores cached charts and configuration.

---

## Expected Results Summary

After this lab, you should have:

| Task | Command | Result |
|------|---------|--------|
| Helm version confirmed | `helm version --short` | v3.x displayed |
| Hub search works | `helm search hub nginx` | Multiple results |
| Repo added | `helm repo list` | Shows "bitnami" |
| Can view README | `helm show readme bitnami/nginx` | Documentation displayed |
| Can view values | `helm show values bitnami/nginx` | YAML values displayed |
| Can render templates | `helm template my-nginx bitnami/nginx` | Kubernetes YAML displayed |

---

## Troubleshooting

### Problem: "helm search hub" returns nothing

**Possible causes:**
- No internet connection
- Artifact Hub might be temporarily unavailable

**Solution:**
Try again in a minute, or use `helm search repo` after adding a repo.

---

### Problem: "Error: repo bitnami not found"

**Cause:** You haven't added the bitnami repo yet.

**Solution:**
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

---

### Problem: "helm show values" shows nothing useful

**Cause:** Chart name might be wrong.

**Solution:**
First search for the correct name:
```bash
helm search repo nginx
```
Use the exact name from the NAME column.

---

## Optional Challenges

If you finish early, try these:

1. **Find a PostgreSQL chart:**
   ```bash
   helm search hub postgresql
   helm search repo postgresql  # after adding bitnami repo
   ```

2. **Compare two charts:**
   ```bash
   helm show chart bitnami/nginx
   helm show chart bitnami/postgresql
   ```
   Notice the different app versions and descriptions.

3. **Save rendered output to a file:**
   ```bash
   helm template my-app bitnami/nginx > my-app-rendered.yaml
   cat my-app-rendered.yaml | head -n 100
   ```

4. **Render with custom values:**
   ```bash
   helm template my-nginx bitnami/nginx --set replicaCount=3 | grep "replicas:"
   ```
   You should see `replicas: 3` in the output.

---

## Key Takeaways

- `helm search hub` finds charts on the public internet
- `helm search repo` finds charts in repos you've added locally
- `helm show readme/values/chart` lets you inspect before installing
- `helm template` renders YAML so you can preview what will be created
- Always read the README and check values before installing a new chart

---

**✅ Lab complete! You've explored Helm without installing anything. Next, we'll actually install a chart!**
