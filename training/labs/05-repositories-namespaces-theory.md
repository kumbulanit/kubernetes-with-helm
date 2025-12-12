# 05 – Repositories & Namespaces (Theory)

**Estimated reading time:** 15 minutes

---

## Part 1: Helm Repositories

### What is a Helm Repository?

### The Simple Explanation

Think of a Helm repository like an **app store** for Kubernetes:

- **Apple App Store** has thousands of apps you can download
- **Helm Repository** has hundreds of charts you can install

Just like the App Store:
- Someone maintains the repository
- Apps/Charts are versioned
- You search, download, and install

---

### The Technical Definition

A Helm repository is an **HTTP server** that hosts:
1. An `index.yaml` file listing all available charts and versions
2. Packaged chart files (`.tgz` archives)

When you run `helm repo add`, you're telling Helm where to look for charts.

---

### Repository Types

| Type | Description | Example |
|------|-------------|---------|
| **Public** | Open to everyone | Bitnami, Artifact Hub |
| **Private** | Company-internal | Your corporate Helm repo |
| **OCI Registry** | Container registry | Docker Hub, AWS ECR, Azure ACR |

---

### How Repositories Work

```
┌──────────────────────────────────────────────────────────────────┐
│                    REPOSITORY WORKFLOW                            │
└──────────────────────────────────────────────────────────────────┘

   YOUR COMPUTER                         REPOSITORY SERVER
   ──────────────                        ─────────────────
   
   ┌─────────────┐                       ┌─────────────────┐
   │ helm repo   │   ────────────────▶   │   index.yaml    │
   │    add      │   Download index      │                 │
   └─────────────┘                       │  nginx: v1.0    │
                                         │  redis: v2.0    │
   ┌─────────────┐                       │  mysql: v3.0    │
   │ helm search │   Search locally      └─────────────────┘
   │    repo     │   (uses cached index)
   └─────────────┘                       ┌─────────────────┐
                                         │   Charts (.tgz) │
   ┌─────────────┐                       │                 │
   │ helm install│   ────────────────▶   │  nginx-1.0.tgz  │
   │             │   Download chart      │  redis-2.0.tgz  │
   └─────────────┘                       │  mysql-3.0.tgz  │
                                         └─────────────────┘
```

---

### The index.yaml File

The `index.yaml` is the catalog of a repository:

```yaml
apiVersion: v1
entries:
  nginx:
    - name: nginx
      version: 15.0.0
      appVersion: "1.25.0"
      description: NGINX Open Source is a web server...
      urls:
        - https://charts.bitnami.com/bitnami/nginx-15.0.0.tgz
      digest: sha256:abc123...
    - name: nginx
      version: 14.2.0
      appVersion: "1.24.0"
      ...
  redis:
    - name: redis
      version: 18.0.0
      ...
generated: "2024-01-15T10:00:00Z"
```

**Key fields:**
- `entries`: Map of chart-name → list of versions
- `urls`: Where to download the chart
- `digest`: Checksum for verification
- `generated`: When the index was last updated

---

### Repository Commands

| Command | Description |
|---------|-------------|
| `helm repo add <name> <url>` | Add a repository |
| `helm repo list` | Show configured repositories |
| `helm repo update` | Download latest index files |
| `helm repo remove <name>` | Remove a repository |

---

### Finding Charts: Artifact Hub

**Artifact Hub** (https://artifacthub.io) is like Google for Helm charts:

- Search across many repositories
- View chart documentation
- See version history
- Check security reports
- Find installation instructions

Before adding random repositories, search Artifact Hub to find official/verified charts.

---

### Popular Public Repositories

| Repository | URL | Description |
|------------|-----|-------------|
| Bitnami | `https://charts.bitnami.com/bitnami` | High-quality, production-ready |
| Prometheus | `https://prometheus-community.github.io/helm-charts` | Monitoring |
| Grafana | `https://grafana.github.io/helm-charts` | Visualization |
| Jetstack | `https://charts.jetstack.io` | cert-manager |
| Ingress-nginx | `https://kubernetes.github.io/ingress-nginx` | Ingress controller |

---

### OCI Registries (Modern Approach)

Helm 3 supports storing charts in OCI (container) registries:

```bash
# Login to registry
helm registry login registry.example.com

# Push a chart
helm push mychart-0.1.0.tgz oci://registry.example.com/charts

# Install from OCI
helm install my-release oci://registry.example.com/charts/mychart --version 0.1.0
```

**Benefits of OCI:**
- Use existing container registry infrastructure
- Single registry for images AND charts
- Better access control
- Immutable versions

---

## Part 2: Kubernetes Namespaces

### What is a Namespace?

### The Simple Explanation

Think of namespaces like **folders on your computer**:

- You can have a file called `report.txt` in both `/work/` and `/personal/`
- They don't conflict because they're in different folders
- You can delete everything in `/personal/` without affecting `/work/`

In Kubernetes:
- You can have a release called `nginx` in both `dev` and `prod` namespaces
- They don't conflict because they're in different namespaces
- You can delete everything in `dev` without affecting `prod`

---

### The Technical Definition

A **namespace** is a virtual cluster within a physical cluster. It provides:
- Isolation between environments/teams
- Resource quotas and limits
- Network policies
- RBAC (who can do what)

---

### Default Namespaces

Every Kubernetes cluster starts with these:

| Namespace | Purpose |
|-----------|---------|
| `default` | Default for resources with no namespace specified |
| `kube-system` | Kubernetes system components |
| `kube-public` | Publicly readable resources |
| `kube-node-lease` | Node heartbeats |

---

### Why Use Namespaces?

```
┌──────────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                             │
└──────────────────────────────────────────────────────────────────┘

     Namespace: dev              Namespace: staging           Namespace: prod
     ─────────────              ───────────────            ────────────────
    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │  my-app     │            │  my-app     │            │  my-app     │
    │  (v2.1-dev) │            │  (v2.0)     │            │  (v1.9)     │
    └─────────────┘            └─────────────┘            └─────────────┘
    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │  redis      │            │  redis      │            │  redis      │
    │  (latest)   │            │  (7.0)      │            │  (6.2-LTS)  │
    └─────────────┘            └─────────────┘            └─────────────┘
    
    Resources: 2GB              Resources: 8GB              Resources: 32GB
    Developers: Everyone        Developers: Senior          Developers: DevOps
```

**Benefits shown:**
1. Same names (my-app, redis) in different environments
2. Different versions per environment
3. Different resource limits
4. Different access permissions

---

### Helm and Namespaces

Helm releases are **namespace-scoped**. The same release name can exist in different namespaces.

**Installing to a specific namespace:**
```bash
# Install to 'dev' namespace (create it if needed)
helm install my-app ./mychart --namespace dev --create-namespace

# Install to 'prod' namespace
helm install my-app ./mychart --namespace prod --create-namespace
```

**Listing releases by namespace:**
```bash
# Current namespace only
helm list

# Specific namespace
helm list --namespace prod

# All namespaces
helm list --all-namespaces
```

---

### Namespace Best Practices

#### 1. Environment-based Namespaces

```
development
staging
production
```

**Helm commands:**
```bash
helm install my-app ./mychart -n development --create-namespace
helm install my-app ./mychart -n staging --create-namespace
helm install my-app ./mychart -n production --create-namespace
```

#### 2. Team-based Namespaces

```
team-frontend
team-backend
team-data
```

#### 3. Application-based Namespaces

```
app-payment
app-inventory
app-shipping
```

---

### Cross-Namespace Communication

Services in one namespace can reach services in another using **full DNS names**:

```
<service-name>.<namespace>.svc.cluster.local
```

**Example:**
- In `dev` namespace: Service `redis`
- In `staging` namespace: Service `my-app`

From `my-app` in staging, connect to Redis in dev:
```
redis.dev.svc.cluster.local:6379
```

---

### Setting Default Namespace

Instead of typing `--namespace` every time:

**Temporary (current shell):**
```bash
export HELM_NAMESPACE=dev
helm install my-app ./mychart  # Uses 'dev'
```

**kubectl context (persistent):**
```bash
kubectl config set-context --current --namespace=dev
helm install my-app ./mychart  # Uses 'dev'
```

---

## Part 3: Best Practices

### Repository Management

1. **Use official repositories when available**
   - Bitnami, Prometheus-community, etc.
   - Check Artifact Hub for verified publishers

2. **Keep repositories updated**
   ```bash
   helm repo update
   ```
   Run this regularly, especially before installing charts.

3. **Consider OCI for production**
   - Better security
   - Integrated with container workflow
   - Immutable versions

4. **Version pin your chart dependencies**
   ```yaml
   # Chart.yaml
   dependencies:
     - name: redis
       version: "18.0.0"  # Pin exact version
       repository: https://charts.bitnami.com/bitnami
   ```

---

### Namespace Strategy

1. **Always specify namespace**
   ```bash
   helm install my-app ./mychart --namespace myns
   ```
   Don't rely on default namespace.

2. **Use --create-namespace**
   ```bash
   helm install my-app ./mychart -n myns --create-namespace
   ```
   Especially in CI/CD where namespace might not exist.

3. **Match namespace to environment**
   ```bash
   # Environment-specific values
   helm install my-app ./mychart \
     -n production \
     -f values-production.yaml
   ```

4. **Use Resource Quotas**
   Prevent one team/app from consuming all resources:
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: compute-quota
     namespace: dev
   spec:
     hard:
       requests.cpu: "10"
       requests.memory: 20Gi
       limits.cpu: "20"
       limits.memory: 40Gi
   ```

---

### Security Considerations

1. **Use RBAC**
   Limit who can deploy to which namespaces.

2. **Network Policies**
   Control traffic between namespaces.

3. **Chart Verification**
   ```bash
   # Verify chart signature (if available)
   helm verify mychart-0.1.0.tgz
   ```

4. **Private Repositories**
   For proprietary charts, use private repos with authentication.

---

## Part 4: Hosting Your Own Chart Repository

### Why Host Your Own Repository?

- **Share charts** with your team or organization
- **Private charts** that shouldn't be public
- **CI/CD integration** for automated chart publishing
- **Version control** over what charts are available

### Repository Structure

A Helm repository is surprisingly simple. It's just an HTTP server with:

```
charts/
├── index.yaml           # Catalog of all charts
├── nginx-1.0.0.tgz      # Packaged chart
├── nginx-1.0.0.tgz.prov # Optional: Signature file
├── mysql-2.0.0.tgz
└── myapp-3.0.0.tgz
```

### The index.yaml File

The `index.yaml` is the heart of a repository. Helm downloads this file to know what charts are available:

```yaml
apiVersion: v1
entries:
  nginx:
    - name: nginx
      version: 1.0.0
      appVersion: "1.25.0"
      description: NGINX web server
      urls:
        - https://my-repo.example.com/charts/nginx-1.0.0.tgz
      digest: sha256:abc123...
      created: "2024-01-15T10:00:00Z"
  mysql:
    - name: mysql
      version: 2.0.0
      ...
generated: "2024-01-15T10:00:00Z"
```

### Packaging Charts

Before uploading, you must package your chart:

```bash
# Package a chart
helm package ./mychart

# Output: mychart-0.1.0.tgz
```

### Generating index.yaml

```bash
# In your charts directory
helm repo index .

# Or with a URL prefix
helm repo index . --url https://my-repo.example.com/charts
```

### Repository Hosting Options

| Option | Complexity | Best For |
|--------|------------|----------|
| **Static web server** | Low | Simple setups |
| **GitHub Pages** | Low | Open source projects |
| **ChartMuseum** | Medium | Teams needing API |
| **Cloud storage** | Medium | S3, GCS, Azure Blob |
| **OCI Registry** | Medium | Container-centric teams |
| **Harbor** | High | Enterprise features |

### ChartMuseum: Self-Hosted Repository

[ChartMuseum](https://chartmuseum.com/) is a popular open-source Helm chart repository with:
- Simple API for uploading charts
- Multiple storage backends (local, S3, GCS, Azure)
- Multi-tenancy support
- Basic authentication

**Quick Start with Helm:**

```bash
# Add ChartMuseum chart repo
helm repo add chartmuseum https://chartmuseum.github.io/charts

# Install ChartMuseum
helm install chartmuseum chartmuseum/chartmuseum \
  --namespace tools \
  --set env.open.STORAGE=local \
  --set env.open.DISABLE_API=false \
  --set persistence.enabled=true
```

**Upload a chart to ChartMuseum:**

```bash
# Using curl
curl --data-binary "@mychart-0.1.0.tgz" http://localhost:8080/api/charts

# Using helm-push plugin
helm plugin install https://github.com/chartmuseum/helm-push
helm push mychart-0.1.0.tgz my-repo
```

### GitHub Pages Repository

Free hosting for public charts:

1. Create a GitHub repo with a `charts/` folder
2. Package and add charts to the folder
3. Generate `index.yaml`:
   ```bash
   helm repo index charts/ --url https://username.github.io/repo-name/charts
   ```
4. Enable GitHub Pages for the repo
5. Add the repo:
   ```bash
   helm repo add my-charts https://username.github.io/repo-name/charts
   ```

### Repository Workflow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                   CHART REPOSITORY WORKFLOW                       │
└──────────────────────────────────────────────────────────────────┘

   DEVELOPER                                       REPOSITORY
   ─────────                                       ──────────
   
   ┌─────────────┐
   │ Create/Edit │
   │   Chart     │
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │ helm lint   │  Validate chart
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │helm package │  Create .tgz
   └──────┬──────┘
          │
          ▼                              ┌─────────────────┐
   ┌─────────────┐                       │                 │
   │ helm push   │ ─────────────────────▶│  ChartMuseum    │
   │ (or curl)   │                       │  S3 / GCS       │
   └─────────────┘                       │  GitHub Pages   │
                                         │                 │
   USER                                  └────────┬────────┘
   ────                                           │
                                                  │
   ┌─────────────┐                               │
   │helm repo add│ ◀──────────────────────────────
   └──────┬──────┘
          │
          ▼
   ┌─────────────┐
   │helm install │  Deploy chart
   │ repo/chart  │
   └─────────────┘
```

---

## Visual: Repository + Namespace Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│              REPOSITORY & NAMESPACE WORKFLOW                      │
└──────────────────────────────────────────────────────────────────┘

                        PUBLIC REPOS                PRIVATE REPO
                        ────────────                ────────────
                       ┌────────────┐             ┌────────────┐
                       │  Bitnami   │             │  Company   │
                       │ prometheus │             │   Charts   │
                       │  grafana   │             │            │
                       └─────┬──────┘             └─────┬──────┘
                             │                          │
                             └──────────┬───────────────┘
                                        │
                                        ▼
                                ┌───────────────┐
                                │ helm repo add │
                                │ helm repo     │
                                │   update      │
                                └───────┬───────┘
                                        │
                                        ▼
                                ┌───────────────┐
                                │ helm search   │
                                │ helm install  │
                                └───────┬───────┘
                                        │
              ┌─────────────────────────┼─────────────────────────┐
              │                         │                         │
              ▼                         ▼                         ▼
    ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
    │  Namespace: dev │       │ Namespace: stg  │       │ Namespace: prod │
    │  ─────────────  │       │  ────────────   │       │  ─────────────  │
    │                 │       │                 │       │                 │
    │  my-app (v2.1)  │       │  my-app (v2.0)  │       │  my-app (v1.9)  │
    │  redis          │       │  redis          │       │  redis          │
    │  prometheus     │       │  prometheus     │       │  prometheus     │
    │                 │       │                 │       │                 │
    └─────────────────┘       └─────────────────┘       └─────────────────┘
```

---

## Key Takeaways

### Repositories
1. **Repository = Chart store** – HTTP server with index.yaml and .tgz files
2. **`helm repo add`** – Add a repository to your local config
3. **`helm repo update`** – Refresh the chart catalog
4. **Artifact Hub** – Search for charts across all repositories
5. **OCI support** – Modern way using container registries

### Namespaces
1. **Namespace = Virtual cluster** – Isolation for environments/teams
2. **Always specify namespace** – Don't rely on default
3. **Use `--create-namespace`** – For CI/CD pipelines
4. **Same release name OK** – In different namespaces
5. **Cross-namespace DNS** – `<service>.<namespace>.svc.cluster.local`

---

**Next: Hands-on with repositories and namespaces!**
