# 01 – Helm Fundamentals (Theory) 09:00–10:00

**Learning objectives:**
- Define Helm, chart, release, repository in plain terms
- Recognize chart folder structure at a high level
- Understand how Helm compares to package managers you already know

---

## What is Helm? (The Big Picture)

Imagine you want to install a web server on your laptop. On macOS, you might type `brew install nginx`. On Ubuntu, you'd use `apt install nginx`. These package managers handle downloading the software, putting files in the right places, and configuring defaults.

**Helm does the same thing, but for Kubernetes.**

Without Helm, installing an application in Kubernetes means writing many YAML files by hand:
- A Deployment file (tells Kubernetes how to run your app)
- A Service file (lets other apps or users reach your app)
- A ConfigMap file (configuration settings)
- A Secret file (passwords, API keys)
- Maybe an Ingress file (expose to the internet)

For a simple app, that's 5+ files with 200+ lines of YAML. For a database like PostgreSQL, it could be 500+ lines. Copying and editing all that by hand is slow and error-prone.

**Helm solves this with "charts"—pre-made packages that bundle all those files together.**

---

## Key Terms Explained Simply

### Chart
A **chart** is a folder containing templates and default values. It's like an installer package.

**Real-world analogy:** A chart is like a recipe. It has ingredients (values) and instructions (templates). You can follow the recipe exactly, or adjust the ingredients to your taste.

**Example:** The `bitnami/nginx` chart contains everything needed to run nginx in Kubernetes—Deployment, Service, ConfigMap, and more. Someone else wrote it; you just install it.

---

### Release
A **release** is what you get when you install a chart into your cluster. It's a running instance with a name you choose.

**Real-world analogy:** If a chart is a recipe, a release is the actual cake you baked. You can bake the same recipe multiple times and give each cake a different name.

**Example:** You install `bitnami/nginx` twice:
- First release named `web-frontend` (serves your website)
- Second release named `api-docs` (serves documentation)

Same chart, two separate releases, running independently.

---

### Repository
A **repository** (or "repo") is a server that stores charts. You add repos to Helm, then search and install charts from them.

**Real-world analogy:** A repo is like an app store. Apple's App Store is a repo. Google Play is another repo. Each has different apps (charts) available.

**Example repos:**
- `https://charts.bitnami.com/bitnami` – Thousands of production-ready charts
- `https://prometheus-community.github.io/helm-charts` – Monitoring tools
- Your company might have a private repo for internal apps

---

### Values
**Values** are the settings you can customize when installing a chart. They're stored in a file called `values.yaml`.

**Real-world analogy:** Values are like the options when ordering a pizza—size, toppings, crust type. The pizza shop (chart) has defaults, but you can customize.

**Example values in an nginx chart:**
```yaml
replicaCount: 2          # Run 2 copies for reliability
image:
  repository: nginx      # Which container image to use
  tag: "1.25"           # Which version
service:
  type: NodePort        # How to expose the service
  port: 80              # Which port to listen on
```

---

## How Helm Works (Step by Step)

Here's what happens when you run `helm install my-nginx bitnami/nginx`:

```
┌─────────────────────────────────────────────────────────────────┐
│ Step 1: Helm downloads the chart from the repository            │
│         (bitnami/nginx → your local cache)                      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 2: Helm reads values.yaml (defaults) and any overrides     │
│         you provided (like --set replicaCount=3)                │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 3: Helm "renders" templates—fills in placeholders with     │
│         actual values, producing final YAML files               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 4: Helm sends those YAML files to Kubernetes               │
│         (just like running kubectl apply)                       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ Step 5: Kubernetes creates the resources (pods, services, etc.) │
│         Helm saves a record called a "release"                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## What's Inside a Chart Folder?

When you create or download a chart, you get a folder like this:

```
my-chart/
├── Chart.yaml          # Metadata: name, version, description
├── values.yaml         # Default configuration values
├── templates/          # YAML templates with placeholders
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── _helpers.tpl    # Reusable template snippets
│   └── NOTES.txt       # Message shown after install
└── charts/             # Dependencies (other charts this one needs)
```

**Let's look at each file:**

### Chart.yaml
Contains metadata about the chart:
```yaml
apiVersion: v2
name: my-chart
description: A simple web application
version: 1.0.0        # Chart version (your packaging version)
appVersion: "1.25"    # App version (the software inside)
```

### values.yaml
Default values that users can override:
```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 100m
    memory: 128Mi
```

### templates/deployment.yaml (simplified example)
A template with placeholders (the `{{ }}` parts):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
  template:
    spec:
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

When Helm renders this with `replicaCount: 2` and `image.tag: "1.25"`, it becomes:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx-app
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: app
          image: "nginx:1.25"
```

---

## Why Use Helm Instead of Plain YAML?

| Without Helm | With Helm |
|--------------|-----------|
| Copy-paste YAML between projects | Reuse charts from repos |
| Edit 10 files to change one setting | Change one value, re-render |
| No history of what you deployed | Helm tracks every release and revision |
| Deleting means finding all related resources | `helm uninstall` removes everything |
| Upgrades are manual and risky | `helm upgrade` handles it; rollback if needed |

---

## Essential Commands Overview

| Command | What it does | Example |
|---------|--------------|---------|
| `helm help` | Shows all commands | `helm help` |
| `helm version` | Shows Helm version | `helm version --short` |
| `helm search hub <term>` | Searches Artifact Hub (public) | `helm search hub nginx` |
| `helm search repo <term>` | Searches your added repos | `helm search repo nginx` |
| `helm show readme <chart>` | Displays chart documentation | `helm show readme bitnami/nginx` |
| `helm show values <chart>` | Shows default values | `helm show values bitnami/nginx` |

---

## Walkthrough Example: Exploring an nginx Chart

Let's walk through discovering and inspecting a chart:

**1. Search for nginx charts on the public hub:**
```bash
helm search hub nginx
```
This queries Artifact Hub and returns dozens of nginx charts from different publishers.

**2. Add a trusted repository:**
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```
Now you can search within Bitnami's catalog.

**3. Search the local repo:**
```bash
helm search repo nginx
```
Output:
```
NAME                    CHART VERSION   APP VERSION   DESCRIPTION
bitnami/nginx           15.0.0          1.25.0        NGINX is a high-performance...
bitnami/nginx-ingress   9.0.0           1.8.0         NGINX Ingress Controller...
```

**4. Read the chart's README:**
```bash
helm show readme bitnami/nginx | head -n 50
```
This shows installation instructions, configuration options, and examples.

**5. View default values:**
```bash
helm show values bitnami/nginx | head -n 30
```
This shows what you can customize when installing.

---

## Review Questions

Test your understanding:

1. **What is the difference between a chart and a release?**
   - A chart is the package/template; a release is an installed instance of that chart with a specific name.

2. **Where do charts come from?**
   - Charts are stored in repositories. You add repos with `helm repo add`, then search and install from them.

3. **Why use Helm instead of writing YAML by hand?**
   - Reusability, easier configuration, version tracking, simple upgrades and rollbacks, one-command uninstall.

4. **What file contains the default configuration for a chart?**
   - `values.yaml`

5. **What command shows what a chart would install without actually installing it?**
   - `helm template <chart>` or `helm install <release> <chart> --dry-run`

---

**✅ You now understand the core concepts of Helm. Next, we'll actually install and use it!**
