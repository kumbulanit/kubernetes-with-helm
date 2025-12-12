# 07 – Final Project: Complete Microservice Deployment

**Estimated duration:** 40–50 minutes

---

## Project Overview

### What You Will Build

In this final project, you'll deploy a complete microservice application with:
- A **frontend** web service (nginx-based)
- A **backend** API service (nginx simulating an API)
- Communication between services
- Separate namespaces for different environments
- Complete lifecycle management

This project combines everything you've learned:
- Creating charts
- Deploying releases
- Using namespaces
- Testing and debugging

---

## Skills Integration Map

```
┌─────────────────────────────────────────────────────────────────┐
│                    SKILLS YOU'LL USE                             │
└─────────────────────────────────────────────────────────────────┘

   Module 01          Module 02          Module 03          Module 04
   ─────────          ─────────          ─────────          ─────────
┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│   Helm    │    │  Install  │    │  Create   │    │  Deploy   │
│  Basics   │───▶│  Charts   │───▶│  Charts   │───▶│  Releases │
└─────┬─────┘    └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
      │                │                │                │
      └────────────────┴────────────────┴────────────────┘
                                │
                                ▼
                    ┌───────────────────┐
                    │   FINAL PROJECT   │
                    │  (Microservices)  │
                    └─────────┬─────────┘
                                │
      ┌─────────────────┴─────────────────┐
      │                                   │
      ▼                                   ▼
   Module 05                          Module 06
   ─────────                          ─────────
┌───────────┐                    ┌───────────┐
│Namespaces │                    │  Testing  │
│  & Repos  │                    │ Debugging │
└───────────┘                    └───────────┘
```

---

## Project Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTER                          │
│                                                                  │
│    Namespace: microservices                                      │
│   ┌───────────────────────────────────────────────────────────┐  │
│   │                                                           │  │
│   │   ┌─────────────────┐       ┌─────────────────┐          │  │
│   │   │                 │       │                 │          │  │
│   │   │    FRONTEND     │──────▶│    BACKEND      │          │  │
│   │   │    (nginx)      │ HTTP  │    (nginx)      │          │  │
│   │   │                 │       │                 │          │  │
│   │   │  Port: 80       │       │  Port: 80       │          │  │
│   │   │  Replicas: 2    │       │  Replicas: 2    │          │  │
│   │   │                 │       │                 │          │  │
│   │   └─────────────────┘       └─────────────────┘          │  │
│   │          ▲                                               │  │
│   └──────────│───────────────────────────────────────────────┘  │
│              │                                                   │
│         NodePort                                                 │
│         (External Access)                                        │
│              │                                                   │
└──────────────│───────────────────────────────────────────────────┘
               │
          USER BROWSER
```

---

## Part 1: Setup

### Step 1: Create Project Directory

```bash
cd ~/helm-training
mkdir microservice-project && cd microservice-project
```

### Step 2: Create Namespace

```bash
kubectl create namespace microservices
```

**Verify:**
```bash
kubectl get namespace microservices
```

---

## Part 2: Create the Backend Chart

### Step 3: Create Backend Chart Structure

```bash
helm create backend
```

### Step 4: Configure Backend Chart.yaml

```bash
cat > backend/Chart.yaml << 'EOF'
apiVersion: v2
name: backend
description: Backend API service for the microservices project
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - backend
  - api
  - microservices
maintainers:
  - name: Helm Training Student
EOF
```

### Step 5: Configure Backend values.yaml

```bash
cat > backend/values.yaml << 'EOF'
# Replica configuration
replicaCount: 2

# Container image
image:
  repository: nginx
  tag: "1.25-alpine"
  pullPolicy: IfNotPresent

# Service configuration
service:
  type: ClusterIP
  port: 80

# Resource limits
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Backend-specific configuration
apiVersion: "v1"
apiName: "Backend API"
EOF
```

### Step 6: Create Backend ConfigMap

```bash
cat > backend/templates/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "backend.fullname" . }}-config
  labels:
    {{- include "backend.labels" . | nindent 4 }}
data:
  index.html: |
    {
      "service": "{{ .Values.apiName }}",
      "version": "{{ .Values.apiVersion }}",
      "status": "healthy",
      "release": "{{ .Release.Name }}",
      "namespace": "{{ .Release.Namespace }}",
      "timestamp": "{{ now | date "2006-01-02T15:04:05Z07:00" }}"
    }
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            default_type application/json;
            add_header Content-Type application/json;
        }
        
        location /health {
            return 200 '{"status": "healthy"}';
            add_header Content-Type application/json;
        }
    }
EOF
```

### Step 7: Update Backend Deployment

```bash
cat > backend/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "backend.fullname" . }}
  labels:
    {{- include "backend.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "backend.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "backend.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          volumeMounts:
            - name: html-volume
              mountPath: /usr/share/nginx/html
            - name: nginx-config
              mountPath: /etc/nginx/conf.d
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: html-volume
          configMap:
            name: {{ include "backend.fullname" . }}-config
            items:
              - key: index.html
                path: index.html
        - name: nginx-config
          configMap:
            name: {{ include "backend.fullname" . }}-config
            items:
              - key: nginx.conf
                path: default.conf
EOF
```

### Step 8: Update Backend Service

```bash
cat > backend/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "backend.fullname" . }}
  labels:
    {{- include "backend.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "backend.selectorLabels" . | nindent 4 }}
EOF
```

### Step 9: Create Backend Test

```bash
mkdir -p backend/templates/tests

cat > backend/templates/tests/test-connection.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "backend.fullname" . }}-test"
  labels:
    {{- include "backend.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: test
      image: curlimages/curl:8.4.0
      command: ['sh', '-c']
      args:
        - |
          echo "Testing backend service..."
          RESPONSE=$(curl -s {{ include "backend.fullname" . }}:{{ .Values.service.port }})
          echo "Response: $RESPONSE"
          if echo "$RESPONSE" | grep -q "healthy"; then
            echo "✅ Backend test passed!"
            exit 0
          else
            echo "❌ Backend test failed!"
            exit 1
          fi
  restartPolicy: Never
EOF
```

### Step 10: Remove Unnecessary Backend Files

```bash
rm backend/templates/ingress.yaml
rm backend/templates/hpa.yaml
rm backend/templates/serviceaccount.yaml
```

### Step 11: Lint Backend Chart

```bash
helm lint backend
```

**Expected output:**
```
==> Linting backend
[INFO] Chart.yaml: icon is recommended

1 chart(s) linted, 0 chart(s) failed
```

---

## Part 3: Create the Frontend Chart

### Step 12: Create Frontend Chart Structure

```bash
helm create frontend
```

### Step 13: Configure Frontend Chart.yaml

```bash
cat > frontend/Chart.yaml << 'EOF'
apiVersion: v2
name: frontend
description: Frontend web service for the microservices project
type: application
version: 0.1.0
appVersion: "1.0.0"
keywords:
  - frontend
  - web
  - microservices
maintainers:
  - name: Helm Training Student
EOF
```

### Step 14: Configure Frontend values.yaml

```bash
cat > frontend/values.yaml << 'EOF'
# Replica configuration
replicaCount: 2

# Container image
image:
  repository: nginx
  tag: "1.25-alpine"
  pullPolicy: IfNotPresent

# Service configuration
service:
  type: NodePort
  port: 80

# Resource limits
resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 50m
    memory: 64Mi

# Frontend-specific configuration
appTitle: "Microservices Demo"
backendService: "backend-api"

# Environment
environment: "development"
EOF
```

### Step 15: Create Frontend ConfigMap

```bash
cat > frontend/templates/configmap.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "frontend.fullname" . }}-config
  labels:
    {{- include "frontend.labels" . | nindent 4 }}
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>{{ .Values.appTitle }}</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .container {
          background: white;
          border-radius: 20px;
          padding: 40px;
          box-shadow: 0 20px 60px rgba(0,0,0,0.3);
          max-width: 800px;
          width: 90%;
        }
        h1 {
          color: #333;
          margin-bottom: 20px;
          text-align: center;
        }
        .info-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
          gap: 20px;
          margin: 30px 0;
        }
        .info-card {
          background: #f8f9fa;
          padding: 20px;
          border-radius: 10px;
          border-left: 4px solid #667eea;
        }
        .info-card h3 {
          color: #667eea;
          margin-bottom: 10px;
          font-size: 14px;
          text-transform: uppercase;
        }
        .info-card p {
          color: #333;
          font-size: 18px;
          font-weight: bold;
        }
        .backend-status {
          background: #e8f5e9;
          border: 2px solid #4caf50;
          border-radius: 10px;
          padding: 20px;
          margin-top: 20px;
        }
        .backend-status h3 {
          color: #2e7d32;
          margin-bottom: 10px;
        }
        #backend-response {
          font-family: monospace;
          background: #f5f5f5;
          padding: 15px;
          border-radius: 5px;
          white-space: pre-wrap;
        }
        .badge {
          display: inline-block;
          padding: 5px 15px;
          border-radius: 20px;
          font-size: 12px;
          font-weight: bold;
          text-transform: uppercase;
        }
        .badge-{{ .Values.environment }} {
          background: {{ if eq .Values.environment "production" }}#f44336{{ else if eq .Values.environment "staging" }}#ff9800{{ else }}#4caf50{{ end }};
          color: white;
        }
      </style>
    </head>
    <body>
      <div class="container">
        <h1>🚀 {{ .Values.appTitle }}</h1>
        <p style="text-align: center; margin-bottom: 20px;">
          <span class="badge badge-{{ .Values.environment }}">{{ .Values.environment }}</span>
        </p>
        
        <div class="info-grid">
          <div class="info-card">
            <h3>Frontend Release</h3>
            <p>{{ .Release.Name }}</p>
          </div>
          <div class="info-card">
            <h3>Namespace</h3>
            <p>{{ .Release.Namespace }}</p>
          </div>
          <div class="info-card">
            <h3>Chart Version</h3>
            <p>{{ .Chart.Version }}</p>
          </div>
          <div class="info-card">
            <h3>Replicas</h3>
            <p>{{ .Values.replicaCount }}</p>
          </div>
        </div>
        
        <div class="backend-status">
          <h3>📡 Backend API Response</h3>
          <div id="backend-response">Loading...</div>
        </div>
      </div>
      
      <script>
        async function fetchBackend() {
          try {
            const response = await fetch('/api/');
            const data = await response.json();
            document.getElementById('backend-response').textContent = JSON.stringify(data, null, 2);
          } catch (error) {
            document.getElementById('backend-response').textContent = 
              'Error connecting to backend: ' + error.message + '\n\n' +
              'This is expected if you are viewing this directly.\n' +
              'The backend connection works through the nginx proxy.';
          }
        }
        fetchBackend();
        setInterval(fetchBackend, 5000);
      </script>
    </body>
    </html>
  nginx.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /api/ {
            proxy_pass http://{{ .Values.backendService }}:80/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
        
        location /health {
            return 200 '{"status": "healthy"}';
            add_header Content-Type application/json;
        }
    }
EOF
```

### Step 16: Update Frontend Deployment

```bash
cat > frontend/templates/deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "frontend.fullname" . }}
  labels:
    {{- include "frontend.labels" . | nindent 4 }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      {{- include "frontend.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "frontend.selectorLabels" . | nindent 8 }}
    spec:
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
          volumeMounts:
            - name: html-volume
              mountPath: /usr/share/nginx/html
            - name: nginx-config
              mountPath: /etc/nginx/conf.d
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: html-volume
          configMap:
            name: {{ include "frontend.fullname" . }}-config
            items:
              - key: index.html
                path: index.html
        - name: nginx-config
          configMap:
            name: {{ include "frontend.fullname" . }}-config
            items:
              - key: nginx.conf
                path: default.conf
EOF
```

### Step 17: Update Frontend Service

```bash
cat > frontend/templates/service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "frontend.fullname" . }}
  labels:
    {{- include "frontend.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: http
      protocol: TCP
      name: http
  selector:
    {{- include "frontend.selectorLabels" . | nindent 4 }}
EOF
```

### Step 18: Create Frontend Test

```bash
mkdir -p frontend/templates/tests

cat > frontend/templates/tests/test-connection.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: "{{ include "frontend.fullname" . }}-test"
  labels:
    {{- include "frontend.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  containers:
    - name: test
      image: curlimages/curl:8.4.0
      command: ['sh', '-c']
      args:
        - |
          echo "Testing frontend service..."
          RESPONSE=$(curl -s {{ include "frontend.fullname" . }}:{{ .Values.service.port }})
          if echo "$RESPONSE" | grep -q "{{ .Values.appTitle }}"; then
            echo "✅ Frontend test passed!"
            exit 0
          else
            echo "❌ Frontend test failed!"
            exit 1
          fi
  restartPolicy: Never
EOF
```

### Step 19: Remove Unnecessary Frontend Files

```bash
rm frontend/templates/ingress.yaml
rm frontend/templates/hpa.yaml
rm frontend/templates/serviceaccount.yaml
```

### Step 20: Lint Frontend Chart

```bash
helm lint frontend
```

---

## Part 4: Deploy the Application

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT ORDER                              │
└─────────────────────────────────────────────────────────────────┘

    Step 1              Step 2              Step 3              Step 4
    ──────              ──────              ──────              ──────
┌───────────┐      ┌───────────┐      ┌───────────┐      ┌───────────┐
│  Deploy   │      │   Test    │      │  Deploy   │      │   Test    │
│  Backend  │ ───▶ │  Backend  │ ───▶ │ Frontend  │ ───▶ │ Frontend  │
│   First   │      │           │      │  Second   │      │           │
└───────────┘      └───────────┘      └───────────┘      └───────────┘
     │                   │                  │                  │
     ▼                   ▼                  ▼                  ▼
helm install        helm test         helm install        helm test
backend-api         backend-api       frontend-web       frontend-web

    WHY THIS ORDER?
    ────────────────
    Backend must be running before Frontend
    because Frontend proxies requests to Backend.
```

### Step 21: Deploy Backend First

```bash
helm install backend-api backend \
  --namespace microservices
```

**Wait for backend to be ready:**
```bash
kubectl get pods -n microservices -w
```

Press `Ctrl+C` when pods show `2/2 Running`.

### Step 22: Test Backend

```bash
helm test backend-api -n microservices
```

**Expected output:**
```
TEST SUITE:     backend-api-backend-test
...
Phase:          Succeeded
```

### Step 23: Deploy Frontend

```bash
helm install frontend-web frontend \
  --namespace microservices \
  --set backendService=backend-api-backend
```

**Wait for frontend to be ready:**
```bash
kubectl get pods -n microservices
```

### Step 24: Test Frontend

```bash
helm test frontend-web -n microservices
```

---

## Part 5: Verify the Application

### Step 25: List All Releases

```bash
helm list -n microservices
```

**Expected output:**
```
NAME          NAMESPACE       REVISION  STATUS    CHART           APP VERSION
backend-api   microservices   1         deployed  backend-0.1.0   1.0.0
frontend-web  microservices   1         deployed  frontend-0.1.0  1.0.0
```

### Step 26: Check All Resources

```bash
kubectl get all -n microservices
```

**Expected output:**
```
NAME                                       READY   STATUS    RESTARTS   AGE
pod/backend-api-backend-xxxxx              1/1     Running   0          5m
pod/backend-api-backend-yyyyy              1/1     Running   0          5m
pod/frontend-web-frontend-aaaaa            1/1     Running   0          3m
pod/frontend-web-frontend-bbbbb            1/1     Running   0          3m

NAME                          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
service/backend-api-backend   ClusterIP   10.96.xxx.xxx    <none>        80/TCP
service/frontend-web-frontend NodePort    10.96.yyy.yyy    <none>        80:xxxxx/TCP

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/backend-api-backend   2/2     2            2           5m
deployment.apps/frontend-web-frontend 2/2     2            2           3m
```

### Step 27: Access the Application

```bash
minikube service frontend-web-frontend -n microservices --url
```

**Open the URL in your browser!**

You should see:
- A beautiful frontend page
- Release information
- Backend API response (JSON from the backend service)

---

## Part 6: Upgrade the Application

### Step 28: Upgrade Backend to v2

```bash
helm upgrade backend-api backend \
  --namespace microservices \
  --set apiVersion="v2" \
  --set replicaCount=3
```

### Step 29: Verify the Upgrade

```bash
helm history backend-api -n microservices
```

**Expected output:**
```
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         deployed    Upgrade complete
```

**Check pods:**
```bash
kubectl get pods -n microservices | grep backend
```

Should show 3 backend pods now.

### Step 30: Upgrade Frontend Environment

```bash
helm upgrade frontend-web frontend \
  --namespace microservices \
  --set backendService=backend-api-backend \
  --set environment=production \
  --set appTitle="Production Microservices"
```

**Refresh your browser** to see the changes:
- Title changed to "Production Microservices"
- Badge shows "PRODUCTION" (red)

---

## Part 7: Rollback (If Needed)

### Step 31: Simulate a Problem

Let's say the production upgrade was premature. Roll back:

```bash
helm rollback frontend-web 1 -n microservices
```

**Verify:**
```bash
helm history frontend-web -n microservices
```

**Expected output:**
```
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         deployed    Rollback to 1
```

---

## Part 8: Clean Up

### Step 32: Uninstall Everything

```bash
helm uninstall frontend-web -n microservices
helm uninstall backend-api -n microservices
```

### Step 33: Delete Namespace

```bash
kubectl delete namespace microservices
```

### Step 34: Verify Cleanup

```bash
helm list -n microservices
kubectl get namespace microservices
```

Both should return empty or "not found".

---

## Project Checklist

| Task | Completed |
|------|-----------|
| Created backend chart | ☐ |
| Created frontend chart | ☐ |
| Deployed to microservices namespace | ☐ |
| Backend tests passed | ☐ |
| Frontend tests passed | ☐ |
| Accessed application in browser | ☐ |
| Upgraded backend to v2 | ☐ |
| Upgraded frontend to production | ☐ |
| Performed rollback | ☐ |
| Cleaned up all resources | ☐ |

---

## What You Learned

1. **Creating charts** – Structured multiple services
2. **ConfigMaps** – Custom nginx configuration
3. **Service communication** – Backend/frontend proxy
4. **Namespaces** – Isolated deployment
5. **Testing** – Validated deployments
6. **Upgrades** – Changed configuration live
7. **Rollbacks** – Reverted changes
8. **Complete lifecycle** – Install → Upgrade → Rollback → Uninstall

---

## Bonus Challenges (Optional)

### Challenge 1: Add a Database

Create a third chart for Redis or PostgreSQL and connect the backend to it.

### Challenge 2: Add Resource Quotas

Add resource quotas to the microservices namespace.

### Challenge 3: Create an Umbrella Chart

Create a parent chart that includes both frontend and backend as dependencies.

### Challenge 4: CI/CD Simulation

Write a shell script that:
1. Lints both charts
2. Templates and validates
3. Deploys with --atomic
4. Runs tests
5. Rolls back on failure

---

**🎉 CONGRATULATIONS! You've completed the Helm Training Course!**

You now have the skills to:
- Create custom Helm charts
- Deploy and manage releases
- Test and debug charts
- Work with repositories and namespaces
- Handle the complete release lifecycle

**Welcome to the world of Kubernetes package management!**
