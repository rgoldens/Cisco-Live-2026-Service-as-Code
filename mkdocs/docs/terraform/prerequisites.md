# Prerequisites

The lab server already has everything pre-installed and initialized:

| Tool | Version | Location |
|---|---|---|
| Terraform | v1.14.7 | `/usr/bin/terraform` |
| Docker | 27.5.1 | `/usr/bin/docker` |
| `sshpass` | — | `/usr/bin/sshpass` |
| `kreuzwerker/docker` provider | 3.9.0 | `~/.terraform.d/plugins/` |
| `CiscoDevNet/iosxe` provider | 0.16.0 | `~/.terraform.d/plugins/` |

!!! note
    The server has no internet access to the Terraform registry. Providers are
    pre-installed in a local filesystem mirror. `terraform init` reads from there — no
    download needed.

All Terraform files are in: **`~/terraform-lab/terraform/`**

---

!!! tip "Up next"
    Continue to [Part 1 — Explore the Configuration](part1-explore.md) to read through the Terraform files.
