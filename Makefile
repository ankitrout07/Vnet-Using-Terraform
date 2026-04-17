.PHONY: init infra get-creds docker-build k8s-deploy deploy

# Variables
TF_DIR = networking
TF_INIT_DIR = backend-init
K8S_DIR = k8s

# 1. Initialize Terraform (Backend & Networking)
init:
	@echo "==> Initializing Terraform Backend..."
	cd $(TF_INIT_DIR) && terraform init && terraform apply -auto-approve
	@echo "==> Initializing Networking Module..."
	cd $(TF_DIR) && terraform init

# 2. Provision Hard Infrastructure
infra:
	@echo "==> Provisioning Hard Infrastructure with Terraform..."
	cd $(TF_DIR) && terraform apply -auto-approve

# 3. Get Credentials for AKS
get-creds:
	@echo "==> Fetching AKS Credentials..."
	@RG=$$(cd $(TF_DIR) && terraform output -raw resource_group_name); \
	AKS=$$(cd $(TF_DIR) && terraform output -raw aks_cluster_name); \
	az aks get-credentials --resource-group $$RG --name $$AKS --overwrite-existing

# 4. Build and Push Dashboard Image
docker-build:
	@echo "==> Building and Pushing Dashboard Image..."
	@ACR=$$(cd $(TF_DIR) && terraform output -raw acr_login_server); \
	ACR_NAME=$$(echo $$ACR | cut -d'.' -f1); \
	az acr login --name $$ACR_NAME; \
	docker build -t $$ACR/fortress-dashboard:v4-cyber ./dashboard; \
	docker push $$ACR/fortress-dashboard:v4-cyber; \
	echo "==> Updating image URL in K8s manifest..."; \
	sed -i "s|image: .*fortress-dashboard:.*|image: $$ACR/fortress-dashboard:v4-cyber|g" $(K8S_DIR)/fortress-app.yaml

# 5. Deploy Soft Infrastructure (Kubernetes)
k8s-deploy:
	@echo "==> Deploying Soft Infrastructure (K8s manifests)..."
	kubectl apply -f $(K8S_DIR)/

# Orchestrate Everything
deploy: infra get-creds docker-build k8s-deploy
	@echo "==> Deployment Complete! <=="
