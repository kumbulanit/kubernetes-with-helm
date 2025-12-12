# 06 – Testing & Debugging Charts (Theory)

**Estimated reading time:** 15 minutes

---

## Why Test and Debug?

### The Simple Explanation

Imagine building a house:
- Would you wait until it's completely built to check if the walls are straight?
- No! You check at every step.

Helm charts are the same:
- Test early and often
- Catch mistakes before they affect users
- Debug problems when they occur

---

### The Technical Reasons

1. **Prevent production issues** – Catch configuration errors before deployment
2. **Save time** – Fix problems in development, not at 2 AM
3. **Improve confidence** – Know your charts work before releasing
4. **Enable CI/CD** – Automated testing for chart changes

---

## Testing Tools Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                    HELM TESTING TOOLKIT                           │
└──────────────────────────────────────────────────────────────────┘

     STATIC ANALYSIS              RENDERING                 RUNTIME
     ───────────────              ─────────                 ───────
    ┌─────────────┐            ┌─────────────┐           ┌─────────────┐
    │  helm lint  │            │helm template│           │  helm test  │
    │             │            │             │           │             │
    │ Check chart │            │Render YAML  │           │ Run test    │
    │ structure   │            │without      │           │ pods in     │
    │ and syntax  │            │installing   │           │ cluster     │
    └─────────────┘            └─────────────┘           └─────────────┘
           │                          │                        │
           ▼                          ▼                        ▼
    ┌─────────────┐            ┌─────────────┐           ┌─────────────┐
    │ Quick check │            │ Preview     │           │ Validate    │
    │ No cluster  │            │ Full YAML   │           │ deployment  │
    │ required    │            │ Check logic │           │ works       │
    └─────────────┘            └─────────────┘           └─────────────┘
```

---

## Tool 1: helm lint

### What It Does

`helm lint` checks your chart for:
- Valid chart structure
- Required files exist
- YAML syntax errors
- Best practice violations

### Usage

```bash
helm lint <chart-path>
```

### Example

```bash
helm lint ./my-webapp
```

**Possible outputs:**

**Good chart:**
```
==> Linting ./my-webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

**Chart with errors:**
```
==> Linting ./my-webapp
[ERROR] Chart.yaml: version is required
[ERROR] templates/deployment.yaml: unable to parse YAML: ...
[WARNING] templates/service.yaml: object name does not conform to Kubernetes naming requirements

1 chart(s) linted, 1 chart(s) failed
```

### Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| `ERROR` | Critical issue, chart won't work | Must fix |
| `WARNING` | Best practice violation | Should fix |
| `INFO` | Suggestion for improvement | Optional |

### Lint with Values

Test with specific values:

```bash
helm lint ./my-webapp --values prod-values.yaml
```

This validates the chart with your production configuration.

---

## Tool 2: helm template

### What It Does

`helm template` renders your templates to YAML without installing anything.

This lets you:
- Preview exact output
- Verify values substitution
- Check conditional logic
- Debug template issues

### Usage

```bash
helm template <release-name> <chart-path>
```

### Example

```bash
helm template my-release ./my-webapp
```

**Output:**
```yaml
---
# Source: my-webapp/templates/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-release-my-webapp-html
...
---
# Source: my-webapp/templates/service.yaml
apiVersion: v1
kind: Service
...
---
# Source: my-webapp/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
...
```

### Template with Values Override

```bash
helm template my-release ./my-webapp --set replicaCount=5
```

Verify that `replicas: 5` appears in the output.

### Template Specific Files

Only render one template:

```bash
helm template my-release ./my-webapp --show-only templates/deployment.yaml
```

### Validate Against Kubernetes

Check if the output is valid Kubernetes YAML:

```bash
helm template my-release ./my-webapp | kubectl apply --dry-run=client -f -
```

**Expected output:**
```
configmap/my-release-my-webapp-html created (dry run)
service/my-release-my-webapp created (dry run)
deployment.apps/my-release-my-webapp created (dry run)
```

---

## Tool 3: --dry-run (Install/Upgrade)

### What It Does

The `--dry-run` flag simulates an install/upgrade:
- Connects to cluster
- Validates configuration
- Shows what would be deployed
- Does NOT actually deploy

### Usage

```bash
helm install my-release ./my-webapp --dry-run
```

### Difference from helm template

| Feature | `helm template` | `helm install --dry-run` |
|---------|----------------|--------------------------|
| Requires cluster | No | Yes |
| Validates against API | No | Yes |
| Shows hooks | Limited | Full |
| Release name generation | No | Yes |
| Server-side validation | No | Yes |

**Use `helm template`** for quick local testing.
**Use `--dry-run`** for full validation before production deploy.

### Debug Mode

Add `--debug` for extra information:

```bash
helm install my-release ./my-webapp --dry-run --debug
```

This shows:
- Computed values
- Rendered templates
- Hook definitions
- Full debug output

---

## Tool 4: helm test

### What It Does

`helm test` runs test pods defined in your chart to verify the installation works correctly.

### How It Works

1. You define test pods in `templates/tests/`
2. These pods run checks (HTTP requests, connections, etc.)
3. If pods succeed (exit 0), test passes
4. If pods fail (exit non-0), test fails

### Creating a Test

**File:** `templates/tests/test-connection.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-webapp.fullname" . }}-test-connection"
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test                    # This makes it a test
spec:
  containers:
    - name: wget
      image: busybox
      command: ['wget']
      args: ['{{ include "my-webapp.fullname" . }}:{{ .Values.service.port }}']
  restartPolicy: Never
```

**Key parts:**
- `helm.sh/hook: test` – Marks this as a test pod
- The container runs a command (wget in this case)
- `restartPolicy: Never` – Don't restart on failure
- If wget succeeds, test passes

### Running Tests

```bash
# First install the chart
helm install my-release ./my-webapp

# Then run tests
helm test my-release
```

**Expected output (success):**
```
NAME: my-release
LAST DEPLOYED: Thu Jan 15 16:00:00 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE:     my-release-my-webapp-test-connection
Last Started:   Thu Jan 15 16:00:05 2024
Last Completed: Thu Jan 15 16:00:10 2024
Phase:          Succeeded
```

**Expected output (failure):**
```
TEST SUITE:     my-release-my-webapp-test-connection
Last Started:   Thu Jan 15 16:00:05 2024
Last Completed: Thu Jan 15 16:00:15 2024
Phase:          Failed
Error: pod my-release-my-webapp-test-connection failed
```

### Multiple Tests

You can have multiple test files:

```
templates/tests/
├── test-connection.yaml    # Test HTTP connectivity
├── test-database.yaml      # Test database connection
└── test-config.yaml        # Test configuration loaded
```

Each runs separately and reports pass/fail.

---

## Debugging Techniques

### 1. Debug Template Rendering

**Use `{{ printf }}` for debugging:**

```yaml
# Add this temporarily to see a value
{{ printf "DEBUG: replicaCount is %v" .Values.replicaCount }}
```

Run `helm template` to see the output.

**Remove before committing!**

### 2. Check Template Logic

Test conditional logic:

```yaml
{{- if .Values.ingress.enabled }}
# This will be rendered
{{- else }}
# This will NOT be rendered
{{- end }}
```

Run `helm template` with different values:

```bash
# Without ingress
helm template my-release ./my-webapp --set ingress.enabled=false

# With ingress
helm template my-release ./my-webapp --set ingress.enabled=true
```

### 3. Inspect Running Release

**View the manifest (what was deployed):**
```bash
helm get manifest my-release
```

**View the values (what configuration was used):**
```bash
helm get values my-release --all
```

**View everything:**
```bash
helm get all my-release
```

### 4. Check Kubernetes Resources

**View pods and their status:**
```bash
kubectl get pods -l app.kubernetes.io/instance=my-release
```

**Describe a pod (detailed info + events):**
```bash
kubectl describe pod <pod-name>
```

**View logs:**
```bash
kubectl logs <pod-name>
kubectl logs -l app.kubernetes.io/instance=my-release
```

### 5. Common Debugging Commands

```bash
# See all resources created by a release
kubectl get all -l app.kubernetes.io/instance=my-release

# Watch pods come up
kubectl get pods -w

# Get events (cluster-wide, useful for errors)
kubectl get events --sort-by='.lastTimestamp'

# Check if a value was set correctly
helm get values my-release | grep replicaCount
```

---

## Common Problems and Solutions

### Problem 1: YAML Indentation Error

**Symptom:**
```
Error: YAML parse error: ...
```

**Cause:** Incorrect whitespace in templates.

**Solution:** Use `nindent` for proper indentation:
```yaml
# Wrong
labels:
{{ include "mychart.labels" . }}

# Correct
labels:
{{- include "mychart.labels" . | nindent 4 }}
```

### Problem 2: Nil Pointer Error

**Symptom:**
```
Error: template: mychart/templates/deployment.yaml:10:18:
executing "mychart/templates/deployment.yaml" at <.Values.image.tag>:
nil pointer evaluating interface {}.tag
```

**Cause:** Trying to access a value that doesn't exist.

**Solution:** Use `default` or check if it exists:
```yaml
# Use default
image: "{{ .Values.image.repository }}:{{ default "latest" .Values.image.tag }}"

# Or check with if
{{- if .Values.image }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
{{- end }}
```

### Problem 3: Resource Name Too Long

**Symptom:**
```
Error: release name "my-very-long-release-name-that-exceeds-limits" is invalid
```

**Cause:** Kubernetes names must be ≤ 63 characters.

**Solution:** Truncate names in helpers:
```yaml
{{- define "mychart.fullname" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
```

### Problem 4: Hook Failed

**Symptom:**
```
Error: pre-install hook failed: Job failed: BackoffLimitExceeded
```

**Cause:** A pre-install hook (like database migration) failed.

**Solution:** Check the hook job logs:
```bash
kubectl logs job/<release-name>-<hook-name>
```

---

## Testing Best Practices

### 1. Always Lint Before Committing

```bash
# Add to your workflow
helm lint ./my-webapp
```

### 2. Template Before Installing

```bash
# Preview what will be deployed
helm template my-release ./my-webapp | less
```

### 3. Use --dry-run for Production Deployments

```bash
# Validate against production cluster
helm upgrade --install my-release ./my-webapp \
  --namespace production \
  -f production-values.yaml \
  --dry-run
```

### 4. Write Test Pods

Create tests for critical functionality:
- Connection tests
- Configuration validation
- Health endpoint checks

### 5. CI/CD Pipeline Testing

```bash
# Typical CI pipeline
helm lint ./my-webapp
helm template my-release ./my-webapp | kubectl apply --dry-run=client -f -
# Deploy to test namespace
helm install my-release ./my-webapp -n test
helm test my-release -n test
# Clean up
helm uninstall my-release -n test
```

---

## Visual: Testing Workflow

```
┌──────────────────────────────────────────────────────────────────┐
│                    CHART TESTING WORKFLOW                         │
└──────────────────────────────────────────────────────────────────┘

       DEVELOPMENT              PRE-DEPLOY              POST-DEPLOY
       ───────────              ──────────              ───────────
    ┌─────────────┐          ┌─────────────┐         ┌─────────────┐
    │ Edit Chart  │          │   --dry-run │         │ helm test   │
    │             │          │             │         │             │
    └──────┬──────┘          └──────┬──────┘         └──────┬──────┘
           │                        │                       │
           ▼                        │                       │
    ┌─────────────┐                 │                       │
    │ helm lint   │                 │                       │
    │             │                 │                       │
    │ Quick       │                 │                       │
    │ syntax      │                 │                       │
    │ check       │                 │                       │
    └──────┬──────┘                 │                       │
           │                        │                       │
           ▼                        │                       │
    ┌─────────────┐                 │                       │
    │helm template│                 │                       │
    │             │                 │                       │
    │ Preview     │                 │                       │
    │ rendered    │                 │                       │
    │ YAML        │                 │                       │
    └──────┬──────┘                 │                       │
           │                        │                       │
           │     ┌──────────────────┘                       │
           │     │                                          │
           ▼     ▼                                          │
         PASS?────────▶ YES ────────▶ DEPLOY ──────────────▶│
           │                          helm install          │
          NO                          helm upgrade          │
           │                                                │
           ▼                                                │
         FIX                                                │
         ISSUES ◀────────────────────────────────────── PASS?
                                                        NO = FIX
```

---

## Key Takeaways

1. **`helm lint`** – Quick syntax and structure check
2. **`helm template`** – Preview rendered YAML without cluster
3. **`--dry-run`** – Full validation with cluster connection
4. **`helm test`** – Runtime tests with test pods
5. **Debug with `--debug`** – See computed values and full output
6. **Inspect with `helm get`** – View manifest, values, notes
7. **Check Kubernetes** – Use kubectl logs, describe, get events
8. **Test early and often** – Catch problems before production

---

**Next: Hands-on testing and debugging!**
