# How to Run — Fortress VNet

## Before You Start

Make sure you have these installed:

```bash
terraform --version   # needs to be >= 1.0
az --version          # Azure CLI
kubectl version       # Kubernetes CLI
ls ~/.ssh/id_rsa.pub  # SSH key
```

No SSH key? Run this:
```bash
ssh-keygen -t rsa -b 4096
```
Just hit Enter for all prompts.

---

## Step 1 — Login to Azure

```bash
az login
```

A browser window opens. Sign in. Come back to the terminal.

---

---

## Step 2 — Deploy the Infrastructure

The project is now configured to be **totally non-interactive**. All resource names are randomised automatically.

```bash
cd networking
terraform init
terraform apply -auto-approve
```

This will:
1. Create a unique resource group, VNet, AKS cluster, and Database.
2. Build and push your custom dashboard to ACR.
3. Deploy the application to AKS.

This takes about **10–15 minutes** (AKS and Application Gateway deployment).

---

## Step 3 — Access the Dashboard
Once the deployment finishes, the Application Gateway public IP will be displayed. Open your browser and navigate to:
```
http://<app_gateway_public_ip>
```
*(Note: It may take 5 minutes for the Gateway to finish its initial health checks).*

---

## Step 4 — Verify the Cluster and Gateway

When it finishes you'll see something like:
```
aks_cluster_name      = "Fortress-VNet-aks"
app_gateway_public_ip = "20.x.x.x"
acr_login_server      = "fortressvnetacrxxxx.azurecr.io"
db_server_fqdn        = "fortress-pg-xxx.private.postgres.database.azure.com"
```

### 5. Stunning Frontend Dashboard
- **Advanced Glassmorphism**: High-contrast blur and multi-layered shadows for a premium UI.
- **Dynamic Background**: Radial gradients and animated "data particles" for an immersive feel.
- **New Features**: Added a **Database** status tab and enhanced **Cluster Nodes** monitoring.
- **Micro-animations**: Smooth hover transitions and pulse indicators for high-fidelity interaction.

### Accessing the Cluster
Since the cluster is **Private**, you cannot reach it directly from the internet. You must:
1. Deploy a **Bastion Host** (uncommented in `compute.tf` - *coming soon*) or
2. Use a **VPN/Site-to-Site** connection.

### Accessing the Web App
Once you've deployed an ingress/service to AKS, you can reach it via:
```
http://<app_gateway_public_ip>
```
Note: It may take **5 minutes** for the Application Gateway to finish its initial provisioning.

---

## Authenticate to ACR
```bash
az acr login --name <acr_name>
```

---

## Connect to the Database

From an app VM (inside the VNet):
```bash
psql -h <db_server_fqdn> -U adminuser -d fortressdb
```

---

## Step 5 — Deploying the Custom Dashboard

Since we've replaced the default Nginx page with a custom dashboard, you need to build and push the image to ACR:

**1. Build the Docker Image:**
```bash
cd dashboard
docker build -t fortressvnetacr3x3rgz.azurecr.io/fortress-dashboard:v2 .
```

**2. Push to ACR:**
```bash
# Ensure you are logged in (from Step 4)
docker push fortressvnetacr3x3rgz.azurecr.io/fortress-dashboard:v2
```

**3. Apply to Kubernetes:**
```bash
cd ../k8s
kubectl apply -f fortress-app.yaml
kubectl apply -f fortress-ingress.yaml
```

**4. Access the Dashboard:**
Open your browser and navigate to the `app_gateway_public_ip` (from Step 4 output).

---

## Teardown — Delete Everything

Type `yes` at each prompt.

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `No subscription found` | Run `az login` again |
| `ssh-key not found` | Run `ssh-keygen -t rsa -b 4096` |
| Gateway error 502/404 | Initial provisioning can take up to 10 minutes |
| `kubectl` not connecting | Ensure you are connected to the VNet (private cluster) |
| `Backend config changed` | Run `rm -rf .terraform` then `terraform init` again |

---

## Setting Up CI/CD (GitHub Actions)

To make GitHub automatically deploy on every merge:

**1. Create an Azure Service Principal:**
```bash
az ad sp create-for-rbac \
  --name "fortress-vnet-github" \
  --role Contributor \
  --scopes /subscriptions/<your-subscription-id>
```

**2. Add these 5 secrets to GitHub** → Settings → Secrets → Actions:

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | `clientId` from above |
| `AZURE_CLIENT_SECRET` | `clientSecret` from above |
| `AZURE_SUBSCRIPTION_ID` | Your subscription ID |
| `AZURE_TENANT_ID` | `tenantId` from above |
| `TF_DB_PASSWORD` | Your DB password |

**3. Uncomment the backend block** in `networking/provider.tf` and fill in your storage account name.

**4. Push to GitHub** — the workflow runs automatically.
