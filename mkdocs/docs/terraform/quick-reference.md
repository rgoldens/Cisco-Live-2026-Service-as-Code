# Quick Reference

| Command | What it does |
|---|---|
| `terraform init` | Initialize working directory, link providers |
| `terraform plan` | Preview changes — safe, makes no modifications |
| `terraform apply -auto-approve` | Deploy or update infrastructure to match config |
| `terraform destroy -auto-approve` | Remove all Terraform-managed resources |
| `terraform show` | Display current state in human-readable form |
| `terraform output` | Print output values |
| `docker ps --filter name=terraform` | Check which terraform containers are running |
| `docker logs -f csr-terraform` | Follow CSR boot log |
| `curl -sk -u admin:admin -H "Accept: application/yang-data+json" https://172.20.21.10/restconf/...` | Query CSR via RESTCONF |
