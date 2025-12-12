# 06 – Testing & Debugging Charts (Lab)

**Objective:** Practice using Helm's testing and debugging tools to validate charts and troubleshoot issues.

**Estimated duration:** 25–30 minutes

**Prerequisites:** Helm installed, Minikube running, my-webapp chart from Module 03.

---

## What You Will Do

1. Use helm lint to check chart structure
2. Use helm template to preview rendered YAML
3. Use --dry-run to validate before installing
4. Create and run test pods
5. Debug intentional errors
6. Practice troubleshooting techniques

---

## Testing Pipeline Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    HELM TESTING PIPELINE                         │
└─────────────────────────────────────────────────────────────────┘

    DEVELOPMENT PHASE              VALIDATION PHASE              RUNTIME
    ─────────────────              ────────────────              ───────

    ┌─────────────┐            ┌─────────────┐            ┌─────────────┐
    │  Edit Chart │            │  --dry-run  │            │  helm test  │
    │   Files     │            │  --debug    │            │   (pods)    │
    └──────┬──────┘            └──────┬──────┘            └──────┬──────┘
           │                          │                          │
           ▼                          │                          │
    ┌─────────────┐                   │                          │
    │  helm lint  │                   │                          │
    │ (syntax)    │                   │                          │
    └──────┬──────┘                   │                          │
           │                          │                          │
           ▼                          │                          │
    ┌─────────────┐                   │                          │
    │   helm      │                   │                          │
    │  template   │                   │                          │
    │  (render)   │                   │                          │
    └──────┬──────┘                   │                          │
           │                          │                          │
           │    ┌─────────────────────┘                          │
           │    │                                                │
           ▼    ▼                                                ▼
         PASS? ──────▶ YES ──────▶ DEPLOY ──────▶ PASS? ──────▶ DONE!
           │                                        │
          NO                                       NO
           │                                        │
           ▼                                        ▼
         FIX ◀─────────────────────────────────── FIX
```

---

## Preparation

**Navigate to your chart:**
```bash
cd ~/helm-training
ls my-webapp
```

Make sure you have the my-webapp chart from Module 03.

---

## Part 1: Linting Charts

### Step 1: Basic Lint

**Run lint on your chart:**
```bash
helm lint my-webapp
```

**Expected output:**
```
==> Linting my-webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

**What this tells you:**
- ✅ Chart passed (0 failed)
- ℹ️ INFO: icon is recommended (optional suggestion)

---

### Step 2: Create a Lint Error (Intentional)

Let's break something to see lint catch it.

**Make a backup and corrupt values.yaml:**
```bash
cp my-webapp/values.yaml my-webapp/values.yaml.bak
echo "this is: not: valid: yaml: [" >> my-webapp/values.yaml
```

**Run lint again:**
```bash
helm lint my-webapp
```

**Expected output:**
```
==> Linting my-webapp
[ERROR] values.yaml: unable to parse YAML: yaml: line X: ...

Error: 1 chart(s) linted, 1 chart(s) failed
```

**Lint caught the error!**

**Restore the file:**
```bash
mv my-webapp/values.yaml.bak my-webapp/values.yaml
```

---

### Step 3: Lint with Values File

**Create a test values file:**
```bash
cat > test-values.yaml << 'EOF'
replicaCount: 3
welcomeMessage: "Testing Lint"
service:
  type: NodePort
EOF
```

**Lint with this values file:**
```bash
helm lint my-webapp -f test-values.yaml
```

**Expected output:**
```
==> Linting my-webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

This validates that your chart works with specific value overrides.

---

## Part 2: Template Rendering

### Step 4: Basic Template Rendering

**Render all templates:**
```bash
helm template my-release my-webapp
```

**This outputs all rendered YAML.** Let's examine specific parts:

**View only the deployment:**
```bash
helm template my-release my-webapp --show-only templates/deployment.yaml
```

**Expected output:**
```yaml
---
# Source: my-webapp/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-release-my-webapp
...
spec:
  replicas: 1
...
```

---

### Step 5: Template with Value Overrides

**Change replica count:**
```bash
helm template my-release my-webapp \
  --set replicaCount=5 \
  --show-only templates/deployment.yaml | grep "replicas:"
```

**Expected output:**
```
  replicas: 5
```

The value was correctly substituted!

---

### Step 6: Verify ConfigMap Content

**Check the welcome message:**
```bash
helm template my-release my-webapp \
  --set welcomeMessage="Testing Template Render" \
  --show-only templates/configmap.yaml | grep -A 3 "index.html"
```

**You should see your custom message in the HTML.**

---

### Step 7: Validate Against Kubernetes API

**Send rendered YAML to kubectl for validation:**
```bash
helm template my-release my-webapp | kubectl apply --dry-run=client -f -
```

**Expected output:**
```
configmap/my-release-my-webapp-html created (dry run)
service/my-release-my-webapp created (dry run)
deployment.apps/my-release-my-webapp created (dry run)
```

**(dry run)** means nothing was actually created - just validated.

---

## Part 3: Dry Run Installation

### Step 8: Dry Run with Debug

**Run install with --dry-run and --debug:**
```bash
helm install my-release my-webapp --dry-run --debug 2>&1 | head -n 50
```

**What you'll see:**
1. USER-SUPPLIED VALUES (your overrides)
2. COMPUTED VALUES (all merged values)
3. HOOKS (pre-install, post-install operations)
4. MANIFEST (rendered Kubernetes YAML)

---

### Step 9: Dry Run with Values File

**Use your test values:**
```bash
helm install my-release my-webapp \
  -f test-values.yaml \
  --dry-run 2>&1 | head -n 30
```

**Check computed values:**
```bash
helm install my-release my-webapp \
  -f test-values.yaml \
  --dry-run --debug 2>&1 | grep -A 10 "COMPUTED VALUES"
```

You should see `replicaCount: 3` from your values file.

---

## Part 4: Creating Tests

### Step 10: Create Tests Directory

**Create the tests folder:**
```bash
mkdir -p my-webapp/templates/tests
```

---

### Step 11: Create a Connection Test

```
┌─────────────────────────────────────────────────────────────────┐
│                    HELM TEST POD FLOW                            │
└─────────────────────────────────────────────────────────────────┘

    helm test my-release
           │
           ▼
    ┌─────────────────┐      ┌─────────────────┐
    │   Test Pod      │      │   Application   │
    │  (busybox)      │─────▶│     Service     │
    │                 │ wget │                 │
    │  Exit Code:     │      │  Response: 200  │
    │    0 = PASS     │◀─────│                 │
    │    1 = FAIL     │      │                 │
    └────────┬────────┘      └─────────────────┘
             │
             ▼
    ┌─────────────────┐
    │  Test Result    │
    │                 │
    │  Phase: Success │
    │  or             │
    │  Phase: Failed  │
    └─────────────────┘
```

**Create a test that checks if the service is reachable:**
```bash
cat > my-webapp/templates/tests/test-connection.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-webapp.fullname" . }}-test-connection"
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: wget
      image: busybox:1.36
      command: ['sh', '-c']
      args:
        - |
          echo "Testing connection to {{ include "my-webapp.fullname" . }}:{{ .Values.service.port }}"
          wget --spider --timeout=5 {{ include "my-webapp.fullname" . }}:{{ .Values.service.port }}
          if [ $? -eq 0 ]; then
            echo "SUCCESS: Service is reachable"
            exit 0
          else
            echo "FAILURE: Service is not reachable"
            exit 1
          fi
  restartPolicy: Never
EOF
```

**What this test does:**
1. Runs as a pod with the `test` hook annotation
2. Uses wget to check if the service responds
3. Exits 0 (pass) if reachable, 1 (fail) if not
4. `hook-delete-policy: hook-succeeded` cleans up after success

---

### Step 12: Create a Content Test

**Create a test that verifies the welcome message appears:**
```bash
cat > my-webapp/templates/tests/test-content.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "my-webapp.fullname" . }}-test-content"
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: curl
      image: curlimages/curl:8.4.0
      command: ['sh', '-c']
      args:
        - |
          echo "Checking content from {{ include "my-webapp.fullname" . }}"
          CONTENT=$(curl -s {{ include "my-webapp.fullname" . }}:{{ .Values.service.port }})
          if echo "$CONTENT" | grep -q "{{ .Values.welcomeMessage }}"; then
            echo "SUCCESS: Welcome message found"
            exit 0
          else
            echo "FAILURE: Welcome message not found"
            echo "Expected: {{ .Values.welcomeMessage }}"
            echo "Got: $CONTENT"
            exit 1
          fi
  restartPolicy: Never
EOF
```

---

### Step 13: Lint the Updated Chart

**Make sure the tests are valid:**
```bash
helm lint my-webapp
```

**Expected output:**
```
==> Linting my-webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

---

### Step 14: Install and Run Tests

**Install the chart:**
```bash
helm install test-release my-webapp
```

**Wait for pod to be ready:**
```bash
kubectl get pods -w
```

Press `Ctrl+C` when the pod shows `1/1 Running`.

**Run the tests:**
```bash
helm test test-release
```

**Expected output:**
```
NAME: test-release
LAST DEPLOYED: Thu Jan 15 16:30:00 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE:     test-release-my-webapp-test-connection
Last Started:   Thu Jan 15 16:30:30 2024
Last Completed: Thu Jan 15 16:30:35 2024
Phase:          Succeeded

TEST SUITE:     test-release-my-webapp-test-content
Last Started:   Thu Jan 15 16:30:36 2024
Last Completed: Thu Jan 15 16:30:40 2024
Phase:          Succeeded
```

**Both tests passed!**

---

### Step 15: View Test Logs

**If you want to see what the tests did:**
```bash
# The pods are deleted on success, but you can disable that
# Let's reinstall without the delete policy for debugging

# First uninstall
helm uninstall test-release
```

---

## Part 5: Debugging Techniques

### Step 16: Create an Intentional Error

Let's create a problem and debug it.

**Corrupt the deployment template:**
```bash
cp my-webapp/templates/deployment.yaml my-webapp/templates/deployment.yaml.bak

# Add invalid YAML indentation
sed -i '' 's/replicas:/  replicas:/' my-webapp/templates/deployment.yaml 2>/dev/null || \
sed -i 's/replicas:/  replicas:/' my-webapp/templates/deployment.yaml
```

**Try to lint:**
```bash
helm lint my-webapp
```

**You might see a parsing error or warning.**

**Try to template:**
```bash
helm template test-release my-webapp 2>&1 | head -n 20
```

**You might see an error about YAML structure.**

**Restore the file:**
```bash
mv my-webapp/templates/deployment.yaml.bak my-webapp/templates/deployment.yaml
```

---

### Step 17: Debug Values Substitution

**Install a release:**
```bash
helm install debug-release my-webapp --set replicaCount=3
```

**Verify the value was used:**
```bash
helm get values debug-release
```

**Expected output:**
```yaml
USER-SUPPLIED VALUES:
replicaCount: 3
```

**Check the actual deployment:**
```bash
kubectl get deployment debug-release-my-webapp -o yaml | grep replicas
```

**Expected output:**
```
  replicas: 3
```

---

### Step 18: Debug Running Pods

**Get pod information:**
```bash
kubectl get pods -l app.kubernetes.io/instance=debug-release
```

**Describe a pod (see events and status):**
```bash
POD=$(kubectl get pods -l app.kubernetes.io/instance=debug-release -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD
```

**View pod logs:**
```bash
kubectl logs $POD
```

---

### Step 19: Check Kubernetes Events

**See recent cluster events:**
```bash
kubectl get events --sort-by='.lastTimestamp' | tail -n 20
```

This helps identify scheduling issues, image pull errors, etc.

---

### Step 20: Use helm get Commands

**View the rendered manifest:**
```bash
helm get manifest debug-release | head -n 40
```

**View all values (merged defaults + overrides):**
```bash
helm get values debug-release --all | head -n 30
```

**View everything:**
```bash
helm get all debug-release | head -n 50
```

---

## Part 6: Clean Up

**Uninstall the release:**
```bash
helm uninstall debug-release
```

**Clean up test files:**
```bash
rm test-values.yaml
```

**Verify:**
```bash
helm list
kubectl get pods
```

---

## Expected Results Summary

| Step | Tool | Expected Result |
|------|------|-----------------|
| Lint | `helm lint my-webapp` | 0 charts failed |
| Lint with error | Added invalid YAML | 1 chart failed |
| Template | `helm template my-release my-webapp` | Rendered YAML shown |
| Template with --set | `--set replicaCount=5` | replicas: 5 in output |
| kubectl validate | `kubectl apply --dry-run=client` | Resources created (dry run) |
| Dry run | `helm install --dry-run` | Computed values shown |
| Create test | Added test-connection.yaml | Test pod defined |
| Run test | `helm test test-release` | Phase: Succeeded |
| Debug | `helm get values/manifest` | Configuration shown |

---

## Troubleshooting Reference

### Problem: Lint shows parse error

**Debug:**
```bash
# Check for YAML syntax issues
python3 -c "import yaml; yaml.safe_load(open('my-webapp/values.yaml'))"
```

**Common causes:**
- Missing colons
- Incorrect indentation
- Invalid characters

---

### Problem: Template shows nil pointer

**Error message:**
```
nil pointer evaluating interface {}.tag
```

**Solution:**
```yaml
# Use default values
image: "{{ .Values.image.repository }}:{{ default "latest" .Values.image.tag }}"
```

---

### Problem: Test pod fails

**Debug:**
```bash
# View test pod logs (before cleanup)
kubectl logs test-release-my-webapp-test-connection

# Or run test with --logs flag
helm test test-release --logs
```

---

### Problem: Pod stuck in Pending

**Debug:**
```bash
kubectl describe pod <pod-name>
# Look at Events section at the bottom
```

**Common causes:**
- Insufficient resources
- Node selector/affinity issues
- PVC not bound

---

## Commands Reference

```bash
# Linting
helm lint <chart>
helm lint <chart> -f values.yaml
helm lint <chart> --strict          # Treat warnings as errors

# Templating
helm template <release> <chart>
helm template <release> <chart> --show-only templates/deployment.yaml
helm template <release> <chart> --set key=value
helm template <release> <chart> | kubectl apply --dry-run=client -f -

# Dry run
helm install <release> <chart> --dry-run
helm install <release> <chart> --dry-run --debug
helm upgrade <release> <chart> --dry-run

# Testing
helm test <release>
helm test <release> --logs          # Show test pod logs
helm test <release> --timeout 5m    # Set timeout

# Debugging
helm get values <release>           # User-supplied values
helm get values <release> --all     # All values
helm get manifest <release>         # Rendered YAML
helm get notes <release>            # NOTES.txt
helm get all <release>              # Everything

# Kubernetes debugging
kubectl describe pod <pod>
kubectl logs <pod>
kubectl get events --sort-by='.lastTimestamp'
kubectl get all -l app.kubernetes.io/instance=<release>
```

---

## Key Takeaways

1. **`helm lint`** catches syntax errors before deployment
2. **`helm template`** previews output without cluster
3. **`--dry-run`** validates against the actual cluster
4. **Test pods** verify your application works after deployment
5. **`helm get`** helps inspect running releases
6. **`kubectl describe`** shows events and status
7. **Always lint and template** before deploying to production
8. **Write tests** for critical functionality

---

**✅ Excellent! You now have a complete toolkit for testing and debugging Helm charts!**
