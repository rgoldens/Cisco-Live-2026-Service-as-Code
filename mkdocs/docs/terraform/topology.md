# Lab Topology

![What This Lab Builds](../../slides/slide-04-what-we-build.png)
![Lab Topology](../../slides/slide-05-topology.png)

This Terraform lab runs **independently** of the main ContainerLab topology. It uses a
separate Docker bridge network and does not interfere with the LTRATO-1001 nodes.

| Container | Image | IP | Role |
|---|---|---|---|
| `csr-terraform` | `vrnetlab/vr-csr:16.12.05` | `172.20.21.10` | Cisco IOS XE router — Terraform target |
| `linux-terraform1` | `ghcr.io/hellt/network-multitool` | `172.20.21.20` | Linux client |
| `linux-terraform2` | `ghcr.io/hellt/network-multitool` | `172.20.21.21` | Linux client |

**Terraform also configures the CSR via RESTCONF:**

- Hostname → `csr-terraform`
- Loopback0 → `10.99.99.1/32` (description: "Managed by Terraform")
