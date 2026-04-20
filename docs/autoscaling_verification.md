# Verification Guide: AKS Autoscaling & Real-Time Observability

This guide provides a comprehensive technical walkthrough of how traffic triggers autoscaling inside the FORTRESS VNet and how every stage is observable — from the Application Gateway to the WebSocket dashboard.

---

## End-to-End Flow

```
ApacheBench (Load Generator)
       ↓
Application Gateway (WAF v2 — L7 Inspection)
       ↓
AKS Pods in AppSubnet (10.0.10.0/24)
       ↓
Metrics Server detects CPU > threshold
       ↓
HPA increases Desired Replicas
       ↓
New Pods provisioned via Azure CNI (get VNet IPs)
       ↓
AGIC syncs new Pod IPs → App Gateway Backend Pool
       ↓
Dashboard WebSocket emits updated pod list → UI updates in real-time
```

---

## 1. The Traffic Flow (The "Trigger")

When you send a surge of traffic to the public IP of the Application Gateway, it evaluates the Layer 7 rules and WAF policies before routing the requests to the AKS pods.

- **Metric Collection**: As the pods handle these requests, the Kubernetes Metrics Server (integrated into AKS) constantly monitors the CPU and Memory utilization of every pod in the `10.0.10.0/24` subnet.
- **The Threshold**: If you have an HPA configured (e.g., scale up if CPU > 50%), the Metrics Server detects the breach and signals the Kubernetes Control Plane.

---

## 2. The Real-Time Scaling Mechanism

Once the threshold is hit, the following happens within the VNet:

### A. HPA Execution
Kubernetes increases the "Desired Replicas" count in the Deployment manifest automatically.

### B. Pod Provisioning
New pods are spun up on your AKS Node Pools. Thanks to **Azure CNI**, these new pods immediately pull available IPs from your AKS subnet and register themselves with the VNet's internal routing table.

### C. AGIC Sync
The Application Gateway Ingress Controller detects the new pod IPs and automatically updates the Application Gateway's **Backend Pool**. Traffic is then distributed across the newly scaled pods without dropping a single packet.

---

## 3. Monitoring via the Dashboard ("Single Pane of Glass")

The custom-built Node.js/WebSocket dashboard acts as the visual observer for this entire cycle:

### The Bridge
The dashboard backend (`server.js`) uses `@kubernetes/client-node` to query `listNamespacedPod("default")` every **2 seconds**.

### The Stream
As the HPA increases the replica count and new pods appear, the backend catches the updated pod list and pushes a JSON payload via **Socket.io WebSockets** to all connected browsers.

### The Visualization
On the UI, you see:

| UI Element | What It Shows |
|------------|---------------|
| **Pod Counter Card** (Overview tab) | Live total pod count with animated gradient number |
| **Scaling Tag** | `STABLE` → `SCALING UP` (amber pulse) → `SCALING DOWN` (blue) |
| **Pod Card Grid** (Cluster Nodes tab) | A card per pod: name, status (Running/Pending), IP, assigned node |
| **Operational Terminal** | Auto-logged entries: `HPA Triggered: Scaling from 2 → 8 pods` |

You can visually correlate inbound request volume with the active pod count in real-time.

---

## 4. Verification Steps

### 4.1 Verify Horizontal Pod Autoscaler (HPA)

HPA scales the number of pod replicas based on CPU or memory utilization.

**Check HPA Status:**
```bash
kubectl get hpa
```
You should see `fortress-hpa` with a target utilization (e.g., `0%/50%`) and the current number of replicas.

**Simulate Load for HPA:**
```bash
kubectl run -i --tty load-generator --rm --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://fortress-service; done"
```

*Open a second terminal to monitor the scaling:*
```bash
kubectl get hpa fortress-hpa --watch
```
As the CPU utilization rises above 50%, you will see the `REPLICAS` count increase from 2 towards 5.

---

### 4.2 Verify Cluster Autoscaler (CA)

Cluster Autoscaler adds or removes nodes in your AKS cluster when pods cannot be scheduled due to resource constraints.

**Check Node Count:**
```bash
kubectl get nodes
```

**Trigger Cluster Scaling:**
```bash
kubectl scale deployment fortress-web --replicas=20
```
Wait a few minutes and check the node status. Pods will likely be in `Pending` state initially, which triggers the CA to add a new node.

**Monitor CA Activity:**
```bash
kubectl get configmap cluster-autoscaler-status -n kube-system -o yaml
```
Look for `status:` and `ReadableStatus:` in the output to see if it's currently "Scaling" or "Healthy".

---

### 4.3 Simulate Production Traffic (ApacheBench)

This is the full end-to-end test — traffic hits the Application Gateway, triggers HPA, and the dashboard shows it live.

```bash
# Simulate 10,000 requests with 50 concurrent users
ab -n 10000 -c 50 http://<APP_GATEWAY_IP>/
```

**What you'll observe on the dashboard:**

| Phase | Pod Counter | Scaling Tag | Terminal Log |
|-------|-------------|-------------|--------------|
| **Before load** | 2 | `STABLE` | — |
| **During load** | 2 → 4 → 8+ | `SCALING UP` (pulsing amber) | `HPA Triggered: Scaling from 2 → 8 pods` |
| **After load** | 8 → 4 → 2 | `SCALING DOWN` (blue) | `Workload decreased: Scaling down to 2 pods` |

For heavier load testing:
```bash
# Aggressive burst: 20,000 requests with 200 concurrent users
ab -n 20000 -c 200 http://<APP_GATEWAY_IP>/
```

---

### 4.4 Visual Verification via Dashboard

1. **Open the Dashboard** → `http://<APP_GATEWAY_IP>/`
2. **Overview Tab** → Watch the Pod Counter card and Scaling Tag
3. **Cluster Nodes Tab** → Watch pod cards appear/disappear as scaling happens
4. **Operational Terminal** → Read the auto-logged scaling events

The dashboard updates every **2 seconds** via WebSocket — no page refresh needed.

---

## 5. Useful Troubleshooting Commands

| Command | Purpose |
|---------|---------|
| `kubectl describe hpa fortress-hpa` | Detailed HPA status and events |
| `kubectl get events --sort-by='.lastTimestamp'` | Recent cluster events |
| `kubectl top pods` | Real-time CPU/memory per pod (requires Metrics Server) |
| `kubectl top nodes` | Real-time CPU/memory per node |
| `kubectl get pods -w` | Watch pod creation/termination live |
| `az aks show --resource-group YOUR_RG --name YOUR_AKS_NAME --query "agentPoolProfiles[0].count"` | Current node count from Azure |
