# =============================================================================
# Makefile — Service as Code Lab
# Cisco Live 2026
#
# Usage:  make help
# =============================================================================

.PHONY: help deploy destroy redeploy inspect \
        ansible-install provision-l3vpn provision-evpn validate \
        tf-init tf-plan tf-apply tf-destroy \
        pip-install clean

TOPOLOGY   := topology/sac-lab.yml
INVENTORY  := ansible/inventory/hosts.yml
PLAYBOOKS  := ansible/playbooks
TF_DIR     := terraform

# --- Default target ---
help: ## Show this help
	@echo ""
	@echo "Service as Code Lab — Cisco Live 2026"
	@echo "======================================"
	@echo ""
	@echo "Containerlab:"
	@echo "  make deploy          Deploy the containerlab topology"
	@echo "  make destroy         Destroy the containerlab topology"
	@echo "  make redeploy        Destroy + re-deploy the topology"
	@echo "  make inspect         Show running lab nodes and IPs"
	@echo ""
	@echo "Setup:"
	@echo "  make pip-install     Install Python dependencies"
	@echo "  make ansible-install Install Ansible Galaxy collections"
	@echo ""
	@echo "Ansible path:"
	@echo "  make provision-l3vpn Deploy L3VPN services via Ansible"
	@echo "  make provision-evpn  Deploy EVPN/VXLAN services via Ansible"
	@echo "  make validate        Run post-deploy validation"
	@echo ""
	@echo "Terraform path (full alternative):"
	@echo "  make tf-init         Initialize Terraform providers"
	@echo "  make tf-plan         Plan L3VPN changes"
	@echo "  make tf-apply        Apply L3VPN changes"
	@echo "  make tf-destroy      Destroy Terraform-managed resources"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean           Remove Terraform state and clab artifacts"
	@echo ""

# =============================================================================
# CONTAINERLAB
# =============================================================================
deploy: ## Deploy the containerlab topology
	sudo containerlab deploy -t $(TOPOLOGY)

destroy: ## Destroy the containerlab topology
	sudo containerlab destroy -t $(TOPOLOGY)

redeploy: ## Destroy and re-deploy the topology
	sudo containerlab destroy -t $(TOPOLOGY) --cleanup
	sudo containerlab deploy -t $(TOPOLOGY)

inspect: ## Show running lab nodes and management IPs
	sudo containerlab inspect -t $(TOPOLOGY)

# =============================================================================
# SETUP
# =============================================================================
pip-install: ## Install Python dependencies from requirements.txt
	pip install -r requirements.txt

ansible-install: ## Install Ansible Galaxy collections
	ansible-galaxy collection install -r ansible/requirements.yml --force

# =============================================================================
# ANSIBLE PATH
# =============================================================================
provision-l3vpn: ## Deploy L3VPN services via Ansible
	ansible-playbook -i $(INVENTORY) $(PLAYBOOKS)/deploy_l3vpn.yml

provision-evpn: ## Deploy EVPN/VXLAN services via Ansible
	ansible-playbook -i $(INVENTORY) $(PLAYBOOKS)/deploy_evpn.yml

validate: ## Run post-deploy validation playbook
	ansible-playbook -i $(INVENTORY) $(PLAYBOOKS)/validate.yml

# =============================================================================
# TERRAFORM PATH (full alternative to Ansible)
# =============================================================================
tf-init: ## Initialize Terraform providers
	cd $(TF_DIR) && terraform init

tf-plan: ## Plan L3VPN service changes
	cd $(TF_DIR) && terraform plan

tf-apply: ## Apply L3VPN service changes
	cd $(TF_DIR) && terraform apply -auto-approve

tf-destroy: ## Destroy Terraform-managed resources
	cd $(TF_DIR) && terraform destroy -auto-approve

# =============================================================================
# MAINTENANCE
# =============================================================================
clean: ## Remove Terraform state and containerlab artifacts
	rm -rf $(TF_DIR)/.terraform $(TF_DIR)/.terraform.lock.hcl $(TF_DIR)/terraform.tfstate*
	rm -rf clab-sac-lab
