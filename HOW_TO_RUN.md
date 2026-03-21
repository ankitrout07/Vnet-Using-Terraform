# How to Run — Fortress VNet

## Before You Start

Make sure you have these installed:

```bash
terraform --version   # needs to be >= 1.0
az --version          # Azure CLI
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

## Step 2 — Create the Remote Backend (first time only)

```bash
cd backend-init
terraform init
terraform apply
```

Type `yes` when asked. When it finishes, **copy the `storage_account_name` value** it prints — you'll need it later.

---

## Step 3 — Deploy the Infrastructure

```bash
cd ../networking
terraform init
terraform apply -var="db_password=YourPassword123!"
```

Type `yes`. This takes about **5–8 minutes**.

---

## Step 4 — Open the Webpage

When it finishes you'll see something like:

```
lb_public_ip      = "20.x.x.x"
bastion_public_ip = "20.y.y.y"
db_server_fqdn    = "fortress-pg-xxx.private.postgres.database.azure.com"
```

Open your browser and go to:
```
http://<lb_public_ip>
```

You'll see the Fortress VNet dashboard. It may take **2–3 minutes** for the VMs to fully boot.

---

## SSH into the Bastion

```bash
ssh adminuser@<bastion_public_ip>
```

From the Bastion, you can then SSH into private app VMs.

---

## Connect to the Database

From an app VM (inside the VNet):
```bash
psql -h <db_server_fqdn> -U adminuser -d fortressdb
```

---

## Teardown — Delete Everything

When you're done, destroy all resources to avoid Azure charges:

```bash
cd networking
terraform destroy

cd ../backend-init
terraform destroy
```

Type `yes` at each prompt.

---

## Common Issues

| Problem | Fix |
|---------|-----|
| `No subscription found` | Run `az login` again |
| `ssh-key not found` | Run `ssh-keygen -t rsa -b 4096` |
| Webpage not loading | Wait 2–3 min after deploy, VMs are still booting |
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
