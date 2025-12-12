# 02 – Installing & Using Helm (Theory) 10:00–11:00

**Learning objectives:**
- Understand how repositories work and how to manage them
- Learn the difference between searching, pulling, and installing
- Install your first Helm release and understand what happens

---

## The Repository System Explained

### What is a Repository?

A Helm repository is simply a web server that hosts chart packages and an index file. Think of it like this:

- **Apple App Store** = A repository of iOS apps
- **npm** = A repository of JavaScript packages
- **Bitnami Helm Repo** = A repository of Kubernetes charts

When you add a repository, Helm downloads an **index file** that lists all available charts, their versions, and where to download them.

### Repository Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. ADD REPO                                                      │
│    helm repo add bitnami https://charts.bitnami.com/bitnami     │
│    → Helm saves the URL and downloads the index                  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. UPDATE REPO                                                   │
│    helm repo update                                              │
│    → Helm re-downloads the index to get latest chart versions   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. SEARCH REPO                                                   │
│    helm search repo nginx                                        │
│    → Helm searches the local index (fast, works offline)        │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. INSTALL FROM REPO                                             │
│    helm install my-nginx bitnami/nginx                          │
│    → Helm downloads chart, renders templates, applies to cluster│
└─────────────────────────────────────────────────────────────────┘
```

---

## Search Commands Explained

Helm has two search commands that work differently:

### `helm search hub <term>`

**What it does:** Searches Artifact Hub, a public website indexing charts from many sources.

**When to use:** When you're looking for a chart and don't know which repo has it.

**Example:**
```bash
helm search hub redis
```

**Pros:** Finds charts from everywhere
**Cons:** Requires internet; you still need to add the repo before installing

---

### `helm search repo <term>`

**What it does:** Searches the index files of repositories you've already added.

**When to use:** When you've added repos and want to find specific charts.

**Example:**
```bash
helm search repo redis
```

**Pros:** Fast; works offline (after initial repo add/update)
**Cons:** Only searches repos you've added

---

## Installing a Chart: What Actually Happens

When you run `helm install`, Helm performs several steps:

### Example Command:
```bash
helm install my-nginx bitnami/nginx
```

### Step-by-Step Breakdown:

**Step 1: Parse the command**
- `my-nginx` = The release name (your choice, must be unique in the namespace)
- `bitnami/nginx` = The chart reference (repo-name/chart-name)

**Step 2: Download the chart**
Helm downloads the chart archive from the repository to your local cache.

**Step 3: Read values**
Helm reads `values.yaml` from the chart. If you provided overrides (`--set` or `-f`), those are merged on top.

**Step 4: Render templates**
Helm processes each file in `templates/`, replacing placeholders like `{{ .Values.replicaCount }}` with actual values.

**Step 5: Validate the YAML**
Helm checks that the rendered YAML is valid Kubernetes syntax.

**Step 6: Send to Kubernetes**
Helm sends the rendered manifests to the Kubernetes API server (like `kubectl apply`).

**Step 7: Create release record**
Helm stores a record of this installation as a Kubernetes Secret in the namespace. This enables upgrades and rollbacks later.

---

## Understanding Release Names

The release name is important:

```bash
helm install my-nginx bitnami/nginx
#            ^^^^^^^^
#            This is your release name
```

### Rules for release names:
- Must be unique within a namespace
- Use lowercase letters, numbers, and hyphens
- Maximum 53 characters
- Should be descriptive (e.g., `frontend-prod`, `api-staging`)

### Why release names matter:
- All resources created will include this name
- You use it for upgrades: `helm upgrade my-nginx bitnami/nginx`
- You use it to check status: `helm status my-nginx`
- You use it to uninstall: `helm uninstall my-nginx`

### Example of multiple releases:
```bash
# Same chart, different releases for different purposes
helm install web-prod bitnami/nginx -n production
helm install web-staging bitnami/nginx -n staging
helm install docs-site bitnami/nginx -n documentation
```

---

## The `helm pull` Command: Downloading Without Installing

Sometimes you want to download a chart without installing it:

```bash
helm pull bitnami/nginx --untar -d /tmp/nginx-chart
```

### Breaking down this command:
- `helm pull` = Download the chart archive
- `bitnami/nginx` = Which chart to download
- `--untar` = Extract the archive (otherwise you get a .tgz file)
- `-d /tmp/nginx-chart` = Where to put it

### Why pull instead of install?
1. **Inspect the templates** before installing
2. **Modify the chart** for your specific needs
3. **Store charts** in your own version control
4. **Work offline** after pulling

### What you get:
```
/tmp/nginx-chart/nginx/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ...
└── README.md
```

---

## Preview Before Installing: Dry Run

Never install blind! Always preview first:

### Option 1: `helm template` (render locally)
```bash
helm template my-nginx bitnami/nginx
```
Shows rendered YAML without contacting the cluster.

### Option 2: `helm install --dry-run` (server-side validation)
```bash
helm install my-nginx bitnami/nginx --dry-run --debug
```
Renders templates AND validates against the Kubernetes API (catches more errors).

### What `--debug` adds:
- Shows the computed values
- Shows hook manifests
- More detailed output

---

## Listing and Checking Releases

After installing, you'll want to check your releases:

### List all releases in current namespace:
```bash
helm list
```

**Output:**
```
NAME      NAMESPACE   REVISION   UPDATED                   STATUS     CHART          APP VERSION
my-nginx  default     1          2024-01-15 10:30:00       deployed   nginx-15.0.0   1.25.0
```

### List releases in all namespaces:
```bash
helm list --all-namespaces
# or shorter:
helm list -A
```

### Check status of a specific release:
```bash
helm status my-nginx
```

**Output shows:**
- Deployment status (deployed, failed, pending)
- Last deployed time
- Namespace
- Notes from the chart (often includes access instructions)

---

## Uninstalling: Cleaning Up

When you're done with a release:

```bash
helm uninstall my-nginx
```

### What this does:
1. Finds all Kubernetes resources created by this release
2. Deletes them (Deployments, Services, ConfigMaps, etc.)
3. Removes the release record

### What it does NOT delete:
- PersistentVolumeClaims (by default, to protect data)
- Resources created outside of Helm

### Keep history after uninstall:
```bash
helm uninstall my-nginx --keep-history
```
This lets you see the old release with `helm history my-nginx` and even rollback to it.

---

## Common Flags for `helm install`

| Flag | Purpose | Example |
|------|---------|---------|
| `--set key=value` | Override a single value | `--set replicaCount=3` |
| `-f values.yaml` | Use a custom values file | `-f my-values.yaml` |
| `-n namespace` | Install in specific namespace | `-n production` |
| `--create-namespace` | Create namespace if missing | `-n new-ns --create-namespace` |
| `--dry-run` | Preview without installing | `--dry-run --debug` |
| `--wait` | Wait until pods are ready | `--wait --timeout 5m` |
| `--atomic` | Rollback if install fails | `--atomic` |

---

## Practical Example: Full Workflow

Let's walk through a complete example:

```bash
# 1. Add repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# 2. Update to get latest charts
helm repo update

# 3. Search for what we want
helm search repo nginx

# 4. Check the chart's documentation
helm show readme bitnami/nginx | head -n 30

# 5. Check default values
helm show values bitnami/nginx | head -n 20

# 6. Preview what will be installed
helm install demo-nginx bitnami/nginx --dry-run --debug | head -n 100

# 7. Actually install it
helm install demo-nginx bitnami/nginx

# 8. Verify installation
helm list
helm status demo-nginx

# 9. Check Kubernetes resources
kubectl get pods,svc

# 10. Clean up when done
helm uninstall demo-nginx
```

---

## Beginner Tips

1. **Always run `helm repo update` before installing** – You want the latest chart versions.

2. **Use `--dry-run --debug` liberally** – Preview before you commit.

3. **Choose meaningful release names** – `test1` and `test2` become confusing; use `nginx-frontend-dev` instead.

4. **Check the README first** – Charts often have required values or prerequisites.

5. **Start with defaults** – Install with no overrides first, then customize in subsequent upgrades.

---

## Review Questions

1. **What's the difference between `helm search hub` and `helm search repo`?**
   - `hub` searches the internet; `repo` searches locally added repositories.

2. **What does `helm repo update` do?**
   - Re-downloads the index file from each repo to get the latest chart list.

3. **Why would you use `helm pull` instead of `helm install`?**
   - To download and inspect a chart without installing it, or to modify it.

4. **What information does `helm status <release>` show?**
   - Deployment status, last update time, namespace, and chart notes.

5. **How do you preview an installation without actually creating resources?**
   - Use `--dry-run --debug` flag with `helm install`.

---

**✅ You now understand how Helm repositories and installations work. Let's practice in the lab!**
