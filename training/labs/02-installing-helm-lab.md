# 02 – Installing & Using Helm (Lab)

**Objective:** Add a repository, search for charts, install your first release, verify it works, and uninstall cleanly.

**Estimated duration:** 25–30 minutes

**Prerequisites:** Environment setup complete; Minikube running; Helm installed.

---

## What You Will Do

This is your first hands-on experience installing something with Helm. You will:
1. Add a chart repository
2. Search for an nginx chart
3. Preview what it would install
4. Actually install it
5. Verify the pods and services are running
6. Access the running nginx
7. Uninstall and clean up

---

## Lab Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                 HELM INSTALL WORKFLOW                            │
└─────────────────────────────────────────────────────────────────┘

   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
   │  1. Add  │     │2. Update │     │3. Search │     │4. Preview│
   │   Repo   │────▶│   Repo   │────▶│  Charts  │────▶│ Dry-Run  │
   └──────────┘     └──────────┘     └──────────┘     └──────────┘
        │                                                   │
        │           REPOSITORY                              │
        │          ┌─────────┐                              │
        └─────────▶│ Bitnami │◀─────────────────────────────┘
                   │ (nginx) │
                   └────┬────┘
                        │
                        ▼
   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
   │5. Install│     │6. Verify │     │ 7. Test  │     │8. Uninst │
   │  Chart   │────▶│  Pods    │────▶│  Access  │────▶│   all    │
   └──────────┘     └──────────┘     └──────────┘     └──────────┘
        │                │                │
        ▼                ▼                ▼
   ┌─────────────────────────────────────────┐
   │           KUBERNETES CLUSTER            │
   │  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
   │  │   Pod   │  │ Service │  │ConfigMap│ │
   │  │ (nginx) │  │  (80)   │  │         │ │
   │  └─────────┘  └─────────┘  └─────────┘ │
   └─────────────────────────────────────────┘
```

---

## Step-by-Step Instructions

### Step 1: Add the Bitnami Repository

Bitnami maintains high-quality, production-ready Helm charts. Let's add their repository.

**Run this command:**
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

**Breaking down the command:**
- `helm repo add` = "Add a new chart repository"
- `bitnami` = The nickname you'll use to reference this repo
- `https://charts.bitnami.com/bitnami` = The URL where charts are hosted

**Expected output:**
```
"bitnami" has been added to your repositories
```

**What just happened:**
Helm saved the URL and downloaded an index file listing all available charts.

---

### Step 2: Update the Repository Index

Always update after adding a repo to ensure you have the latest chart versions.

**Run this command:**
```bash
helm repo update
```

**Expected output:**
```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

**What this does:**
Downloads the latest index file, which lists all charts and their versions. Run this periodically to get new chart versions.

---

### Step 3: Search for nginx Charts

Now let's find an nginx chart.

**Run this command:**
```bash
helm search repo nginx
```

**Expected output:**
```
NAME                    CHART VERSION   APP VERSION   DESCRIPTION
bitnami/nginx           15.0.0          1.25.0        NGINX Open Source is a web server...
bitnami/nginx-ingress   9.0.0           1.8.0         NGINX Ingress Controller is...
```

**Understanding the columns:**
- **NAME**: Full chart reference (repo/chart) - you'll use this to install
- **CHART VERSION**: Version of the Helm chart package
- **APP VERSION**: Version of nginx inside the chart
- **DESCRIPTION**: What the chart does

---

### Step 4: (Optional) Pull the Chart Locally

Before installing, let's download the chart to inspect it.

**Run these commands:**
```bash
helm pull bitnami/nginx --untar -d /tmp/helm-nginx
ls /tmp/helm-nginx/nginx
```

**Expected output:**
```
Chart.yaml  README.md  charts  templates  values.yaml  values.schema.json
```

**What you downloaded:**
- `Chart.yaml` – Metadata (name, version)
- `values.yaml` – Default configuration
- `templates/` – YAML templates that become Kubernetes resources
- `README.md` – Documentation

**Inspect the default values (first 20 lines):**
```bash
head -n 20 /tmp/helm-nginx/nginx/values.yaml
```

This shows you what settings you can customize.

---

### Step 5: Preview the Installation (Dry Run)

Before installing, preview what Kubernetes resources will be created.

**Run this command:**
```bash
helm install lab-nginx bitnami/nginx --dry-run --debug 2>&1 | head -n 80
```

**Breaking down the command:**
- `helm install` = "Install a chart"
- `lab-nginx` = Your chosen release name
- `bitnami/nginx` = The chart to install
- `--dry-run` = Don't actually install, just show what would happen
- `--debug` = Show extra details (computed values, hooks)
- `2>&1 | head -n 80` = Show first 80 lines of output

**What you'll see:**
- The computed values (defaults merged with any overrides)
- The rendered Kubernetes YAML (Deployment, Service, etc.)
- Hook information

**Why this matters:**
You can catch configuration mistakes BEFORE they affect your cluster.

---

### Step 6: Install the Chart

Now let's actually install nginx into your cluster.

**Run this command:**
```bash
helm install lab-nginx bitnami/nginx
```

**Expected output:**
```
NAME: lab-nginx
LAST DEPLOYED: Thu Jan 15 10:30:00 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: nginx
CHART VERSION: 15.0.0
APP VERSION: 1.25.0

** Please be patient while the chart is being deployed **

NGINX can be accessed through the following DNS name from within your cluster:

    lab-nginx.default.svc.cluster.local (port 80)

To access NGINX from outside the cluster, follow the steps below:

1. Get the NGINX URL by running these commands:
...
```

**What just happened:**
1. Helm downloaded the chart (if not cached)
2. Rendered templates with default values
3. Sent the YAML to Kubernetes
4. Kubernetes created the Deployment, Service, etc.
5. Helm recorded this as "revision 1" of release "lab-nginx"

---

### Step 7: Verify the Release is Listed

**Run this command:**
```bash
helm list
```

**Expected output:**
```
NAME       NAMESPACE   REVISION   UPDATED                   STATUS     CHART          APP VERSION
lab-nginx  default     1          2024-01-15 10:30:00       deployed   nginx-15.0.0   1.25.0
```

**Understanding the columns:**
- **NAME**: Your release name
- **NAMESPACE**: Where it's installed
- **REVISION**: How many times it's been installed/upgraded (1 = first install)
- **STATUS**: Current state (deployed, failed, pending-install, etc.)
- **CHART**: Which chart and version
- **APP VERSION**: The application version (nginx 1.25.0)

---

### Step 8: Check the Release Status

**Run this command:**
```bash
helm status lab-nginx
```

**Expected output:**
Same as the install output, plus updated status information.

**When to use this:**
- Check if a release is healthy
- Re-read the NOTES (often contain access instructions)
- See when it was last updated

---

### Step 9: Verify Kubernetes Resources

Let's check what Kubernetes resources were created.

**Check pods:**
```bash
kubectl get pods
```

**Expected output:**
```
NAME                         READY   STATUS    RESTARTS   AGE
lab-nginx-7d4f8b7b9c-xk2j4   1/1     Running   0          2m
```

**What this shows:**
- One pod is running (STATUS: Running)
- 1/1 containers are ready
- Name includes your release name (`lab-nginx-`)

**Check services:**
```bash
kubectl get svc
```

**Expected output:**
```
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   1h
lab-nginx    ClusterIP   10.96.123.45    <none>        80/TCP    2m
```

**What this shows:**
- A Service named `lab-nginx` was created
- Type is `ClusterIP` (internal only by default)
- Listening on port 80

**Get more details about the service:**
```bash
kubectl describe svc lab-nginx
```

**This shows:**
- Full configuration
- Endpoints (which pod IPs receive traffic)
- Labels and selectors

---

### Step 10: Access the Running nginx

Since the service type is ClusterIP (internal), we need port-forwarding to access it from our laptop.

```
┌─────────────────────────────────────────────────────────────────┐
│                    PORT FORWARDING                               │
└─────────────────────────────────────────────────────────────────┘

   YOUR LAPTOP                         KUBERNETES CLUSTER
   ───────────                         ──────────────────

  ┌───────────┐                       ┌─────────────────┐
  │           │     Port Forward      │   Service       │
  │  Browser  │ ──────────────────────│  lab-nginx      │
  │           │     localhost:8080    │    :80          │
  │           │          ═══════════▶ │                 │
  └───────────┘                       └────────┬────────┘
                                               │
                                               ▼
                                      ┌─────────────────┐
                                      │      Pod        │
                                      │     nginx       │
                                      │   container     │
                                      └─────────────────┘
```

**Run this command:**
```bash
kubectl port-forward svc/lab-nginx 8080:80
```

**Breaking down the command:**
- `kubectl port-forward` = Forward a local port to a cluster resource
- `svc/lab-nginx` = The service to forward to
- `8080:80` = Local port 8080 → Service port 80

**Expected output:**
```
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
```

**Now open a new terminal** (leave port-forward running) **and test:**
```bash
curl http://localhost:8080
```

**Expected output:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```

You're seeing the nginx welcome page served from your Kubernetes cluster!

**Stop port-forward:** Press `Ctrl+C` in the terminal running port-forward.

---

### Step 11: See What Was Installed (Manifests)

**View the actual Kubernetes YAML that was applied:**
```bash
helm get manifest lab-nginx | head -n 50
```

**This shows:**
The exact YAML that Helm sent to Kubernetes. Useful for debugging or auditing.

**View the values that were used:**
```bash
helm get values lab-nginx
```

**Expected output:**
```
USER-SUPPLIED VALUES:
null
```

Since we didn't override any values, it shows null. The chart used all defaults.

---

### Step 12: Uninstall the Release

When you're done, clean up the installation.

**Run this command:**
```bash
helm uninstall lab-nginx
```

**Expected output:**
```
release "lab-nginx" uninstalled
```

**What this does:**
1. Finds all Kubernetes resources created by this release
2. Deletes them (Deployment, Service, etc.)
3. Removes the release record from Helm's history

**Verify it's gone:**
```bash
helm list
kubectl get pods
kubectl get svc
```

The `lab-nginx` release, pod, and service should no longer appear.

---

## Expected Results Summary

| Step | Command | Expected Result |
|------|---------|-----------------|
| Add repo | `helm repo add bitnami ...` | "bitnami" has been added |
| Update repo | `helm repo update` | Update Complete |
| Search | `helm search repo nginx` | Shows bitnami/nginx |
| Install | `helm install lab-nginx bitnami/nginx` | STATUS: deployed |
| List | `helm list` | Shows lab-nginx, revision 1 |
| Check pods | `kubectl get pods` | 1 pod Running |
| Port-forward | `curl localhost:8080` | nginx welcome page |
| Uninstall | `helm uninstall lab-nginx` | release uninstalled |

---

## Troubleshooting

### Problem: Pod is stuck in "Pending" state

**Check what's wrong:**
```bash
kubectl describe pod lab-nginx-xxxxx
```

**Common causes:**
- Not enough cluster resources (try `minikube stop && minikube start --cpus=4 --memory=8192`)
- Image pull issues (check your internet connection)

---

### Problem: "port is already in use" during port-forward

**Solution:**
Use a different local port:
```bash
kubectl port-forward svc/lab-nginx 9090:80
# Then access http://localhost:9090
```

---

### Problem: Install fails with "INSTALLATION FAILED"

**Get more details:**
```bash
helm install lab-nginx bitnami/nginx --debug
```

**Common causes:**
- Chart not found (did you `helm repo add` and `helm repo update`?)
- Release name already exists (uninstall first or choose different name)

---

## Optional Challenges

### Challenge 1: Install with Custom Service Type

Install nginx with NodePort so Minikube can provide a URL:

```bash
helm install nginx-nodeport bitnami/nginx --set service.type=NodePort
```

Then get the URL:
```bash
minikube service nginx-nodeport --url
```

Open that URL in your browser!

Don't forget to uninstall when done:
```bash
helm uninstall nginx-nodeport
```

---

### Challenge 2: Install with Multiple Replicas

```bash
helm install nginx-ha bitnami/nginx --set replicaCount=3
kubectl get pods
```

You should see 3 pods running. This demonstrates high availability.

Uninstall:
```bash
helm uninstall nginx-ha
```

---

### Challenge 3: Inspect the Computed Values

```bash
helm install nginx-debug bitnami/nginx --dry-run --debug 2>&1 | grep -A 20 "COMPUTED VALUES"
```

This shows all the final values after merging defaults with your overrides.

---

## Key Takeaways

1. **`helm repo add` + `helm repo update`** = Set up your chart sources
2. **`helm search repo`** = Find charts in your repos
3. **`helm install --dry-run --debug`** = Preview before installing
4. **`helm install <release> <chart>`** = Install the chart
5. **`helm list` and `helm status`** = Check your releases
6. **`kubectl get pods,svc`** = Verify Kubernetes resources
7. **`helm uninstall`** = Clean up when done

---

**✅ Congratulations! You've installed your first Helm release. Next, we'll create our own chart!**
