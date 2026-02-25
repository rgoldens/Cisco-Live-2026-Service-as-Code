# Service as Code Lab — Cisco Live 2026

Hands-on lab demonstrating network service provisioning as code using Ansible, Terraform, and YAML service definitions on a containerlab topology with Cisco XRd, CSR1000v, and Nexus 9000v.

## Overview

This lab teaches the **Service as Code** approach to network operations: define services as structured data (YAML), render device config with templates (Jinja2/HCL), push with automation (Ansible or Terraform), and validate with assertions.

**Session:** 4 hours | **Attendees:** 30 (individual lab instances)

### Topology

```
            ┌─────────┐          ┌─────────┐
            │  xrd01  │──────────│  xrd02  │      IOS-XR  (P / Route Reflector)
            │  (P/RR) │          │  (P/RR) │      IS-IS + LDP + BGP VPNv4 RR
            └────┬────┘          └────┬────┘
                 │                    │
            ┌────┴────┐          ┌────┴────┐
            │csr-pe01 │──────────│csr-pe02 │      IOS-XE  (PE router)
            │  (PE)   │          │  (PE)   │      IS-IS + LDP + VRF + BGP VPNv4
            └────┬────┘          └────┬────┘
                 │                    │
            ┌────┴────┐          ┌────┴────┐
            │n9k-ce01 │──────────│n9k-ce02 │      NX-OS   (CE / DC switch)
            │  (CE)   │          │  (CE)   │      OSPF + VXLAN/EVPN
            └────┬────┘          └─────────┘
                 │
            ┌────┴──────┐
            │linux-client│                         Alpine Linux (test endpoint)
            └───────────┘
```

**7 nodes** | 2 XRd P-routers | 2 CSR1000v PEs | 2 N9Kv CEs | 1 Linux client

## Project Structure

```
.
├── Makefile                        # All lab operations (deploy, provision, validate)
├── requirements.txt                # Python dependencies
├── INSTRUCTOR_CHECKLIST.md         # Pre-session setup checklist
├── PRESENTATION_OUTLINE.md         # 11-module session outline (4 hours)
├── STUDENT_LAB_GUIDE.md            # Step-by-step lab exercises
│
├── topology/
│   └── sac-lab.yml                 # Containerlab topology definition
│
├── configs/                        # Startup configs (underlay pre-configured)
│   ├── xrd01.cfg                   # IOS-XR: IS-IS, LDP, BGP RR
│   ├── xrd02.cfg
│   ├── csr-pe01.cfg                # IOS-XE: IS-IS, LDP, BGP VPNv4, NETCONF
│   ├── csr-pe02.cfg
│   ├── n9k-ce01.cfg                # NX-OS: OSPF underlay
│   └── n9k-ce02.cfg
│
├── services/                       # Source of Truth (YAML service definitions)
│   ├── l3vpn/
│   │   ├── vars/
│   │   │   ├── customer_a.yml      # Customer A L3VPN definition
│   │   │   └── customer_b.yml      # Customer B L3VPN definition
│   │   └── templates/
│   │       ├── csr_pe_l3vpn.j2     # IOS-XE L3VPN template
│   │       └── xrd_p_bgp.j2        # IOS-XR BGP RR template
│   └── evpn/
│       ├── vars/
│       │   └── vxlan_tenant.yml    # EVPN/VXLAN tenant definition
│       └── templates/
│           └── n9k_evpn.j2         # NX-OS EVPN template
│
├── ansible/                        # Ansible automation path
│   ├── requirements.yml            # Galaxy collections
│   ├── inventory/
│   │   ├── hosts.yml               # Device inventory
│   │   └── group_vars/
│   │       ├── all.yml             # Shared variables
│   │       ├── xrd.yml             # IOS-XR connection settings
│   │       ├── csr.yml             # IOS-XE connection settings
│   │       └── n9kv.yml            # NX-OS connection settings
│   └── playbooks/
│       ├── deploy_l3vpn.yml        # L3VPN provisioning
│       ├── deploy_evpn.yml         # EVPN/VXLAN provisioning
│       └── validate.yml            # Post-deploy validation
│
├── terraform/                      # Terraform automation path (full alternative)
│   ├── providers.tf                # CiscoDevNet/iosxe + iosxr providers
│   ├── variables.tf                # Variable definitions
│   ├── terraform.tfvars            # Variable values (mirrors YAML SoT)
│   ├── l3vpn.tf                    # L3VPN resource definitions
│   └── outputs.tf                  # Output definitions
│
└── scripts/
    └── deploy-all.sh               # Batch deployment for 30 instances
```

## Quick Start

### Prerequisites

- Linux host (Ubuntu 22.04+ or RHEL 9+)
- Docker 24.x+
- [containerlab](https://containerlab.dev/install/) 0.55+
- Python 3.10+
- Terraform 1.5+
- Docker images:
  - `ios-xr/xrd-control-plane:25.1.1`
  - `vrnetlab/cisco_csr1000v:<tag>` (build from .qcow2 via [vrnetlab](https://github.com/hellt/vrnetlab))
  - `vrnetlab/cisco_n9kv:<tag>` (build from .qcow2 via vrnetlab)

### Deploy the Lab

```bash
cd ~/sac-lab

# Install dependencies
make pip-install
make ansible-install

# Deploy the topology (wait ~10 min for all nodes to boot)
make deploy

# Check that all 7 nodes are running
make inspect
```

### Provision Services

**Ansible path:**

```bash
make provision-l3vpn     # Deploy L3VPN on PE routers
make provision-evpn      # Deploy EVPN/VXLAN on CE switches
make validate            # Run validation checks
```

**Terraform path (alternative):**

```bash
make tf-init             # Download providers
make tf-plan             # Preview changes
make tf-apply            # Apply L3VPN resources
```

### Add a New Customer

Create a YAML file in `services/l3vpn/vars/`:

```yaml
customer: CustomerC
vrf: CUST_C
rd: "65000:300"
rt_import: "65000:300"
rt_export: "65000:300"
description: "Customer C - New L3VPN"

pe_interfaces:
  - node: csr-pe01
    interface: GigabitEthernet2
    vrf_ip: 10.200.1.1/24
    description: "CUST_C CE-facing"
    ce_neighbor:
      ip: 10.200.1.2
      remote_as: 65100
```

Then run:

```bash
make provision-l3vpn
make validate
```

That's it. YAML in, service out.

## Credentials

| Device | Username | Password |
|--------|----------|----------|
| XRd (IOS-XR) | `clab` | `clab@123` |
| CSR1000v (IOS-XE) | `admin` | `admin` |
| N9Kv (NX-OS) | `admin` | `admin` |

## Batch Operations (30 Instances)

For deploying across all 30 attendee hosts:

```bash
# Create a hosts.txt file with one IP per line
# Then use the batch script:
./scripts/deploy-all.sh deploy          # Deploy all labs (staggered)
./scripts/deploy-all.sh verify          # Verify all instances
./scripts/deploy-all.sh status          # Quick status check
./scripts/deploy-all.sh destroy         # Tear down all labs
./scripts/deploy-all.sh setup           # Install deps on all hosts
./scripts/deploy-all.sh update-inventory # Update Ansible inventory IPs
```

See `INSTRUCTOR_CHECKLIST.md` for the full pre-session setup procedure.

## Resource Requirements (Per Instance)

| Resource | Minimum |
|----------|---------|
| vCPUs | 12 |
| RAM | 24 GB |
| Disk | 40 GB |

N9Kv nodes use the `n9kv-lite` profile (6 GB RAM, 2 vCPUs each).

## Documentation

- `PRESENTATION_OUTLINE.md` — 11-module session outline with timings
- `STUDENT_LAB_GUIDE.md` — step-by-step exercise instructions
- `INSTRUCTOR_CHECKLIST.md` — pre-session setup and emergency procedures

## Kernel Tuning (Required for XRd)

```bash
sudo sysctl -w fs.inotify.max_user_instances=64000
sudo sysctl -w fs.inotify.max_user_watches=64000
```
