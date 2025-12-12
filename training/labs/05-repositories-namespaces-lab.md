# 05 – Repositories & Namespaces (Lab)

**Objective:** Work with multiple Helm repositories and deploy applications across different namespaces.

**Estimated duration:** 25–30 minutes

**Prerequisites:** Helm installed, Minikube running, my-webapp chart from Module 03.

---

## What You Will Do

1. Explore existing repositories
2. Add and manage multiple repositories
3. Search for charts across repositories
4. Create and use namespaces
5. Deploy the same chart to multiple namespaces
6. Manage releases across namespaces
7. Clean up

---

## Multi-Namespace Deployment Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    NAMESPACE ISOLATION                           │
└─────────────────────────────────────────────────────────────────┘

    REPOSITORIES                      KUBERNETES CLUSTER
    ────────────                      ──────────────────

  ┌─────────────┐                ┌───────────────────────────────┐
  │   Bitnami   │                │                               │
  │  Prometheus │ ──────────────▶│   Namespace: dev              │
  │   Grafana   │      │         │  ┌─────────────────────────┐  │
  └─────────────┘      │         │  │  webapp (replicas: 1)   │  │
        │              │         │  │  "Development Env"      │  │
        │              │         │  └─────────────────────────┘  │
        │              │         │                               │
        ▼              │         ├───────────────────────────────┤
  helm search repo     │         │                               │
  helm install         │         │   Namespace: staging          │
        │              │         │  ┌─────────────────────────┐  │
        │              ├────────▶│  │  webapp (replicas: 2)   │  │
        │              │         │  │  "Staging Env"          │  │
        │              │         │  └─────────────────────────┘  │
        │              │         │                               │
        │              │         ├───────────────────────────────┤
        │              │         │                               │
        │              │         │   Namespace: production       │
        │              └────────▶│  ┌─────────────────────────┐  │
        │                        │  │  webapp (replicas: 3)   │  │
        │                        │  │  "Production Env"       │  │
        │                        │  └─────────────────────────┘  │
        │                        │                               │
        │                        └───────────────────────────────┘
        │
        ▼
  Same chart, different
  configurations per
  namespace!
```

---

## Step-by-Step Instructions

### Step 1: View Current Repositories

**List configured repositories:**
```bash
helm repo list
```

**Expected output:**
```
NAME    URL
bitnami https://charts.bitnami.com/bitnami
```

If you don't see bitnami, add it:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

---

### Step 2: Add More Repositories

Let's add some popular repositories.

**Add Prometheus community charts:**
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

**Expected output:**
```
"prometheus-community" has been added to your repositories
```

**Add Grafana charts:**
```bash
helm repo add grafana https://grafana.github.io/helm-charts
```

**Add ingress-nginx:**
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
```

**Verify all repositories:**
```bash
helm repo list
```

**Expected output:**
```
NAME                 URL
bitnami              https://charts.bitnami.com/bitnami
prometheus-community https://prometheus-community.github.io/helm-charts
grafana              https://grafana.github.io/helm-charts
ingress-nginx        https://kubernetes.github.io/ingress-nginx
```

You now have 4 repositories configured!

---

### Step 3: Update All Repositories

Download the latest chart listings:

```bash
helm repo update
```

**Expected output:**
```
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "prometheus-community" chart repository
...Successfully got an update from the "grafana" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
...Successfully got an update from the "bitnami" chart repository
Update Complete. ⎈Happy Helming!⎈
```

---

### Step 4: Search Across Repositories

**Search for monitoring-related charts:**
```bash
helm search repo prometheus
```

**Expected output (partial):**
```
NAME                                    CHART VERSION   APP VERSION   DESCRIPTION
prometheus-community/prometheus         25.0.0          v2.47.0       Prometheus is a monitoring system...
prometheus-community/kube-prometheus-stack   51.0.0     v0.68.0       kube-prometheus-stack collects...
bitnami/prometheus                      0.3.0           2.47.0        Prometheus is an open source...
```

**Notice:** Multiple repositories have prometheus charts. The name format is `<repo-name>/<chart-name>`.

**Search for grafana:**
```bash
helm search repo grafana
```

**Search with version filter:**
```bash
helm search repo prometheus --versions | head -n 10
```

This shows all available versions of each chart.

---

### Step 5: Get Chart Information

**View chart details:**
```bash
helm show chart prometheus-community/prometheus
```

**Expected output:**
```yaml
apiVersion: v2
appVersion: v2.47.0
description: Prometheus is a monitoring system and time series database.
name: prometheus
version: 25.0.0
...
```

**View default values:**
```bash
helm show values prometheus-community/prometheus | head -n 50
```

**View README (full documentation):**
```bash
helm show readme prometheus-community/prometheus | head -n 100
```

---

### Step 6: Create Namespaces

Let's create namespaces for different environments.

**Create dev namespace:**
```bash
kubectl create namespace dev
```

**Expected output:**
```
namespace/dev created
```

**Create staging namespace:**
```bash
kubectl create namespace staging
```

**Create production namespace:**
```bash
kubectl create namespace production
```

**Verify namespaces:**
```bash
kubectl get namespaces
```

**Expected output:**
```
NAME              STATUS   AGE
default           Active   1h
dev               Active   30s
kube-node-lease   Active   1h
kube-public       Active   1h
kube-system       Active   1h
production        Active   10s
staging           Active   20s
```

---

### Step 7: Deploy to Dev Namespace

Let's deploy our webapp to the dev namespace.

**Navigate to your chart:**
```bash
cd ~/helm-training
```

**Install to dev namespace:**
```bash
helm install webapp my-webapp \
  --namespace dev \
  --set welcomeMessage="Development Environment" \
  --set replicaCount=1
```

**Expected output:**
```
NAME: webapp
LAST DEPLOYED: Thu Jan 15 15:00:00 2024
NAMESPACE: dev
STATUS: deployed
REVISION: 1
...
```

---

### Step 8: Deploy to Staging Namespace

**Install to staging namespace:**
```bash
helm install webapp my-webapp \
  --namespace staging \
  --set welcomeMessage="Staging Environment" \
  --set replicaCount=2
```

**Expected output:**
```
NAME: webapp
NAMESPACE: staging
STATUS: deployed
REVISION: 1
...
```

**Notice:** Same release name "webapp" works in different namespaces!

---

### Step 9: Deploy to Production Namespace

**Install to production namespace:**
```bash
helm install webapp my-webapp \
  --namespace production \
  --set welcomeMessage="Production Environment - Handle with Care!" \
  --set replicaCount=3 \
  --set service.type=NodePort
```

---

### Step 10: List Releases Across Namespaces

**List releases in current namespace (default):**
```bash
helm list
```

**Expected output:**
```
NAME    NAMESPACE   REVISION   ...
(empty - no releases in default namespace)
```

**List releases in dev namespace:**
```bash
helm list --namespace dev
```

**Expected output:**
```
NAME    NAMESPACE   REVISION   STATUS     CHART           APP VERSION
webapp  dev         1          deployed   my-webapp-0.1.0 1.25.0
```

**List releases in ALL namespaces:**
```bash
helm list --all-namespaces
```

**Expected output:**
```
NAME    NAMESPACE    REVISION   STATUS     CHART           APP VERSION
webapp  dev          1          deployed   my-webapp-0.1.0 1.25.0
webapp  staging      1          deployed   my-webapp-0.1.0 1.25.0
webapp  production   1          deployed   my-webapp-0.1.0 1.25.0
```

**Three releases, same name, different namespaces!**

---

### Step 11: Verify Pods Across Namespaces

**Check pods in all namespaces:**
```bash
kubectl get pods --all-namespaces | grep webapp
```

**Expected output:**
```
dev          webapp-my-webapp-xxxxx    1/1   Running   0   2m
production   webapp-my-webapp-aaaaa    1/1   Running   0   1m
production   webapp-my-webapp-bbbbb    1/1   Running   0   1m
production   webapp-my-webapp-ccccc    1/1   Running   0   1m
staging      webapp-my-webapp-yyyyy    1/1   Running   0   2m
staging      webapp-my-webapp-zzzzz    1/1   Running   0   2m
```

**Notice:** Dev has 1 pod, Staging has 2, Production has 3 (matching our replicaCount settings).

---

### Step 12: Test Each Environment

**Test Dev environment:**
```bash
kubectl port-forward svc/webapp-my-webapp 8081:80 --namespace dev &
sleep 2
curl -s http://localhost:8081 | grep -o "<h1>.*</h1>"
kill %1 2>/dev/null || true
```

**Expected output:**
```
<h1>Development Environment</h1>
```

**Test Staging environment:**
```bash
kubectl port-forward svc/webapp-my-webapp 8082:80 --namespace staging &
sleep 2
curl -s http://localhost:8082 | grep -o "<h1>.*</h1>"
kill %1 2>/dev/null || true
```

**Expected output:**
```
<h1>Staging Environment</h1>
```

**Test Production environment (uses NodePort):**
```bash
minikube service webapp-my-webapp --namespace production --url
```

Copy the URL and open in browser, or:
```bash
URL=$(minikube service webapp-my-webapp --namespace production --url)
curl -s "$URL" | grep -o "<h1>.*</h1>"
```

**Expected output:**
```
<h1>Production Environment - Handle with Care!</h1>
```

---

### Step 13: Upgrade in One Namespace

Let's upgrade only the dev release:

```bash
helm upgrade webapp my-webapp \
  --namespace dev \
  --set welcomeMessage="Development v2 - Updated!" \
  --set replicaCount=1
```

**Check that only dev was upgraded:**
```bash
helm list --all-namespaces
```

**Expected output:**
```
NAME    NAMESPACE    REVISION   ...
webapp  dev          2          ...    # Revision 2!
webapp  staging      1          ...    # Still Revision 1
webapp  production   1          ...    # Still Revision 1
```

Only dev was upgraded to revision 2.

---

### Step 14: View Release History by Namespace

**Dev history:**
```bash
helm history webapp --namespace dev
```

**Expected output:**
```
REVISION   STATUS       DESCRIPTION
1          superseded   Install complete
2          deployed     Upgrade complete
```

**Production history:**
```bash
helm history webapp --namespace production
```

**Expected output:**
```
REVISION   STATUS     DESCRIPTION
1          deployed   Install complete
```

---

### Step 15: Set Default Namespace (Optional)

To avoid typing `--namespace` every time:

**Using kubectl:**
```bash
kubectl config set-context --current --namespace=dev
```

**Now helm commands use dev by default:**
```bash
helm list   # Shows dev namespace
```

**Reset to default namespace:**
```bash
kubectl config set-context --current --namespace=default
```

---

### Step 16: Remove a Repository

Let's remove a repository we don't need:

```bash
helm repo remove ingress-nginx
```

**Expected output:**
```
"ingress-nginx" has been removed from your repositories
```

**Verify:**
```bash
helm repo list
```

The ingress-nginx repository is gone.

---

### Step 17: Clean Up

**Uninstall all webapp releases:**
```bash
helm uninstall webapp --namespace dev
helm uninstall webapp --namespace staging
helm uninstall webapp --namespace production
```

**Delete the namespaces:**
```bash
kubectl delete namespace dev
kubectl delete namespace staging
kubectl delete namespace production
```

**Verify cleanup:**
```bash
helm list --all-namespaces
kubectl get namespaces | grep -E "(dev|staging|production)"
```

Both should return empty.

**Keep repositories for future use** (or remove them):
```bash
# Optional: Remove all added repos except bitnami
helm repo remove prometheus-community
helm repo remove grafana
```

---

## Expected Results Summary

| Step | Action | Expected Result |
|------|--------|-----------------|
| Add repos | `helm repo add ...` | Repository added |
| Update repos | `helm repo update` | Latest indexes downloaded |
| Search | `helm search repo prometheus` | Charts from multiple repos |
| Create namespaces | `kubectl create namespace dev` | Namespaces created |
| Install to namespace | `helm install webapp my-webapp -n dev` | Release in dev namespace |
| List all | `helm list --all-namespaces` | Shows all releases |
| Upgrade one | `helm upgrade ... -n dev` | Only dev updated |
| Uninstall | `helm uninstall webapp -n dev` | Release removed from dev |

---

## Troubleshooting

### Problem: "namespace not found"

**Solution:** Create the namespace first, or use `--create-namespace`:
```bash
helm install webapp my-webapp \
  --namespace myns \
  --create-namespace
```

---

### Problem: "release already exists"

**Cause:** A release with that name exists in that namespace.

**Check existing releases:**
```bash
helm list --namespace myns
```

**Solutions:**
```bash
# Uninstall existing release
helm uninstall webapp --namespace myns

# Or use a different release name
helm install webapp-v2 my-webapp --namespace myns
```

---

### Problem: "Error: repo not found"

**Cause:** Repository wasn't added or was removed.

**Solution:**
```bash
# List current repos
helm repo list

# Add the missing repo
helm repo add myrepo https://...

# Update
helm repo update
```

---

### Problem: Can't find chart after adding repo

**Solution:**
```bash
# Make sure to update after adding
helm repo update

# Search again
helm search repo chartname
```

---

## Commands Reference

### Repository Commands
```bash
helm repo add <name> <url>      # Add repository
helm repo list                  # List repositories
helm repo update                # Update all repos
helm repo remove <name>         # Remove repository
helm search repo <keyword>      # Search charts
helm search repo <chart> --versions  # See all versions
helm show chart <repo>/<chart>  # View chart metadata
helm show values <repo>/<chart> # View default values
```

### Namespace Commands
```bash
kubectl create namespace <name>     # Create namespace
kubectl get namespaces              # List namespaces
kubectl delete namespace <name>     # Delete namespace

# Helm with namespaces
helm install ... --namespace <ns>              # Install to namespace
helm install ... -n <ns> --create-namespace    # Create ns if needed
helm list --namespace <ns>                     # List in namespace
helm list --all-namespaces                     # List all
helm upgrade ... --namespace <ns>              # Upgrade in namespace
helm uninstall <name> --namespace <ns>         # Uninstall from namespace
```

---

## Key Takeaways

1. **Multiple repositories** give you access to more charts
2. **`helm repo update`** downloads latest chart versions
3. **Search format** is `<repo-name>/<chart-name>`
4. **Namespaces** provide isolation between environments
5. **Same release name** can exist in different namespaces
6. **Always specify namespace** with `--namespace` or `-n`
7. **Use `--create-namespace`** in CI/CD pipelines
8. **`helm list --all-namespaces`** shows everything

---

**✅ Great work! You can now manage repositories and deploy across namespaces!**
