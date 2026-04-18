# Project Documentation: Fortress VNet

Production-grade, secure 3-Tier Virtual Network on Azure, fully provisioned with Terraform. Features a private AKS cluster protected by an Application Gateway.

---

## 1. Architecture Overview

### Logical Design
```
Internet
   ↓
Application Gateway (WAF-ready + AGIC)
   ↓
Private AKS Cluster (Azure CNI) ↔ Redis Cache
   ↓
Private Services (Bastion)
   ↓
PostgreSQL Flexible Server (Private DNS)
```

### Infrastructure Tiers
1.  **Tier 1: Gateway (Public)**: Azure Application Gateway v2 provides L7 load balancing and edge security (WAF).
2.  **Tier 2: App (Private)**: Private AKS Cluster running the monitoring dashboard. Pods receive VNet IPs via Azure CNI.
3.  **Tier 3: DB (Isolated)**: PostgreSQL Flexible Server v15 in a delegated subnet with zero public access.
4.  **Tier 4: Cache (Private)**: Redis Standard C1 for high-performance session and data caching.
5.  **Tier 5: Access (Public/Private)**: Azure Bastion Service for secure, browser-based RDP/SSH access.

> [!NOTE]
> All infrastructure components, including the Terraform state storage and networking resources, are now consolidated into a **single, shared Resource Group** for streamlined management and improved visibility.

---

## 2. Project Structure

```
.
├── dashboard/             # Custom Monitoring Dashboard (HTML/CSS)
├── k8s/                   # Kubernetes Manifests (App, Service, Ingress)
├── networking/            # Root Terraform Module
│   ├── main.tf            # Logic to wire VNet, AKS, ACR, and DB
│   └── modules/
│       ├── networking/    # VNet, Subnets, NSGs, NAT Gateway
│       ├── aks/           # Private Cluster + AGIC Add-on
│       ├── app_gateway/   # Application Gateway v2
│       ├── acr/           # Container Registry
│       ├── database/      # PostgreSQL + Private DNS
│       ├── redis/         # Redis Cache + Private Endpoint
│       └── bastion/       # Azure Bastion Service
├── ARCHITECTURE.md        # Detailed component breakdown
└── HOW_TO_RUN.md          # Original quick-start guide
```

---

## 3. Building and Deployment Guide

### Automated Deployment (Recommended)
The project is configured for non-interactive deployment.
```bash
cd networking
terraform init
terraform apply -auto-approve
```
*This handles infrastructure provisioning, Docker image build/push to ACR, and initial Kubernetes deployment.*

### Manual Application Updates
If the dashboard code changes, follow these steps:
1.  **Build & Push**:
    ```bash
    LOGIN_SERVER=$(terraform output -raw acr_login_server)
    docker build -t $LOGIN_SERVER/fortress-dashboard:v2 ./dashboard
    docker push $LOGIN_SERVER/fortress-dashboard:v2
    ```
2.  **Update K8s**:
    ```bash
    az aks get-credentials --resource-group <RG_NAME> --name <AKS_NAME>
    kubectl apply -f k8s/fortress-app.yaml
    kubectl apply -f k8s/fortress-ingress.yaml
    ```

---

## 4. Recent Troubleshooting & Fixes

### Fix 1: `fortress_web` Rollout Failure
- **Issue**: Pods stuck in `ImagePullBackOff`.
- **Cause**: Image name discrepancy and missing identity metadata in Terraform state (tainted resource).
- **Resolution**: Re-imported the deployment into Terraform and manually pushed the correct image tag (`v2`) to ACR.

### Fix 2: 502 Bad Gateway (AGIC Sync)
- **Issue**: Application Gateway backend pools were empty despite healthy pods.
- **Cause**: AGIC Add-on uses a platform-managed identity that didn't match the one tracked in the initial Terraform state, leading to silent permission failures.
- **Resolution**: 
  - Refreshed Terraform state (`terraform apply -refresh-only`) to capture the auto-generated AGIC identity ID.
  - Granted `Network Contributor` and `Contributor` roles to the correct identity.
  - Modernized Ingress to use `spec.ingressClassName: azure-application-gateway`.
  - Restarted the AGIC pod to force a full re-sync.

---

## 5. Status and Verification

- **Dashboard URL**: `http://<app_gateway_public_ip>`
- **Backend Health**: All replicas are "Ready" and joined to the Application Gateway's backend pool.
- **Database**: Reachable only from within the VNet via its private FQDN.
- **ACR**: Fully integrated with AKS for secure ImagePull.
