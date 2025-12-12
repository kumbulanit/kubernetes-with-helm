# 03 – Creating Helm Charts (Lab)

**Objective:** Create a custom Helm chart from scratch, customize it, lint it, and install it.

**Estimated duration:** 30–35 minutes

**Prerequisites:** Helm installed, Minikube running, completed Module 02.

---

## What You Will Build

In this lab, you'll create a chart for a simple web application:
- Deployment (runs nginx containers)
- Service (exposes the application)
- ConfigMap (custom welcome page)
- Customizable through values

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    MY-WEBAPP CHART STRUCTURE                     │
└─────────────────────────────────────────────────────────────────┘

    CHART FILES                          KUBERNETES RESOURCES
    ───────────                          ─────────────────────

  ┌─────────────────┐                 ┌─────────────────────────┐
  │   values.yaml   │ ───────────────▶│      Configuration      │
  │   - replicas    │    Render       │   (merged values)       │
  │   - image       │                 └───────────┬─────────────┘
  │   - message     │                             │
  └─────────────────┘                             │
          │                                       ▼
          │                           ┌─────────────────────────┐
          ▼                           │      Deployment         │
  ┌─────────────────┐                 │  ┌─────────────────┐   │
  │   templates/    │ ───────────────▶│  │   Pod (nginx)   │   │
  │   deployment    │    Create       │  │  ┌───────────┐  │   │
  │   service       │                 │  │  │ ConfigMap │  │   │
  │   configmap     │                 │  │  │  Volume   │  │   │
  └─────────────────┘                 │  │  └───────────┘  │   │
                                      │  └─────────────────┘   │
                                      └───────────┬────────────┘
                                                  │
                                      ┌───────────▼────────────┐
                                      │       Service          │
                                      │    (ClusterIP:80)      │
                                      └────────────────────────┘
```

---

## Step-by-Step Instructions

### Step 1: Create the Chart Scaffold

Helm can generate a starter chart structure for you.

**Navigate to a working directory:**
```bash
cd ~/
mkdir helm-training && cd helm-training
```

**Create the chart:**
```bash
helm create my-webapp
```

**Expected output:**
```
Creating my-webapp
```

**What was created:**
```
my-webapp/
├── Chart.yaml
├── values.yaml
├── charts/
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── serviceaccount.yaml
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   └── tests/
│       └── test-connection.yaml
└── .helmignore
```

Helm generates a complete, working chart! Let's explore it.

---

### Step 2: Explore the Generated Files

**View the chart metadata:**
```bash
cat my-webapp/Chart.yaml
```

**Expected output:**
```yaml
apiVersion: v2
name: my-webapp
description: A Helm chart for Kubernetes
type: application
version: 0.1.0
appVersion: "1.16.0"
```

**What this tells us:**
- Chart name: my-webapp
- Version: 0.1.0 (chart version)
- AppVersion: 1.16.0 (the app version, we'll change this)

---

**View the default values:**
```bash
cat my-webapp/values.yaml
```

This is a long file. Let's look at key sections:

```bash
head -n 30 my-webapp/values.yaml
```

**Key values you'll see:**
```yaml
replicaCount: 1

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: ""

service:
  type: ClusterIP
  port: 80
```

---

**View a template file:**
```bash
cat my-webapp/templates/deployment.yaml
```

**What you'll see:**
Go template syntax with:
- `{{ .Values.replicaCount }}` – pulls from values.yaml
- `{{ include "my-webapp.fullname" . }}` – uses a helper function
- Conditional blocks with `{{- if ... }}`

---

### Step 3: Customize Chart.yaml

Let's update the chart metadata.

**Edit Chart.yaml:**
```bash
cat > my-webapp/Chart.yaml << 'EOF'
apiVersion: v2
name: my-webapp
description: A custom web application chart for Helm training
type: application
version: 0.1.0
appVersion: "1.25.0"
keywords:
  - nginx
  - web
  - training
maintainers:
  - name: Helm Training Student
    email: student@example.com
EOF
```

**What we changed:**
- Better description
- Updated appVersion to 1.25.0 (current nginx)
- Added keywords and maintainer info

---

### Step 4: Simplify values.yaml

The generated values.yaml has many options. Let's simplify it for our training.

**Replace values.yaml:**
```bash
cat > my-webapp/values.yaml << 'EOF'
# Number of pod replicas
replicaCount: 1

# Container image settings
image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

# Service settings
service:
  type: ClusterIP
  port: 80

# Resource limits (important for production)
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Custom welcome message (we'll use this!)
welcomeMessage: "Welcome to Helm Training!"
EOF
```

**What we configured:**
- 1 replica (can be overridden)
- nginx 1.25 image
- ClusterIP service on port 80
- Resource limits (good practice)
- Custom welcome message (we'll use this in a ConfigMap)

---

### Step 5: Create a Custom ConfigMap Template

Let's add a ConfigMap that creates a custom welcome page.

**Create the ConfigMap template:**
```bash
cat > my-webapp/templates/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "my-webapp.fullname" . }}-html
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>{{ .Values.welcomeMessage }}</title>
      <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #326CE5; }
        .info { background: #f0f0f0; padding: 20px; border-radius: 10px; margin: 20px auto; max-width: 600px; }
      </style>
    </head>
    <body>
      <h1>{{ .Values.welcomeMessage }}</h1>
      <div class="info">
        <p><strong>Release Name:</strong> {{ .Release.Name }}</p>
        <p><strong>Namespace:</strong> {{ .Release.Namespace }}</p>
        <p><strong>Chart Version:</strong> {{ .Chart.Version }}</p>
        <p><strong>App Version:</strong> {{ .Chart.AppVersion }}</p>
        <p><strong>Replicas:</strong> {{ .Values.replicaCount }}</p>
      </div>
    </body>
    </html>
EOF
```

**What this does:**
- Creates a ConfigMap with a custom `index.html`
- Uses template values to show release information
- The HTML is dynamically generated with Helm values

---

### Step 6: Update the Deployment to Use the ConfigMap

We need to mount the ConfigMap into nginx so it serves our custom page.

**View the current deployment template:**
```bash
head -n 50 my-webapp/templates/deployment.yaml
```

**Replace the deployment template:**
```bash
cat > my-webapp/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-webapp.fullname" . }}
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "my-webapp.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "my-webapp.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          # Mount the custom HTML from ConfigMap
          volumeMounts:
            - name: html-volume
              mountPath: /usr/share/nginx/html
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: html-volume
          configMap:
            name: {{ include "my-webapp.fullname" . }}-html
EOF
```

**What we changed:**
- Added a volumeMount to mount our ConfigMap
- Added a volume referencing the ConfigMap
- Added liveness and readiness probes (best practice)
- Used `toYaml` to include resources from values

---

### Step 7: Update the Service Template

Let's ensure the service template is clean:

**Replace the service template:**
```bash
cat > my-webapp/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "my-webapp.fullname" . }}
  labels:
    {{- include "my-webapp.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "my-webapp.selectorLabels" . | nindent 4 }}
EOF
```

---

### Step 8: Update NOTES.txt

Update the post-install instructions:

```bash
cat > my-webapp/templates/NOTES.txt << 'EOF'
🎉 Congratulations! {{ .Release.Name }} has been deployed!

📊 Release Information:
   - Name: {{ .Release.Name }}
   - Namespace: {{ .Release.Namespace }}
   - Replicas: {{ .Values.replicaCount }}

🌐 To access your application:

{{- if eq .Values.service.type "NodePort" }}
   Run: minikube service {{ include "my-webapp.fullname" . }} --url
{{- else if eq .Values.service.type "LoadBalancer" }}
   Run: kubectl get svc {{ include "my-webapp.fullname" . }} -w
{{- else }}
   Run: kubectl port-forward svc/{{ include "my-webapp.fullname" . }} 8080:{{ .Values.service.port }}
   Then open: http://localhost:8080
{{- end }}

📝 Useful commands:
   - Check status: helm status {{ .Release.Name }}
   - View pods: kubectl get pods -l app.kubernetes.io/instance={{ .Release.Name }}
   - View logs: kubectl logs -l app.kubernetes.io/instance={{ .Release.Name }}
   - Uninstall: helm uninstall {{ .Release.Name }}
EOF
```

---

### Step 9: Delete Unnecessary Templates

The generated chart has files we don't need. Let's remove them:

```bash
rm my-webapp/templates/ingress.yaml
rm my-webapp/templates/hpa.yaml
rm my-webapp/templates/serviceaccount.yaml
rm -rf my-webapp/templates/tests
```

**Why remove these:**
- ingress.yaml – We're not using Ingress in this lab
- hpa.yaml – Horizontal Pod Autoscaler not needed
- serviceaccount.yaml – Default service account is fine
- tests/ – We'll cover testing in a later module

---

### Step 10: Lint Your Chart

Before installing, check for errors:

**Run helm lint:**
```bash
helm lint my-webapp
```

**Expected output:**
```
==> Linting my-webapp
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

**What this means:**
- ✅ 0 charts failed – No errors
- ⚠️ INFO: icon is recommended – Just a suggestion, not an error

---

### Step 11: Preview the Installation (Template Rendering)

See what Kubernetes YAML will be generated:

```bash
helm template my-release my-webapp
```

**This shows all the rendered YAML.** Let's pipe it through head:

```bash
helm template my-release my-webapp | head -n 60
```

**What you'll see:**
- ConfigMap with your custom HTML
- Service definition
- Deployment with volume mounts

**Check for your welcome message:**
```bash
helm template my-release my-webapp | grep -A 5 "welcomeMessage"
```

You should see your custom welcome message in the HTML.

---

### Step 12: Install Your Chart

Now let's install it!

```bash
helm install my-release my-webapp
```

**Expected output:**
```
NAME: my-release
LAST DEPLOYED: Thu Jan 15 11:00:00 2024
NAMESPACE: default
STATUS: deployed
REVISION: 1

🎉 Congratulations! my-release has been deployed!
...
```

---

### Step 13: Verify the Installation

**Check the release:**
```bash
helm list
```

**Expected output:**
```
NAME         NAMESPACE   REVISION   UPDATED                   STATUS     CHART           APP VERSION
my-release   default     1          2024-01-15 11:00:00       deployed   my-webapp-0.1.0 1.25.0
```

**Check pods:**
```bash
kubectl get pods
```

**Expected output:**
```
NAME                                    READY   STATUS    RESTARTS   AGE
my-release-my-webapp-7d4f8b7b9c-xxxxx   1/1     Running   0          30s
```

**Check services:**
```bash
kubectl get svc
```

**Check the ConfigMap:**
```bash
kubectl get configmap
kubectl describe configmap my-release-my-webapp-html
```

You should see your custom HTML in the ConfigMap.

---

### Step 14: Test Your Application

**Start port-forward:**
```bash
kubectl port-forward svc/my-release-my-webapp 8080:80
```

**In a new terminal, test with curl:**
```bash
curl http://localhost:8080
```

**Expected output:**
```html
<!DOCTYPE html>
<html>
<head>
  <title>Welcome to Helm Training!</title>
...
```

You should see your custom welcome page with release information!

**Stop port-forward:** Press `Ctrl+C`

---

### Step 15: Install with Custom Values

Let's install another release with different values:

```bash
helm install custom-release my-webapp \
  --set replicaCount=2 \
  --set welcomeMessage="Hello from Custom Release!" \
  --set service.type=NodePort
```

**Verify two releases exist:**
```bash
helm list
```

**Expected output:**
```
NAME            NAMESPACE   REVISION   STATUS     CHART
my-release      default     1          deployed   my-webapp-0.1.0
custom-release  default     1          deployed   my-webapp-0.1.0
```

**Check pods (should have 3 total):**
```bash
kubectl get pods
```

**Access the custom release via Minikube:**
```bash
minikube service custom-release-my-webapp --url
```

Open that URL in your browser and see your custom message!

---

### Step 16: Clean Up

**Uninstall both releases:**
```bash
helm uninstall my-release
helm uninstall custom-release
```

**Verify:**
```bash
helm list
kubectl get pods
```

Everything should be gone.

---

## Expected Results Summary

| Step | What You Did | Expected Result |
|------|--------------|-----------------|
| Create chart | `helm create my-webapp` | Chart structure created |
| Customize | Edited values.yaml, added configmap.yaml | Custom configuration |
| Lint | `helm lint my-webapp` | 0 charts failed |
| Template | `helm template my-release my-webapp` | Rendered YAML shown |
| Install | `helm install my-release my-webapp` | STATUS: deployed |
| Test | Port-forward + curl | Custom welcome page |
| Custom install | `--set` flags | Different configuration |
| Uninstall | `helm uninstall` | Releases removed |

---

## Troubleshooting

### Problem: "error parsing" when running helm template

**Cause:** YAML syntax error in templates

**Solution:** Check for:
- Missing colons
- Incorrect indentation
- Unclosed template brackets `{{ }}`

**Debug:**
```bash
helm template my-release my-webapp --debug
```

---

### Problem: Pod stuck in CrashLoopBackOff

**Cause:** Container can't start

**Solution:** Check logs:
```bash
kubectl logs -l app.kubernetes.io/instance=my-release
kubectl describe pod -l app.kubernetes.io/instance=my-release
```

---

### Problem: ConfigMap not mounting

**Cause:** Volume mount path or name mismatch

**Solution:** Verify volume and volumeMount names match:
```bash
kubectl describe pod -l app.kubernetes.io/instance=my-release
```

Look for Events at the bottom.

---

## Chart Files Summary

After this lab, your chart should have:

```
┌─────────────────────────────────────────────────────────────────┐
│                    CHART DIRECTORY STRUCTURE                     │
└─────────────────────────────────────────────────────────────────┘

    my-webapp/
    │
    ├── Chart.yaml ─────────────────▶ Identity (name, version)
    │
    ├── values.yaml ────────────────▶ Default configuration
    │
    ├── templates/ ─────────────────▶ Kubernetes resource templates
    │   │
    │   ├── deployment.yaml ────────▶ Pod specification
    │   │       │
    │   │       └── volumeMounts ───▶ Mounts ConfigMap
    │   │
    │   ├── service.yaml ───────────▶ Network exposure
    │   │
    │   ├── configmap.yaml ─────────▶ Custom HTML content
    │   │
    │   ├── NOTES.txt ──────────────▶ Post-install instructions
    │   │
    │   └── _helpers.tpl ───────────▶ Reusable template functions
    │
    ├── charts/ ────────────────────▶ Dependencies (empty)
    │
    └── .helmignore ────────────────▶ Files to exclude from package
```

---

## Key Takeaways

1. **`helm create`** generates a working starter chart
2. **values.yaml** contains all configurable options
3. **Template syntax** (`{{ .Values.x }}`) makes charts dynamic
4. **ConfigMaps** are great for injecting configuration
5. **Volume mounts** connect ConfigMaps to containers
6. **`helm lint`** catches errors before installation
7. **`helm template`** previews rendered YAML
8. **`--set`** overrides values at install time

---

**✅ Congratulations! You've created your first custom Helm chart!**

**Keep the `my-webapp` chart** – we'll use it in the next modules!
