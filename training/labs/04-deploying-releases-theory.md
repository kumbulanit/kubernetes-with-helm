# 04 – Deploying & Managing Releases (Theory)

**Estimated reading time:** 15 minutes

---

## What is a Release?

### The Simple Explanation

Think of a **release** like a **running instance** of a recipe:

- A **chart** is the recipe (instructions for making a cake)
- A **release** is the actual cake you made (running in your kitchen)

You can make the same recipe multiple times:
- Birthday cake for Alice → Release "alice-cake"
- Birthday cake for Bob → Release "bob-cake"

Same recipe, different instances.

---

### The Technical Definition

A **release** is a chart deployed to Kubernetes with a specific configuration. Each release:
- Has a unique name within a namespace
- Tracks its own revision history
- Manages its own set of Kubernetes resources
- Can be upgraded, rolled back, or uninstalled independently

---

## Release Lifecycle

A release goes through several states:

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│ Install │ ──▶ │ Running │ ──▶ │ Upgrade │ ──▶ │ Running │
│         │     │  (v1)   │     │         │     │  (v2)   │
└─────────┘     └─────────┘     └─────────┘     └─────────┘
                    │                               │
                    │          ┌─────────┐          │
                    └─────────▶│ Rollback│◀─────────┘
                               │  (v1)   │
                               └─────────┘
                                    │
                               ┌────▼────┐
                               │Uninstall│
                               └─────────┘
```

### Release States

| State | Description |
|-------|-------------|
| `deployed` | Current release is active and running |
| `superseded` | Previous release version (replaced by newer) |
| `failed` | Release failed to install or upgrade |
| `uninstalling` | Release is being deleted |
| `pending-install` | Install in progress |
| `pending-upgrade` | Upgrade in progress |
| `pending-rollback` | Rollback in progress |

---

## The Install Command

### Basic Installation

```bash
helm install <release-name> <chart>
```

**Example:**
```bash
helm install my-app bitnami/nginx
```

**What happens:**
1. Helm fetches the chart (from repo or local)
2. Merges default values with any overrides
3. Renders all templates
4. Sends resources to Kubernetes API
5. Records the release in cluster (as a Secret)
6. Displays NOTES.txt

---

### Installation Options

| Option | Description | Example |
|--------|-------------|---------|
| `--namespace` | Target namespace | `--namespace prod` |
| `--create-namespace` | Create namespace if missing | `--create-namespace` |
| `--values` / `-f` | Use values file | `-f custom-values.yaml` |
| `--set` | Override single value | `--set replicas=3` |
| `--set-string` | Override as string | `--set-string version="1.0"` |
| `--set-file` | Set value from file | `--set-file cert=cert.pem` |
| `--dry-run` | Preview without installing | `--dry-run` |
| `--debug` | Show debug information | `--debug` |
| `--wait` | Wait for pods ready | `--wait` |
| `--timeout` | Set wait timeout | `--timeout 5m` |
| `--atomic` | Auto-rollback on failure | `--atomic` |

---

### Ways to Override Values

**Method 1: Using --set (single values)**
```bash
helm install my-app ./mychart --set replicaCount=3
```

**Method 2: Using --set for nested values (dot notation)**
```bash
helm install my-app ./mychart --set image.tag=v2.0
```

**Method 3: Using --set for lists**
```bash
helm install my-app ./mychart --set "hosts[0]=host1.com,hosts[1]=host2.com"
```

**Method 4: Using a values file**
```bash
# Create a values file
cat > custom-values.yaml << EOF
replicaCount: 3
image:
  tag: v2.0
EOF

# Use it
helm install my-app ./mychart -f custom-values.yaml
```

**Method 5: Combining multiple sources**
```bash
# Values are merged in order (later values win)
helm install my-app ./mychart \
  -f base-values.yaml \
  -f prod-values.yaml \
  --set image.tag=latest
```

**Priority (lowest to highest):**
1. Chart's values.yaml
2. First values file (-f)
3. Second values file (-f)
4. --set values

---

## The Upgrade Command

Upgrades update an existing release to a new chart version or configuration.

### Basic Upgrade

```bash
helm upgrade <release-name> <chart>
```

**Example:**
```bash
helm upgrade my-app bitnami/nginx --set replicaCount=3
```

**What happens:**
1. Fetches the chart
2. Merges new values with previous release values
3. Renders templates
4. Computes diff with current release
5. Applies changes to Kubernetes
6. Increments revision number
7. Records new revision in cluster

---

### Important: Value Persistence

By default, upgrade **resets values to chart defaults**, then applies your new values.

**Problem scenario:**
```bash
# Install with replica=3
helm install my-app ./mychart --set replicaCount=3

# Upgrade without --reuse-values
helm upgrade my-app ./mychart --set image.tag=v2.0
# replicaCount is now back to default (1)!
```

**Solution 1: Use --reuse-values**
```bash
helm upgrade my-app ./mychart --reuse-values --set image.tag=v2.0
# Keeps replicaCount=3, updates image.tag
```

**Solution 2: Always specify all values**
```bash
helm upgrade my-app ./mychart -f values.yaml
# values.yaml contains ALL your configuration
```

**Best practice:** Always use a values file for predictable upgrades.

---

### Upgrade Options

| Option | Description |
|--------|-------------|
| `--reuse-values` | Keep existing values, merge new ones |
| `--reset-values` | Reset to chart defaults (default behavior) |
| `--install` / `-i` | Install if release doesn't exist |
| `--atomic` | Rollback on failure |
| `--wait` | Wait for pods ready |
| `--force` | Force resource update (delete + recreate) |

---

### Install-or-Upgrade Pattern

Use `upgrade --install` to handle both cases:

```bash
helm upgrade --install my-app ./mychart -f values.yaml
```

**What this does:**
- If "my-app" exists → Upgrade it
- If "my-app" doesn't exist → Install it

This is useful in CI/CD pipelines where you don't know the current state.

---

## Revision History

Each install/upgrade creates a new **revision**.

### View History

```bash
helm history <release-name>
```

**Example output:**
```
REVISION   UPDATED                    STATUS       CHART          APP VERSION   DESCRIPTION
1          Thu Jan 15 10:00:00 2024   superseded   mychart-0.1.0  1.0.0        Install complete
2          Thu Jan 15 11:00:00 2024   superseded   mychart-0.1.0  1.0.0        Upgrade complete
3          Thu Jan 15 12:00:00 2024   deployed     mychart-0.2.0  1.1.0        Upgrade complete
```

**Understanding the output:**
- Revision 1: Original install
- Revision 2: First upgrade (same chart version, different values?)
- Revision 3: Current (deployed), new chart version

---

### How Helm Stores History

Helm stores release information as **Secrets** in the release namespace:

```bash
kubectl get secrets -l owner=helm
```

**Output:**
```
NAME                           TYPE                 DATA   AGE
sh.helm.release.v1.my-app.v1   helm.sh/release.v1   1      1h
sh.helm.release.v1.my-app.v2   helm.sh/release.v1   1      30m
sh.helm.release.v1.my-app.v3   helm.sh/release.v1   1      5m
```

Each Secret stores the complete state of that revision.

---

## The Rollback Command

Rollback reverts to a previous revision.

### Basic Rollback

```bash
helm rollback <release-name> <revision>
```

**Example:**
```bash
# Current: revision 3
# Rollback to revision 2
helm rollback my-app 2
```

**What happens:**
1. Helm reads the state from revision 2's Secret
2. Applies that configuration
3. Creates a NEW revision (4) with revision 2's content
4. Updates the deployment

**The history after rollback:**
```
REVISION   STATUS       DESCRIPTION
1          superseded   Install complete
2          superseded   Upgrade complete
3          superseded   Upgrade complete
4          deployed     Rollback to 2
```

Notice: Rollback creates a **new** revision, not a true "undo".

---

### Rollback Options

```bash
helm rollback my-app 2 --wait       # Wait for pods ready
helm rollback my-app 2 --dry-run    # Preview without applying
helm rollback my-app 2 --force      # Force resource recreation
```

---

## The Uninstall Command

Removes a release and its resources.

### Basic Uninstall

```bash
helm uninstall <release-name>
```

**What happens:**
1. Helm finds all resources created by the release
2. Deletes them from Kubernetes
3. Removes the release record from cluster

---

### Keep History After Uninstall

If you might want to rollback after uninstall:

```bash
helm uninstall my-app --keep-history
```

**Then later:**
```bash
# See the uninstalled release
helm list --all

# Rollback to resurrect it
helm rollback my-app 3
```

---

## Status and Information Commands

### helm list

Shows all releases:

```bash
helm list                    # Current namespace
helm list --all-namespaces   # All namespaces
helm list --all              # Include failed/pending
helm list --filter 'prod-*'  # Filter by name pattern
```

### helm status

Shows detailed release status:

```bash
helm status my-app
```

**Output includes:**
- Release name, namespace, revision
- Current status
- Last deployment time
- NOTES.txt content

### helm get

Get specific information:

```bash
helm get values my-app         # User-supplied values
helm get values my-app --all   # All values (merged)
helm get manifest my-app       # Rendered Kubernetes YAML
helm get notes my-app          # Just the NOTES
helm get hooks my-app          # Hook definitions
helm get all my-app            # Everything
```

---

## Release Best Practices

### 1. Use Meaningful Release Names

```bash
# Bad
helm install r1 ./mychart

# Good
helm install prod-web-frontend ./mychart
helm install dev-api-backend ./mychart
```

**Pattern:** `<environment>-<component>-<service>`

---

### 2. Always Use Namespaces

```bash
helm install my-app ./mychart --namespace prod --create-namespace
```

Benefits:
- Isolation between environments
- Easier resource management
- Better security (RBAC per namespace)

---

### 3. Use Values Files for Each Environment

```
values/
├── values-dev.yaml
├── values-staging.yaml
└── values-prod.yaml
```

```bash
helm install my-app ./mychart -f values/values-prod.yaml -n prod
```

---

### 4. Use --wait and --timeout in CI/CD

```bash
helm upgrade --install my-app ./mychart \
  --wait \
  --timeout 5m \
  --atomic
```

- `--wait`: Don't return until pods are ready
- `--timeout`: Fail after 5 minutes
- `--atomic`: Auto-rollback if it fails

---

### 5. Document Your Releases

Create a README with:
- Release naming conventions
- Values file purpose
- Upgrade procedures
- Rollback procedures

---

## Visual: Release Management Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│                    RELEASE MANAGEMENT WORKFLOW                    │
└──────────────────────────────────────────────────────────────────┘

    DEVELOPMENT                  STAGING                 PRODUCTION
    ───────────                  ───────                 ──────────
    
    ┌─────────┐              ┌─────────┐              ┌─────────┐
    │ Install │              │ Install │              │ Install │
    │  dev-*  │              │  stg-*  │              │ prod-*  │
    └────┬────┘              └────┬────┘              └────┬────┘
         │                        │                        │
         ▼                        ▼                        ▼
    ┌─────────┐              ┌─────────┐              ┌─────────┐
    │ Test &  │              │ Test &  │              │ Monitor │
    │ Iterate │              │ Verify  │              │ & Alert │
    └────┬────┘              └────┬────┘              └────┬────┘
         │                        │                        │
         ▼                        ▼                        │
    ┌─────────┐              ┌─────────┐                   │
    │ Upgrade │ ───────────▶ │ Upgrade │ ─────────────────▶│
    │  Often  │              │Carefully│                   │
    └─────────┘              └─────────┘                   │
                                                          ▼
                                                    ┌─────────┐
                                                    │ Upgrade │
                                                    │(Planned)│
                                                    └────┬────┘
                                                         │
                                                 ┌───────┴───────┐
                                                 │   Problem?    │
                                                 └───────┬───────┘
                                                    YES  │  NO
                                              ┌──────────┴──────────┐
                                              ▼                     ▼
                                         ┌─────────┐          ┌─────────┐
                                         │Rollback │          │ Success │
                                         └─────────┘          └─────────┘
```

---

## Key Takeaways

1. **Release = Running Instance** – A chart deployed with specific configuration
2. **Revisions = History** – Every install/upgrade creates a revision
3. **Upgrade carefully** – Use `--reuse-values` or values files
4. **Rollback creates new revision** – It's not a true undo
5. **Use namespaces** – Isolate environments
6. **Use --atomic in CI/CD** – Auto-rollback on failure
7. **Keep release history** – For auditing and recovery

---

**Next: Hands-on release management!**
