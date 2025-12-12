# 03 – Creating Helm Charts (Theory)

**Estimated reading time:** 15 minutes

---

## What is a Helm Chart?

### The Simple Explanation

Think of a Helm chart like a **recipe in a cookbook**:

- A **recipe** tells you what ingredients you need and how to combine them
- A **Helm chart** tells Kubernetes what resources you need and how to configure them

When you follow a recipe, you might adjust it (less salt, more garlic). Similarly, with a Helm chart, you can adjust configuration values (different port, more replicas).

---

### The Technical Definition

A Helm chart is a **collection of files** that describe a set of Kubernetes resources. It packages all the YAML templates, default values, and metadata needed to deploy an application.

---

## Why Create Your Own Charts?

### Scenario 1: No Existing Chart

You've built a custom application. There's no public chart for it. You need to create one to deploy it to Kubernetes.

### Scenario 2: Company Standards

Your organization has specific requirements (labels, annotations, security settings) that aren't in public charts.

### Scenario 3: Simplified Deployment

Instead of managing 10 separate YAML files, you can bundle them into one chart that's easy to install and upgrade.

### Scenario 4: Reusability

Create once, deploy many times with different configurations.

---

## Chart Directory Structure

When you create a chart, Helm generates a specific folder structure:

```
mychart/
├── Chart.yaml          # Required: Chart metadata
├── values.yaml         # Required: Default configuration values
├── charts/             # Optional: Dependencies (subcharts)
├── templates/          # Required: Template files
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── NOTES.txt       # Optional: Post-install instructions
│   ├── _helpers.tpl    # Optional: Reusable template snippets
│   └── tests/          # Optional: Test files
│       └── test-connection.yaml
├── .helmignore         # Optional: Patterns to ignore when packaging
└── README.md           # Optional: Documentation
```

### Let's Understand Each File:

---

### 1. Chart.yaml (Required)

The **identity card** of your chart. Contains metadata about the chart itself.

**Example:**
```yaml
apiVersion: v2                    # Helm 3 uses v2
name: mychart                     # Chart name (must match folder name)
description: A Helm chart for my application
type: application                 # "application" or "library"
version: 0.1.0                    # Chart version (you control this)
appVersion: "1.0.0"               # Version of the app being deployed
keywords:
  - web
  - nginx
maintainers:
  - name: Your Name
    email: you@example.com
```

**Key fields explained:**
- `apiVersion: v2` – Always "v2" for Helm 3 charts
- `name` – How users reference your chart
- `version` – The chart package version (follows semantic versioning)
- `appVersion` – The version of the actual application (nginx 1.25, your-app 2.1, etc.)

**Why two versions?**
- Chart version: Changes when you modify the chart (new features, bug fixes)
- App version: Changes when you update the application inside

---

### 2. values.yaml (Required)

The **default settings** for your chart. Users can override any of these.

**Example:**
```yaml
# Container image configuration
image:
  repository: nginx       # Docker image name
  tag: "1.25"            # Image version
  pullPolicy: IfNotPresent

# Deployment configuration
replicaCount: 1          # Number of pods

# Service configuration
service:
  type: ClusterIP        # ClusterIP, NodePort, or LoadBalancer
  port: 80               # Port the service listens on

# Resource limits
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Feature toggles
ingress:
  enabled: false         # Set to true to create an Ingress
```

**Why values.yaml matters:**
1. Documents all configurable options in one place
2. Provides sensible defaults
3. Users can override any value without editing templates

---

### 3. templates/ Directory (Required)

Contains **Go template files** that generate Kubernetes YAML.

**How templating works:**

Instead of hardcoding values, you use placeholders:

**Regular Kubernetes YAML (hardcoded):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
```

**Helm Template (dynamic):**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-app
spec:
  replicas: {{ .Values.replicaCount }}
```

The `{{ ... }}` syntax inserts values dynamically:
- `{{ .Release.Name }}` → The name of the release (e.g., "prod-nginx")
- `{{ .Values.replicaCount }}` → The value from values.yaml (e.g., 3)

---

### 4. _helpers.tpl (Common Patterns)

A special file containing **reusable template snippets**. The underscore prefix tells Helm not to output this file directly.

**Example:**
```yaml
{{/*
Generate a standard name for resources
*/}}
{{- define "mychart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate standard labels
*/}}
{{- define "mychart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
```

**Usage in other templates:**
```yaml
metadata:
  name: {{ include "mychart.name" . }}
  labels:
    {{- include "mychart.labels" . | nindent 4 }}
```

**Why use helpers:**
- DRY (Don't Repeat Yourself) – Define once, use everywhere
- Consistency – All resources get the same labels
- Maintenance – Change in one place, updates everywhere

---

### 5. NOTES.txt (Post-Install Instructions)

Displayed after a successful install. Uses the same templating syntax.

**Example:**
```
Congratulations! {{ .Release.Name }} has been deployed.

To access your application:

{{- if eq .Values.service.type "NodePort" }}
  Get the NodePort:
  kubectl get svc {{ .Release.Name }} -o jsonpath='{.spec.ports[0].nodePort}'
{{- else if eq .Values.service.type "LoadBalancer" }}
  Wait for the external IP:
  kubectl get svc {{ .Release.Name }} -w
{{- else }}
  Run port-forward:
  kubectl port-forward svc/{{ .Release.Name }} 8080:{{ .Values.service.port }}
{{- end }}
```

---

### 6. .helmignore

Like `.gitignore`, specifies files to exclude when packaging the chart.

**Example:**
```
# Patterns to ignore when building packages
.git
.gitignore
*.swp
*.bak
*.tmp
.DS_Store
```

---

## Template Syntax Deep Dive

### Basic Syntax

| Syntax | Description | Example |
|--------|-------------|---------|
| `{{ .Values.x }}` | Access values.yaml | `{{ .Values.replicaCount }}` |
| `{{ .Release.Name }}` | Release name | `{{ .Release.Name }}` |
| `{{ .Chart.Name }}` | Chart name | `{{ .Chart.Name }}` |
| `{{ .Release.Namespace }}` | Target namespace | `{{ .Release.Namespace }}` |

### Built-in Objects

**Available in every template:**

```
.Values      → Contents of values.yaml (and any overrides)
.Release     → Information about the release
  .Name      → Release name
  .Namespace → Namespace
  .Revision  → Revision number
  .IsUpgrade → true if this is an upgrade
  .IsInstall → true if this is an install
.Chart       → Contents of Chart.yaml
  .Name      → Chart name
  .Version   → Chart version
.Files       → Access non-special files in the chart
.Capabilities → Info about the Kubernetes cluster
```

### Conditional Logic

**if/else:**
```yaml
{{- if .Values.ingress.enabled }}
apiVersion: networking.k8s.io/v1
kind: Ingress
# ... ingress configuration
{{- end }}
```

**if/else if/else:**
```yaml
{{- if eq .Values.env "production" }}
replicas: 3
{{- else if eq .Values.env "staging" }}
replicas: 2
{{- else }}
replicas: 1
{{- end }}
```

### Loops

**range (for-each):**
```yaml
{{- range .Values.ports }}
- port: {{ .port }}
  name: {{ .name }}
{{- end }}
```

**With values.yaml:**
```yaml
ports:
  - port: 80
    name: http
  - port: 443
    name: https
```

**Output:**
```yaml
- port: 80
  name: http
- port: 443
  name: https
```

### Whitespace Control

The `-` inside `{{- }}` and `{{ -}}` controls whitespace:

- `{{-` removes whitespace/newlines before
- `-}}` removes whitespace/newlines after

**Without whitespace control:**
```yaml
metadata:
  labels:
{{ include "mychart.labels" . }}
```
May produce extra blank lines.

**With whitespace control:**
```yaml
metadata:
  labels:
{{- include "mychart.labels" . | nindent 4 }}
```
Produces clean output.

---

## Functions and Pipelines

Helm includes many useful functions.

### Common Functions

| Function | Description | Example |
|----------|-------------|---------|
| `default` | Provide default value | `{{ default "nginx" .Values.image }}` |
| `quote` | Wrap in quotes | `{{ .Values.name \| quote }}` |
| `upper` | Uppercase | `{{ .Values.name \| upper }}` |
| `lower` | Lowercase | `{{ .Values.name \| lower }}` |
| `trunc` | Truncate string | `{{ .Values.name \| trunc 63 }}` |
| `trim` | Remove whitespace | `{{ .Values.name \| trim }}` |
| `indent` | Add indentation | `{{ .Values.config \| indent 4 }}` |
| `nindent` | Newline + indent | `{{ .Values.config \| nindent 4 }}` |
| `toYaml` | Convert to YAML | `{{ .Values.resources \| toYaml }}` |

### Pipeline Syntax

Functions can be chained with `|` (pipe):

```yaml
# Start with a value, then apply functions left-to-right
name: {{ .Values.name | default "myapp" | upper | quote }}

# Equivalent to: quote(upper(default("myapp", .Values.name)))
```

---

## Visual: Chart Creation Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    CHART CREATION WORKFLOW                        │
└──────────────────────────────────────────────────────────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Create     │     │   Define    │     │   Write     │
│  Structure  │ ──▶ │   Values    │ ──▶ │  Templates  │
│             │     │             │     │             │
│ helm create │     │ values.yaml │     │ templates/  │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Test &    │     │   Lint &    │     │   Package   │
│   Debug     │ ◀── │   Validate  │ ◀── │   Chart     │
│             │     │             │     │             │
│ helm install│     │ helm lint   │     │ helm package│
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## Chart Design Best Practices

### 1. Use Meaningful Defaults

```yaml
# Good: Works out of the box
replicaCount: 1
service:
  type: ClusterIP
  port: 80

# Bad: Requires user to set everything
replicaCount: null   # Forces user to set this
```

### 2. Make Things Toggleable

```yaml
# Allow users to enable/disable features
ingress:
  enabled: false     # Disabled by default

autoscaling:
  enabled: false     # Disabled by default
  minReplicas: 1
  maxReplicas: 10
```

### 3. Use Consistent Naming

```yaml
# Use kebab-case for chart names: my-app
# Use camelCase for values: replicaCount, servicePort
```

### 4. Add Comments

```yaml
# -- Number of replicas for the deployment
replicaCount: 1

# -- Container image repository
image:
  repository: nginx
  # -- Image tag (overrides Chart appVersion)
  tag: ""
```

### 5. Validate with Schema

Create `values.schema.json` to validate user inputs:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "properties": {
    "replicaCount": {
      "type": "integer",
      "minimum": 1
    }
  }
}
```

---

## Common Patterns

### Pattern 1: Full Resource Name

```yaml
{{- define "mychart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
```

**Result:** `prod-nginx-mychart` → Unique names per release

### Pattern 2: Standard Labels

```yaml
{{- define "mychart.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "mychart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

### Pattern 3: Optional Resources

```yaml
{{- if .Values.serviceAccount.create -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "mychart.serviceAccountName" . }}
{{- end }}
```

---

## Key Takeaways

1. **Chart = Package** – Contains everything needed to deploy an application
2. **values.yaml = Configuration** – Sensible defaults users can override
3. **templates/ = Dynamic YAML** – Go templates that generate Kubernetes resources
4. **Templating = Power** – Conditionals, loops, functions make charts flexible
5. **helpers = Reusability** – Define once, use throughout the chart
6. **NOTES.txt = UX** – Help users know what to do after installation

---

## Chart Dependencies

### What are Chart Dependencies?

When your application needs other services (like a database), you can include them as dependencies. Instead of creating one massive chart, you can:
- Split applications into separate charts
- Reuse existing charts (like MySQL, Redis)
- Manage complex deployments as a single unit

### Why Use Dependencies?

```
┌──────────────────────────────────────────────────────────────────┐
│                    WITHOUT DEPENDENCIES                           │
└──────────────────────────────────────────────────────────────────┘

  Manual Installation:
  
  1. helm install mysql bitnami/mysql -n myapp
  2. helm install redis bitnami/redis -n myapp  
  3. helm install myapp ./myapp-chart -n myapp
  
  Problems:
  - Must remember the order
  - Must manually track which releases belong together
  - Cleanup is error-prone

┌──────────────────────────────────────────────────────────────────┐
│                     WITH DEPENDENCIES                             │
└──────────────────────────────────────────────────────────────────┘

  Single Command:
  
  helm install myapp ./myapp-chart -n myapp
  
  Benefits:
  - One command installs everything
  - All resources tracked as one release
  - One command to upgrade/rollback/uninstall
```

### Defining Dependencies in Chart.yaml

**Modern approach (Helm 3):**
```yaml
# Chart.yaml
apiVersion: v2
name: my-app
version: 1.0.0
dependencies:
  - name: mysql
    version: "9.0.0"
    repository: "https://charts.bitnami.com/bitnami"
  - name: redis
    version: "18.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled    # Optional: only include if enabled
```

### Managing Dependencies

**Download dependencies:**
```bash
helm dependency update ./my-app
```

This downloads the dependency charts to `charts/` folder and creates `Chart.lock`:

```
my-app/
├── Chart.yaml
├── Chart.lock              # Locks dependency versions
├── charts/                 # Downloaded dependencies
│   ├── mysql-9.0.0.tgz
│   └── redis-18.0.0.tgz
├── values.yaml
└── templates/
```

**Build dependencies (from lock file):**
```bash
helm dependency build ./my-app
```

### Configuring Dependencies via values.yaml

Override subchart values by nesting under the dependency name:

```yaml
# values.yaml for parent chart
replicaCount: 1
image:
  repository: my-app
  tag: "1.0"

# Configuration for mysql subchart
mysql:
  auth:
    rootPassword: "secretpassword"
    database: "myapp"
  primary:
    persistence:
      size: 10Gi

# Configuration for redis subchart
redis:
  enabled: true    # Controls the condition
  auth:
    password: "redispassword"
```

### Dependency Workflow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                    DEPENDENCY WORKFLOW                            │
└──────────────────────────────────────────────────────────────────┘

  1. Define Dependencies
     ─────────────────
     ┌─────────────────┐
     │   Chart.yaml    │
     │                 │
     │  dependencies:  │
     │   - mysql       │
     │   - redis       │
     └────────┬────────┘
              │
  2. Download Dependencies
     ─────────────────────
              │
              ▼
     ┌─────────────────┐     ┌─────────────────┐
     │ helm dependency │ ──▶ │   charts/       │
     │     update      │     │  mysql-9.0.tgz  │
     └─────────────────┘     │  redis-18.0.tgz │
              │              └─────────────────┘
              │
  3. Install Parent Chart
     ────────────────────
              │
              ▼
     ┌─────────────────┐     ┌─────────────────────────────┐
     │  helm install   │ ──▶ │   Kubernetes Cluster         │
     │   myapp ./myapp │     │                              │
     └─────────────────┘     │  ┌─────────┐  ┌─────────┐   │
                             │  │ my-app  │  │  mysql  │   │
                             │  └─────────┘  └─────────┘   │
                             │               ┌─────────┐   │
                             │               │  redis  │   │
                             │               └─────────┘   │
                             └─────────────────────────────┘
```

### Dependency Conditions and Tags

**Conditionally include dependencies:**

```yaml
# Chart.yaml
dependencies:
  - name: redis
    version: "18.0.0"
    repository: "https://charts.bitnami.com/bitnami"
    condition: redis.enabled
    tags:
      - cache
```

```yaml
# values.yaml
redis:
  enabled: false    # Set to true to include redis

# Or use tags
tags:
  cache: true       # Enable all charts tagged "cache"
```

### Accessing Subchart Values in Templates

To reference subchart services from your parent chart templates:

```yaml
# In parent chart's deployment.yaml
env:
  - name: DATABASE_HOST
    value: "{{ .Release.Name }}-mysql"
  - name: DATABASE_USER
    value: "{{ .Values.mysql.auth.username }}"
  - name: REDIS_HOST
    value: "{{ .Release.Name }}-redis-master"
```

### Dependency Best Practices

1. **Always pin versions** - Use exact versions, not ranges
   ```yaml
   version: "9.0.0"      # Good
   version: ">=9.0.0"    # Risky
   ```

2. **Use conditions** - Don't force dependencies
   ```yaml
   condition: redis.enabled
   ```

3. **Document subchart values** - Show users what they can configure

4. **Test with and without dependencies**

5. **Keep dependencies minimal** - Only include what you truly need

---

**Next: We'll create our own chart from scratch!**
