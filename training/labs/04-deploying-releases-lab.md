# 04 – Deploying & Managing Releases (Lab)

**Objective:** Practice installing, upgrading, rolling back, and uninstalling releases with various configuration options.

**Estimated duration:** 25–30 minutes

**Prerequisites:** Completed Module 03 (you should have the `my-webapp` chart).

---

## What You Will Do

1. Install a release with default values
2. Check release status and information
3. Upgrade with new values
4. View revision history
5. Rollback to a previous version
6. Install with a values file
7. Use upgrade --install pattern
8. Clean up

---

## Release Lifecycle Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    RELEASE LIFECYCLE                             │
└─────────────────────────────────────────────────────────────────┘

                         ┌─────────────┐
                         │   INSTALL   │
                         │  Revision 1 │
                         └──────┬──────┘
                                │
                                ▼
    ┌───────────────────────────────────────────────────────┐
    │                    DEPLOYED                           │
    │                                                       │
    │  ┌─────────┐     ┌─────────┐     ┌─────────┐         │
    │  │Revision │     │Revision │     │Revision │         │
    │  │    1    │────▶│    2    │────▶│    3    │         │
    │  │(install)│     │(upgrade)│     │(upgrade)│         │
    │  └─────────┘     └─────────┘     └────┬────┘         │
    │       │               │               │              │
    │       │               │               │              │
    │       └───────────────┴───────┬───────┘              │
    │                               │                      │
    │                        ┌──────▼──────┐               │
    │                        │  ROLLBACK   │               │
    │                        │ Revision 4  │               │
    │                        │ (copy of 2) │               │
    │                        └─────────────┘               │
    └───────────────────────────────────────────────────────┘
                                │
                                ▼
                         ┌─────────────┐
                         │  UNINSTALL  │
                         │  (cleanup)  │
                         └─────────────┘
```

---

## Preparation

**Make sure you have the my-webapp chart from Module 03:**

```bash
cd ~/helm-training
ls my-webapp
```

**Expected output:**
```
Chart.yaml  charts  templates  values.yaml
```

If you don't have it, go back and complete Module 03 first.

---

## Step-by-Step Instructions

### Step 1: Install with Default Values

Let's install our chart with all defaults.

**Run this command:**
```bash
helm install webapp-v1 my-webapp
```

**Breaking down the command:**
- `helm install` = Install a new release
- `webapp-v1` = The release name you chose
- `my-webapp` = Path to your chart directory

**Expected output:**
```
NAME: webapp-v1
LAST DEPLOYED: Thu Jan 15 14:00:00 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1
...
```

**Verify it's running:**
```bash
kubectl get pods
```

**Wait until the pod is Running (1/1 Ready).**

---

### Step 2: Check Release Information

**List all releases:**
```bash
helm list
```

**Expected output:**
```
NAME       NAMESPACE  REVISION  UPDATED                   STATUS    CHART           APP VERSION
webapp-v1  default    1         2024-01-15 14:00:00       deployed  my-webapp-0.1.0 1.25.0
```

**Get detailed status:**
```bash
helm status webapp-v1
```

This shows:
- Release information
- Current status
- The NOTES.txt output

---

### Step 3: View the Current Values

**See what values were used:**
```bash
helm get values webapp-v1
```

**Expected output:**
```
USER-SUPPLIED VALUES:
null
```

Since we didn't override anything, it shows null. The chart used all defaults.

**See ALL computed values (defaults + overrides):**
```bash
helm get values webapp-v1 --all | head -n 30
```

This shows all the values from values.yaml.

---

### Step 4: Test the Current Installation

**Start port-forward:**
```bash
kubectl port-forward svc/webapp-v1-my-webapp 8080:80 &
```

The `&` runs it in the background.

**Test with curl:**
```bash
curl -s http://localhost:8080 | grep -o "<h1>.*</h1>"
```

**Expected output:**
```
<h1>Welcome to Helm Training!</h1>
```

**Stop the background port-forward:**
```bash
kill %1 2>/dev/null || true
```

---

### Step 5: Upgrade with New Values

Now let's upgrade the release with different values.

**Run the upgrade:**
```bash
helm upgrade webapp-v1 my-webapp \
  --set replicaCount=2 \
  --set welcomeMessage="Version 2 - Upgraded!"
```

**Expected output:**
```
Release "webapp-v1" has been upgraded. Happy Helming!
NAME: webapp-v1
LAST DEPLOYED: Thu Jan 15 14:05:00 2024
NAMESPACE: default
STATUS: deployed
REVISION: 2
...
```

**Notice:** Revision is now 2!

---

### Step 6: Verify the Upgrade

**Check the release:**
```bash
helm list
```

**Expected output:**
```
NAME       NAMESPACE  REVISION  ...
webapp-v1  default    2         ...
```

**Check pods (should see 2 now):**
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                    READY   STATUS    RESTARTS   AGE
webapp-v1-my-webapp-xxxxx-aaaaa         1/1     Running   0          30s
webapp-v1-my-webapp-xxxxx-bbbbb         1/1     Running   0          30s
```

**Verify the new message:**
```bash
kubectl port-forward svc/webapp-v1-my-webapp 8080:80 &
sleep 2
curl -s http://localhost:8080 | grep -o "<h1>.*</h1>"
kill %1 2>/dev/null || true
```

**Expected output:**
```
<h1>Version 2 - Upgraded!</h1>
```

The ConfigMap was updated with the new message!

---

### Step 7: View Release History

**Check the revision history:**
```bash
helm history webapp-v1
```

**Expected output:**
```
REVISION  UPDATED                   STATUS      CHART           APP VERSION  DESCRIPTION
1         Thu Jan 15 14:00:00 2024  superseded  my-webapp-0.1.0 1.25.0       Install complete
2         Thu Jan 15 14:05:00 2024  deployed    my-webapp-0.1.0 1.25.0       Upgrade complete
```

**Understanding this:**
- Revision 1: Original install (now "superseded" = replaced)
- Revision 2: Current version (status "deployed")

---

### Step 8: Upgrade Again (Version 3)

Let's make another upgrade:

```bash
helm upgrade webapp-v1 my-webapp \
  --set replicaCount=3 \
  --set welcomeMessage="Version 3 - High Availability!"
```

**Check history:**
```bash
helm history webapp-v1
```

**Expected output:**
```
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         deployed    Upgrade complete
```

Now we have 3 revisions.

---

### Step 9: Rollback to Previous Version

Something's wrong with version 3! Let's rollback to version 2.

**Run the rollback:**
```bash
helm rollback webapp-v1 2
```

**Expected output:**
```
Rollback was a success! Happy Helming!
```

**Check history:**
```bash
helm history webapp-v1
```

**Expected output:**
```
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         superseded  Upgrade complete
4         deployed    Rollback to 2
```

**Important:** Rollback created revision 4, which is a copy of revision 2.

**Verify values rolled back:**
```bash
kubectl get pods   # Should be 2 pods (from revision 2)
```

**Test the message:**
```bash
kubectl port-forward svc/webapp-v1-my-webapp 8080:80 &
sleep 2
curl -s http://localhost:8080 | grep -o "<h1>.*</h1>"
kill %1 2>/dev/null || true
```

**Expected output:**
```
<h1>Version 2 - Upgraded!</h1>
```

The message is back to "Version 2"!

---

### Step 12: Using Values Files

Let's install a new release using a values file (best practice).

```
┌─────────────────────────────────────────────────────────────────┐
│                    VALUES MERGE ORDER                            │
└─────────────────────────────────────────────────────────────────┘

    LOWEST PRIORITY ─────────────────────────▶ HIGHEST PRIORITY

    ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
    │ values.yaml  │   │   -f file    │   │    --set     │
    │  (defaults)  │ + │ (overrides)  │ + │  (command)   │
    └──────────────┘   └──────────────┘   └──────────────┘
           │                  │                  │
           │                  │                  │
           └──────────────────┴──────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  FINAL VALUES    │
                    │  (merged result) │
                    └──────────────────┘
```

**Create a production values file:**
```bash
cat > prod-values.yaml << 'EOF'
replicaCount: 3

welcomeMessage: "Production Environment"

service:
  type: NodePort

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
EOF
```

**Install with the values file:**
```bash
helm install prod-webapp my-webapp -f prod-values.yaml
```

**Verify:**
```bash
helm list
kubectl get pods | grep prod
```

You should see:
- Two releases: webapp-v1 and prod-webapp
- 3 pods for prod-webapp (replicaCount: 3)

---

### Step 11: Check What Values Were Used

**View user-supplied values for prod-webapp:**
```bash
helm get values prod-webapp
```

**Expected output:**
```yaml
USER-SUPPLIED VALUES:
replicaCount: 3
resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
service:
  type: NodePort
welcomeMessage: Production Environment
```

This shows exactly what you provided via the values file.

---

### Step 12: Upgrade with --reuse-values

**Important concept:** By default, upgrades reset to chart defaults.

**Let's see this:**
```bash
# Current: prod-webapp has replicaCount=3

# Upgrade without --reuse-values (WRONG WAY)
helm upgrade prod-webapp my-webapp --set image.tag="1.24"

# Check pods
kubectl get pods | grep prod
```

**Problem:** You might see only 1 pod because replicaCount reset to default (1)!

**Fix it with --reuse-values:**
```bash
helm upgrade prod-webapp my-webapp --reuse-values --set image.tag="1.25"
```

Now replicaCount stays at 3.

**Better approach:** Always use a values file:
```bash
helm upgrade prod-webapp my-webapp -f prod-values.yaml
```

---

### Step 13: The upgrade --install Pattern

This pattern is great for CI/CD: install if new, upgrade if exists.

**Test with a new release:**
```bash
helm upgrade --install staging-webapp my-webapp \
  --set welcomeMessage="Staging Environment" \
  --set replicaCount=2
```

**Output indicates install:**
```
Release "staging-webapp" does not exist. Installing it now.
NAME: staging-webapp
...
```

**Run the same command again:**
```bash
helm upgrade --install staging-webapp my-webapp \
  --set welcomeMessage="Staging Environment - Updated" \
  --set replicaCount=2
```

**Output indicates upgrade:**
```
Release "staging-webapp" has been upgraded.
...
```

This pattern handles both cases automatically!

---

### Step 14: List All Releases

**See all releases:**
```bash
helm list
```

**Expected output:**
```
NAME            NAMESPACE  REVISION  STATUS    CHART
prod-webapp     default    3         deployed  my-webapp-0.1.0
staging-webapp  default    2         deployed  my-webapp-0.1.0
webapp-v1       default    4         deployed  my-webapp-0.1.0
```

You have 3 releases, each with its own configuration.

---

### Step 15: Clean Up All Releases

**Uninstall all three releases:**
```bash
helm uninstall webapp-v1
helm uninstall prod-webapp
helm uninstall staging-webapp
```

**Verify everything is gone:**
```bash
helm list
kubectl get pods
```

Both should be empty.

**Clean up the values file:**
```bash
rm prod-values.yaml
```

---

## Expected Results Summary

| Step | Action | Expected Result |
|------|--------|-----------------|
| Install | `helm install webapp-v1 my-webapp` | REVISION: 1, STATUS: deployed |
| Upgrade | `helm upgrade webapp-v1 --set ...` | REVISION: 2 |
| History | `helm history webapp-v1` | Shows all revisions |
| Rollback | `helm rollback webapp-v1 2` | Creates new revision (4) with v2 values |
| Values file | `helm install -f prod-values.yaml` | Values from file used |
| upgrade --install | `helm upgrade --install` | Install or upgrade as needed |
| Uninstall | `helm uninstall` | Release removed |

---

## Troubleshooting

### Problem: "cannot re-use a name that is still in use"

**Cause:** Trying to install a release name that already exists.

**Solution:**
```bash
# Either uninstall first
helm uninstall existing-release

# Or use upgrade --install
helm upgrade --install existing-release ./mychart
```

---

### Problem: Upgrade resets my values

**Cause:** Default behavior resets to chart defaults.

**Solution:**
```bash
# Use --reuse-values
helm upgrade my-app ./mychart --reuse-values --set newKey=newValue

# Or always use a values file
helm upgrade my-app ./mychart -f my-values.yaml
```

---

### Problem: Rollback doesn't seem to work

**Check:** Make sure you're specifying the correct revision number.

```bash
# View history first
helm history my-app

# Then rollback to the specific revision
helm rollback my-app <revision-number>
```

---

### Problem: "Error: UPGRADE FAILED: another operation is in progress"

**Cause:** Previous operation didn't complete cleanly.

**Solution:**
```bash
# Check the release status
helm status my-app

# If stuck, you may need to force the operation
helm upgrade my-app ./mychart --force
```

---

## Key Takeaways

1. **`helm install`** creates a new release with revision 1
2. **`helm upgrade`** creates new revisions
3. **`helm history`** shows all revisions
4. **`helm rollback`** creates a NEW revision with old content
5. **Use values files** for production deployments
6. **Use `--reuse-values`** if upgrading with --set
7. **Use `upgrade --install`** in CI/CD pipelines
8. **`helm uninstall`** removes the release and resources

---

## Commands Reference

```bash
# Install
helm install <name> <chart>
helm install <name> <chart> -f values.yaml
helm install <name> <chart> --set key=value

# Upgrade
helm upgrade <name> <chart>
helm upgrade <name> <chart> --reuse-values
helm upgrade --install <name> <chart>

# Information
helm list
helm status <name>
helm history <name>
helm get values <name>
helm get manifest <name>

# Rollback
helm rollback <name> <revision>

# Uninstall
helm uninstall <name>
helm uninstall <name> --keep-history
```

---

**✅ Excellent! You now know how to manage the full lifecycle of Helm releases!**
