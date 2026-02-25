# =============================================================================
# STUDENT LAB GUIDE
# Service as Code Lab — Cisco Live 2026
#
# Duration: 4 hours
# Format:   Individual lab instances (one per attendee)
# =============================================================================

---

## Before You Begin

### Your Lab Environment

You have a dedicated Linux host running Docker and containerlab with a 7-node
network topology already deployed. Everything runs on your host — no shared
infrastructure.

### Connection Info

| Item | Value |
|------|-------|
| Lab host | `<your-assigned-IP>` (see lab assignment sheet) |
| SSH user | `<provided by instructor>` |
| Lab directory | `~/sac-lab` |

```bash
ssh <user>@<your-assigned-IP>
cd ~/sac-lab
```

### Device Credentials

| Device | Username | Password |
|--------|----------|----------|
| XRd (xrd01, xrd02) | `clab` | `clab@123` |
| CSR1000v (csr-pe01, csr-pe02) | `admin` | `admin` |
| N9Kv (n9k-ce01, n9k-ce02) | `admin` | `admin` |
| Linux client | (use `docker exec`) | n/a |

### Quick Command Reference

```
make help              Show all available commands
make inspect           Show running nodes and management IPs
make provision-l3vpn   Deploy L3VPN via Ansible
make provision-evpn    Deploy EVPN/VXLAN via Ansible
make validate          Run post-deploy validation
make tf-init           Initialize Terraform
make tf-plan           Preview Terraform changes
make tf-apply          Apply Terraform changes
make tf-destroy        Destroy Terraform-managed resources
```

### Topology Diagram

```
                    ┌─────────┐          ┌─────────┐
                    │  xrd01  │──────────│  xrd02  │
                    │  (P/RR) │ P-P core │  (P/RR) │
                    └────┬────┘          └────┬────┘
                         │                    │
                    ┌────┴────┐          ┌────┴────┐
                    │csr-pe01 │──────────│csr-pe02 │
                    │  (PE)   │ inter-PE │  (PE)   │
                    └────┬────┘          └────┬────┘
                         │                    │
                    ┌────┴────┐          ┌────┴────┐
                    │n9k-ce01 │──────────│n9k-ce02 │
                    │  (CE)   │ DC link  │  (CE)   │
                    └────┬────┘          └─────────┘
                         │
                    ┌────┴──────┐
                    │linux-client│
                    └───────────┘
```

### Addressing Plan

| Node | Loopback0 | Role |
|------|-----------|------|
| xrd01 | 10.0.0.1/32 | P-router / Route Reflector |
| xrd02 | 10.0.0.2/32 | P-router / Route Reflector |
| csr-pe01 | 10.0.0.11/32 | PE router (west) |
| csr-pe02 | 10.0.0.12/32 | PE router (east) |
| n9k-ce01 | 10.0.0.21/32 | CE/DC switch (west) |
| n9k-ce02 | 10.0.0.22/32 | CE/DC switch (east) |

| Link | Subnet |
|------|--------|
| P-P core (xrd01 ↔ xrd02) | 10.0.0.0/30 |
| P-PE west (xrd01 ↔ csr-pe01) | 10.0.1.0/30 |
| P-PE east (xrd02 ↔ csr-pe02) | 10.0.1.4/30 |
| Inter-PE (csr-pe01 ↔ csr-pe02) | 10.0.2.0/30 |
| PE-CE west (csr-pe01 ↔ n9k-ce01) | 10.0.3.0/30 |
| PE-CE east (csr-pe02 ↔ n9k-ce02) | 10.0.3.4/30 |
| DC inter-switch (n9k-ce01 ↔ n9k-ce02) | 10.0.4.0/30 |
| Client subnet | 192.168.100.0/24 |

---

## Exercise 0: Verify Your Environment

**Time:** 5-10 minutes
**Goal:** Confirm your lab is deployed and all nodes are accessible.

### Step 1: Check running containers

```bash
make inspect
```

You should see **7 nodes** with status "running" and management IPs in the
172.20.20.0/24 range.

**Write down your management IPs** — you'll need them throughout the lab:

```
xrd01:        172.20.20.___
xrd02:        172.20.20.___
csr-pe01:     172.20.20.___
csr-pe02:     172.20.20.___
n9k-ce01:     172.20.20.___
n9k-ce02:     172.20.20.___
linux-client: 172.20.20.___
```

### Step 2: Test SSH to each device type

```bash
# XRd — uses clab/clab@123
ssh clab@<xrd01-ip>
# Type: show version
# Type: exit

# CSR — uses admin/admin
ssh admin@<csr-pe01-ip>
# Type: show version
# Type: exit

# N9Kv — uses admin/admin
ssh admin@<n9k-ce01-ip>
# Type: show version
# Type: exit
```

### Step 3: Verify the project files

```bash
ls -la ~/sac-lab/
```

You should see: `ansible/`, `configs/`, `Makefile`, `requirements.txt`,
`services/`, `terraform/`, `topology/`

### Checkpoint

- [ ] 7/7 containers running
- [ ] SSH works to xrd01, csr-pe01, and n9k-ce01
- [ ] Project directory contains all expected folders

> **Stuck?** Raise your hand — the instructor can help troubleshoot SSH or
> container issues. If a node isn't responding, it may still be booting
> (N9Kv takes up to 8 minutes).

---

## Exercise 1: Explore the Underlay

**Time:** 15 minutes
**Goal:** Verify that IS-IS, LDP, and BGP underlay protocols are operational
before we provision any services.

### Step 1: Check IS-IS on a P-router

SSH to xrd01:

```bash
ssh clab@<xrd01-ip>
```

Run these commands:

```
show isis neighbors
```

**Expected:** Two IS-IS adjacencies — one to xrd02, one to csr-pe01. Both
should show state `Up`.

```
show isis database brief
```

**Expected:** LSPs from all IS-IS-speaking nodes (xrd01, xrd02, csr-pe01,
csr-pe02).

```
exit
```

### Step 2: Check LDP on a PE router

SSH to csr-pe01:

```bash
ssh admin@<csr-pe01-ip>
```

Run these commands:

```
show isis neighbors
```

**Expected:** Two IS-IS adjacencies — one to xrd01, one to csr-pe02.

```
show mpls ldp neighbor
```

**Expected:** LDP sessions with xrd01 and csr-pe02 (and possibly xrd02
indirectly).

```
show bgp vpnv4 unicast all summary
```

**Expected:** BGP neighbors 10.0.0.1 (xrd01) and 10.0.0.2 (xrd02) in
`Established` state. These are the Route Reflectors.

```
show ip vrf
```

**Expected:** No VRFs yet (or only a default). This is correct — we haven't
provisioned any services yet.

```
exit
```

### Step 3: Check OSPF underlay on a CE switch

SSH to n9k-ce01:

```bash
ssh admin@<n9k-ce01-ip>
```

Run these commands:

```
show ip ospf neighbors
```

**Expected:** One OSPF neighbor — n9k-ce02 on Ethernet1/2.

```
show nve peers
```

**Expected:** No NVE peers yet (EVPN not provisioned).

```
exit
```

### Step 4: Check the Route Reflector

SSH to xrd01 again:

```bash
ssh clab@<xrd01-ip>
```

```
show bgp vpnv4 unicast summary
```

**Expected:** Two BGP neighbors — 10.0.0.11 (csr-pe01) and 10.0.0.12
(csr-pe02), both in `Established` state.

```
exit
```

### Checkpoint

- [ ] IS-IS adjacencies UP on xrd01 (2 neighbors)
- [ ] IS-IS adjacencies UP on csr-pe01 (2 neighbors)
- [ ] LDP sessions established (csr-pe01 has at least 2 LDP neighbors)
- [ ] BGP VPNv4 sessions Established between PEs and RRs
- [ ] OSPF neighbor UP between n9k-ce01 and n9k-ce02
- [ ] No VRFs provisioned yet on PEs (expected — this comes next)

> **Key insight:** The underlay (IS-IS, LDP, BGP structure) is pre-configured
> via startup configs. In a SaC workflow, the underlay is typically managed
> separately from services. We focus on services from here.

---

## Exercise 2: Provision L3VPN with Ansible

**Time:** 20 minutes
**Goal:** Use Ansible to provision L3VPN services defined in YAML and validate
the result.

### Step 1: Review the service definition

Look at the Customer A L3VPN definition — this is the **source of truth**:

```bash
cat services/l3vpn/vars/customer_a.yml
```

Note the key fields:
- `customer: CustomerA` — human-readable name
- `vrf: CUST_A` — the VRF name on the PE routers
- `rd: "65000:100"` — route distinguisher
- `rt_import / rt_export: "65000:100"` — route targets
- `pe_interfaces` — which PE, which interface, what IP, which CE neighbor

**This YAML file is the entire service definition.** Everything the automation
needs to provision the VPN is here.

### Step 2: Review the template

See how YAML becomes IOS-XE config:

```bash
cat services/l3vpn/templates/csr_pe_l3vpn.j2
```

This Jinja2 template reads the YAML variables and renders them into IOS-XE CLI
commands: VRF definition, interface binding, BGP VRF address-family.

### Step 3: Review the second customer

```bash
cat services/l3vpn/vars/customer_b.yml
```

Notice: same structure, different values. The playbook picks up *all* YAML
files in the `vars/` directory automatically.

### Step 4: Run the L3VPN playbook

```bash
make provision-l3vpn
```

Watch the output. You should see:
- Tasks loading customer YAML files
- Tasks rendering and applying config to csr-pe01 and csr-pe02
- Tasks configuring BGP VPNv4 on xrd01 and xrd02 (RRs)
- All tasks should show `ok` or `changed`; no `failed`

### Step 5: Verify on the PE routers

SSH to csr-pe01:

```bash
ssh admin@<csr-pe01-ip>
```

```
show ip vrf
```

**Expected:** CUST_A and CUST_B VRFs now appear.

```
show ip vrf CUST_A
```

**Expected:** Shows the VRF details including RD, RT, and associated interface.

```
show ip route vrf CUST_A
```

**Expected:** Connected route for 192.168.100.0/24 and possibly BGP routes
from the other PE.

```
show bgp vpnv4 unicast all summary
```

**Expected:** VPNv4 sessions still Established, now with prefixes exchanged.

```
exit
```

### Step 6: Run validation

```bash
make validate
```

The validation playbook checks:
- BGP VPNv4 summary on PEs
- VRF route tables for expected prefixes
- BGP EVPN on CEs (will show nothing yet — that's fine)
- RR BGP summary for PE neighbors
- Ping from linux-client to CUST_A gateway

### Step 7: Test idempotency

Run the playbook again:

```bash
make provision-l3vpn
```

**Expected:** All tasks show `ok` (not `changed`). This is idempotency — the
config is already in the desired state, so nothing changes.

### Checkpoint

- [ ] `make provision-l3vpn` completes without errors
- [ ] CUST_A and CUST_B VRFs visible on csr-pe01
- [ ] VRF routes present for 192.168.100.0/24 and/or 192.168.200.0/24
- [ ] `make validate` passes L3VPN assertions
- [ ] Second run is idempotent (no changes)

> **Key insight:** You didn't type a single CLI command on the routers. The
> service was defined in YAML, rendered by a template, and pushed by Ansible.
> To add a new customer, you add a YAML file — not router CLI.

---

### Stretch Goal: Add Customer C

If you finish early, try adding a new customer:

1. Copy the Customer A definition:
   ```bash
   cp services/l3vpn/vars/customer_a.yml services/l3vpn/vars/customer_c.yml
   ```

2. Edit the new file:
   ```bash
   vi services/l3vpn/vars/customer_c.yml
   ```

   Change:
   - `customer: CustomerC`
   - `vrf: CUST_C`
   - `rd: "65000:300"`
   - `rt_import: "65000:300"`
   - `rt_export: "65000:300"`
   - Update IP addresses to avoid conflicts (e.g., 10.200.1.0/24, 10.200.2.0/24)

3. Re-run the playbook:
   ```bash
   make provision-l3vpn
   ```

4. Verify:
   ```bash
   ssh admin@<csr-pe01-ip>
   show ip vrf
   # You should now see CUST_A, CUST_B, and CUST_C
   ```

---

## Exercise 3: Provision L3VPN with Terraform

**Time:** 15 minutes
**Goal:** See the same L3VPN service provisioned using Terraform — same
outcome, different automation engine.

### Step 1: Understand the difference

| Aspect | Ansible (Exercise 2) | Terraform (this exercise) |
|--------|----------------------|---------------------------|
| Model | Imperative: run tasks in order | Declarative: define desired state |
| Protocol | SSH / CLI | RESTCONF / HTTPS |
| State | Stateless (no tracking) | Stateful (terraform.tfstate) |
| Idempotency | Template comparison | State diff |
| Preview | Dry-run mode | `terraform plan` |

### Step 2: Review the Terraform configuration

```bash
cat terraform/providers.tf
```

Note: Two provider instances per device type, aliased as `pe01`, `pe02`, etc.
The RESTCONF-based providers talk to the devices over HTTPS.

```bash
cat terraform/terraform.tfvars
```

This is the Terraform equivalent of the YAML SoT. Same data — customer names,
VRFs, RD/RT, PE bindings — expressed in HCL format.

```bash
cat terraform/l3vpn.tf
```

The resource definitions: `iosxe_vrf`, `iosxe_bgp_neighbor`,
`iosxe_bgp_address_family_ipv4_vrf`. These map 1:1 to configuration objects
on the device.

### Step 3: Initialize Terraform

```bash
make tf-init
```

This downloads the CiscoDevNet providers. You should see:
"Terraform has been successfully initialized!"

### Step 4: Plan the changes

```bash
make tf-plan
```

Review the plan output. Terraform shows exactly what it will create:
- VRF definitions on pe01 and pe02
- BGP neighbor entries for RR peering
- BGP VRF address families

**Important:** This is a *preview*. Nothing has been applied yet. This is one
of Terraform's key advantages — you see before you commit.

### Step 5: Apply the changes

```bash
make tf-apply
```

Terraform creates the resources via RESTCONF. You should see:
"Apply complete! Resources: X added, 0 changed, 0 destroyed."

### Step 6: Verify

SSH to csr-pe01 and check the same things as Exercise 2:

```bash
ssh admin@<csr-pe01-ip>
show ip vrf
show ip route vrf CUST_A
exit
```

### Step 7: Inspect Terraform state

```bash
cat terraform/terraform.tfstate | python3 -m json.tool | head -60
```

Terraform tracks every resource it created. This is how it knows what to
update or delete on subsequent runs.

### Step 8: Destroy Terraform-managed resources

```bash
make tf-destroy
```

Terraform cleanly removes only what it created, using the state file to know
exactly what to target.

### Checkpoint

- [ ] `make tf-init` succeeds
- [ ] `make tf-plan` shows expected resources
- [ ] `make tf-apply` creates resources without errors
- [ ] VRFs verified on PE routers
- [ ] `make tf-destroy` cleanly removes resources

> **Key insight:** Same service (L3VPN), same YAML-equivalent data, same
> result — but a completely different engine and workflow. The SaC pattern
> is tool-agnostic. Choose Ansible or Terraform based on your team's
> operational model, not dogma.

---

## Exercise 4: EVPN/VXLAN + Full Validation

**Time:** 20 minutes
**Goal:** Deploy a second service type (EVPN/VXLAN) on the N9Kv switches and
run end-to-end validation.

### Step 1: Re-provision L3VPN (if destroyed in Exercise 3)

If you ran `make tf-destroy` in the previous exercise, re-provision L3VPN
using Ansible so that the full stack is in place:

```bash
make provision-l3vpn
```

### Step 2: Review the EVPN service definition

```bash
cat services/evpn/vars/vxlan_tenant.yml
```

Note the structure:
- `tenant: CUST_A_DC` — tenant name
- `vlans` — VLAN ID, name, VNI, SVI addresses per switch
- `vtep_source` — loopback for VXLAN tunnel endpoints
- `evpn_peers` — iBGP EVPN peering between DC switches
- `ospf_area / ospf_process` — underlay configuration

**Same pattern as L3VPN:** a YAML file describes the service; a template
renders it to NX-OS config.

### Step 3: Review the EVPN template

```bash
cat services/evpn/templates/n9k_evpn.j2
```

This template produces NX-OS configuration for:
- VLAN + VNI mapping
- NVE interface (VXLAN VTEP)
- BGP EVPN address family
- SVI interfaces with anycast gateway

### Step 4: Deploy EVPN

```bash
make provision-evpn
```

Watch the output. The playbook:
1. Loads the tenant YAML
2. Renders and applies VXLAN/EVPN config to n9k-ce01 and n9k-ce02
3. Saves the NX-OS running config
4. Checks NVE peer status

### Step 5: Verify on the N9Kv switches

SSH to n9k-ce01:

```bash
ssh admin@<n9k-ce01-ip>
```

```
show vxlan
```

**Expected:** VXLAN VNIs 10100 and 10200 mapped to VLANs 100 and 200.

```
show nve peers
```

**Expected:** NVE peer (n9k-ce02's VTEP IP) in `Up` state.

```
show bgp l2vpn evpn summary
```

**Expected:** BGP L2VPN EVPN neighbor (n9k-ce02 loopback) in `Established` state.

```
exit
```

### Step 6: Run full validation

```bash
make validate
```

This runs all validation checks:
1. **L3VPN on PEs:** BGP VPNv4 summary, VRF routes, prefix assertions
2. **EVPN on CEs:** BGP L2VPN EVPN summary, NVE peers, VXLAN status
3. **Route Reflectors:** PE neighbors established on RRs
4. **End-to-end:** Ping from linux-client to 192.168.100.1 (CUST_A gateway)

All assertions should pass.

### Step 7: Test end-to-end connectivity manually

Access the Linux client container:

```bash
docker exec -it clab-sac-lab-linux-client sh
```

```
ping -c 3 192.168.100.1
```

**Expected:** 3 packets sent, 3 received. This proves connectivity from the
test client through the N9Kv CE switch to the CUST_A VRF gateway on the PE.

```
exit
```

### Checkpoint

- [ ] `make provision-evpn` completes without errors
- [ ] VXLAN VNIs visible on n9k-ce01 (`show vxlan`)
- [ ] NVE peers UP between ce01 and ce02
- [ ] BGP L2VPN EVPN sessions Established
- [ ] `make validate` passes all sections
- [ ] Ping from linux-client to 192.168.100.1 succeeds

> **Key insight:** Two completely different service types (L3VPN and EVPN) —
> same workflow. YAML defines the service, a template renders device config,
> automation pushes it, validation confirms it. This is Service as Code.

---

### Stretch Goal: Add a VLAN to the EVPN Tenant

1. Edit the EVPN tenant definition:
   ```bash
   vi services/evpn/vars/vxlan_tenant.yml
   ```

2. Add a new VLAN under the `vlans` list:
   ```yaml
     - id: 300
       name: CUST_A_APP
       vni: 10300
       svi_addresses:
         n9k-ce01: 192.168.30.1/24
         n9k-ce02: 192.168.30.2/24
   ```

3. Re-run the EVPN playbook:
   ```bash
   make provision-evpn
   ```

4. Verify:
   ```bash
   ssh admin@<n9k-ce01-ip>
   show vxlan
   # VLAN 300 / VNI 10300 should now appear
   ```

---

## Troubleshooting

### SSH connection refused

- **XRd:** Boot time ~2 min. Wait and retry.
- **CSR1000v:** Boot time ~6 min. Wait and retry.
- **N9Kv:** Boot time ~5-8 min (slowest). Wait up to 10 min.
- Check the container is running: `docker ps --filter label=lab=sac-lab`

### Ansible playbook fails with "unreachable"

Your management IPs may differ from the defaults in the inventory.

```bash
# Get actual IPs
make inspect

# Compare with inventory
cat ansible/inventory/hosts.yml

# Update if needed
vi ansible/inventory/hosts.yml
```

### Terraform plan shows errors

- Ensure `make tf-init` completed successfully
- Verify RESTCONF is enabled on CSR (it's in the startup config)
- Check that `terraform/terraform.tfvars` has the correct management IPs

### IS-IS adjacencies not forming

```bash
# Check if startup config was applied
docker exec clab-sac-lab-xrd01 /pkg/bin/xr_cli.sh "show run router isis"
```

If the config is missing, try redeploying:
```bash
make redeploy
# Wait 8-10 minutes for all nodes to boot
```

### "No VRF routes" after provisioning

1. Check that the playbook completed without errors
2. Wait 30-60 seconds for BGP to converge
3. Verify BGP VPNv4 sessions are Established on the RRs
4. Check that the VRF exists: `show ip vrf` on the PE

### Linux client can't ping

1. Verify the IP was assigned: `docker exec clab-sac-lab-linux-client ip addr show eth1`
2. Check the route: `docker exec clab-sac-lab-linux-client ip route`
3. Verify n9k-ce01 has the SVI with 192.168.100.1/24

---

## What You've Accomplished

By completing this lab, you have:

1. **Explored** a multi-vendor SP topology (IOS-XR, IOS-XE, NX-OS) running
   IS-IS, LDP, BGP, OSPF, and VXLAN/EVPN
2. **Provisioned L3VPN** services using Ansible — from YAML definition to
   verified VRF routes
3. **Provisioned L3VPN** using Terraform — same service, different engine,
   same result
4. **Deployed EVPN/VXLAN** on DC switches — extending the SaC pattern to a
   second service type
5. **Validated** end-to-end connectivity and protocol state using automated
   assertions
6. **Experienced the SaC mindset:** define services as data, render with
   templates, push with automation, validate with assertions

The service definitions in `services/` are your source of truth. The
templates, playbooks, and Terraform configs are your rendering engine.
The devices are just targets. **Network configuration is code.**
