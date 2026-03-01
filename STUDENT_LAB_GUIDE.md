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

### GitLab (GitOps Workflow)

Your lab host also runs a local GitLab CE instance for the CI/CD exercises.

| Item | Value |
|------|-------|
| GitLab URL | `http://<your-lab-host-ip>:8080` |
| GitLab username | `student` |
| GitLab password | `CiscoLive2026!` |
| Git clone URL | `http://localhost:8080/student/sac-lab.git` |
| GitLab SSH port | `2222` (not used in this lab — use HTTP) |

> **Note:** Git credentials are pre-configured on your lab host. You can
> `git clone`, `git push`, and `git pull` without entering your password.

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

### GitOps Workflow: Add Customer C via GitLab CI/CD

Instead of running Ansible manually, let's use the production-realistic GitOps
workflow: edit YAML → commit → push → Merge Request → CI pipeline deploys.

#### Step 1: Clone the lab repo from GitLab

```bash
cd ~
git clone http://localhost:8080/student/sac-lab.git sac-lab-gitops
cd sac-lab-gitops
```

#### Step 2: Create a feature branch

```bash
git checkout -b add-customer-c
```

#### Step 3: Create the Customer C service definition

```bash
cp services/l3vpn/vars/customer_a.yml services/l3vpn/vars/customer_c.yml
```

Edit the new file:

```bash
vi services/l3vpn/vars/customer_c.yml
```

Change these values:
- `customer: CustomerC`
- `vrf: CUST_C`
- `rd: "65000:300"`
- `rt_import: "65000:300"`
- `rt_export: "65000:300"`
- Update IP addresses to avoid conflicts (e.g., `10.200.1.0/24`)

#### Step 4: Commit and push

```bash
git add services/l3vpn/vars/customer_c.yml
git commit -m "Add Customer C L3VPN service"
git push -u origin add-customer-c
```

#### Step 5: Create a Merge Request in GitLab

Open your browser to `http://<your-lab-host-ip>:8080` and log in as `student` /
`CiscoLive2026!`.

1. Navigate to the **sac-lab** project
2. You should see a banner: "Create merge request" — click it
3. Title: "Add Customer C L3VPN service"
4. Click **Create merge request**

#### Step 6: Review the pipeline

Before merging, GitLab CI runs a **validation pipeline** on your branch:

1. Click on the pipeline icon in the MR (or go to **CI/CD → Pipelines**)
2. Watch the `validate-l3vpn` job run — it checks your YAML for required fields
3. Wait for it to pass (green checkmark)

#### Step 7: Merge and deploy

1. Back on the MR page, click **Merge**
2. This triggers the **deploy pipeline** on the `main` branch
3. Go to **CI/CD → Pipelines** to watch the deploy job
4. The pipeline runs `ansible-playbook` to push Customer C config to the routers

#### Step 8: Verify

```bash
ssh admin@<csr-pe01-ip>
show ip vrf
# You should now see CUST_A, CUST_B, and CUST_C
exit
```

#### Step 9: Break It — Introduce a deliberate error

Now let's prove the CI/CD pipeline acts as a **guardrail**. You will
intentionally break the Customer C YAML file and watch the pipeline catch it.

```bash
cd ~/sac-lab-gitops
git checkout main && git pull
git checkout -b break-customer-c
```

Edit `customer_c.yml` and **delete the entire `rd:` line**:

```bash
vi services/l3vpn/vars/customer_c.yml
```

Remove this line completely:
```yaml
rd: "65000:300"
```

Save the file, then commit and push:

```bash
git add services/l3vpn/vars/customer_c.yml
git commit -m "Remove rd field (intentional break)"
git push -u origin break-customer-c
```

Create a Merge Request in GitLab:
1. Open `http://<your-lab-host-ip>:8080`
2. Click the "Create merge request" banner
3. Title: "Remove rd field (intentional break)"
4. Click **Create merge request**

#### Step 10: Watch the pipeline FAIL (YANG validation first, then Ansible)

1. Click the pipeline icon in the MR (or go to **CI/CD → Pipelines**)
2. You will see **two** validation stages fail, in order:

**Stage 1: YANG Schema Validation (`validate-yang-l3vpn`)**
- This runs **first** and fails immediately
- Click on the failed job to see the error log
- **Expected error:**
  ```
  ✗ YANG validation failed: services/l3vpn/vars/customer_c.yml
  
  Validation errors:
  
    • Missing required field: 'rd'
  ```
- YANG caught the missing field at the **schema level** — before anything else

**Stage 2: Ansible Validation (`validate-l3vpn-yaml`)**
- This job depends on YANG passing, so it never runs (it's skipped)

**Stage 3: Deploy (`deploy-l3vpn`)**
- Also skipped because validation failed

> **This is defense in depth.** YANG caught a schema error (missing required field) before the Ansible assertions even ran. The pipeline is a safety net: no schema errors pass, no code reaches the routers.

#### Step 11: Fix It — Restore the field and redeploy

Go back to your terminal and restore the `rd:` field:

```bash
vi services/l3vpn/vars/customer_c.yml
```

Add the `rd:` line back:
```yaml
rd: "65000:300"
```

Commit and push the fix:

```bash
git add services/l3vpn/vars/customer_c.yml
git commit -m "Restore rd field (fix intentional break)"
git push
```

Now watch the pipeline in GitLab:
1. Go to **CI/CD → Pipelines** — a new pipeline starts automatically
2. **Stage 1: YANG validation (`validate-yang-l3vpn`)** — passes (green checkmark)
   - YANG now sees the `rd:` field and validates successfully
3. **Stage 2: Ansible validation (`validate-l3vpn-yaml`)** — passes
   - Ansible assertions all pass
4. **Stage 3: Deploy (`deploy-l3vpn`)** — runs and completes successfully
   - Ansible playbook pushes config to routers

Merge the MR, then verify on the router:

```bash
ssh admin@<csr-pe01-ip>
show ip vrf
# CUST_C should still be present and intact
exit
```

#### Break It / Fix It Checkpoint

- [ ] **YANG validation failed** with `Missing required field: 'rd'`
- [ ] **YANG validation is a hard blocker** — Ansible and Deploy jobs were skipped
- [ ] Fix committed and pushed — new pipeline triggered
- [ ] **YANG validation passed** after restoring `rd:`
- [ ] **Ansible validation passed**, then **Deploy ran** automatically
- [ ] CUST_C VRF confirmed on csr-pe01

> **Key insight:** YANG validation happens *first* in the pipeline, catching schema errors before any other validation runs. This demonstrates defense-in-depth: schema validation (YANG) → business logic validation (Ansible) → deployment. The pipeline is a safety net that prevents bad data from reaching your routers.
> file, pushed it through a review process (MR), and automation handled the rest.
> This is how production network changes should work — reviewable, auditable,
> automated.

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

### GitOps Workflow: Add VLAN 300 via GitLab CI/CD

Use the same GitOps workflow to extend the EVPN tenant.

#### Step 1: Create a branch

```bash
cd ~/sac-lab-gitops
git checkout main && git pull
git checkout -b add-evpn-vlan300
```

#### Step 2: Edit the EVPN tenant definition

```bash
vi services/evpn/vars/vxlan_tenant.yml
```

Add a new VLAN under the `vlans` list:

```yaml
  - id: 300
    name: CUST_A_APP
    vni: 10300
    svi_addresses:
      n9k-ce01: 192.168.30.1/24
      n9k-ce02: 192.168.30.2/24
```

#### Step 3: Commit and push

```bash
git add services/evpn/vars/vxlan_tenant.yml
git commit -m "Add VLAN 300 to EVPN tenant"
git push -u origin add-evpn-vlan300
```

#### Step 4: Create and merge via GitLab

1. Open `http://<your-lab-host-ip>:8080`
2. Click the "Create merge request" banner
3. Title: "Add VLAN 300 to EVPN tenant"
4. Wait for the validation pipeline to pass
5. Click **Merge**

#### Step 5: Watch the pipeline deploy

1. Go to **CI/CD → Pipelines**
2. The `deploy-evpn` job runs automatically
3. Wait for it to complete (green checkmark)

#### Step 6: Verify

```bash
ssh admin@<n9k-ce01-ip>
show vxlan
# VLAN 300 / VNI 10300 should now appear
exit
```

> **Key insight:** Same GitOps workflow, different service type. Whether it's
> L3VPN or EVPN, the process is identical: branch → edit YAML → MR → merge →
> automated deploy. The CI/CD pipeline knows which playbook to run based on
> which files changed.

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

### GitLab: Can't log in to web UI

- Verify GitLab is running: `docker ps | grep gitlab-ce`
- Check health: `docker inspect --format='{{.State.Health.Status}}' gitlab-ce`
- If "starting" or "unhealthy", wait 2-3 minutes — GitLab can be slow to boot
- Credentials: `student` / `CiscoLive2026!`

### GitLab: `git push` fails with "Access denied"

```bash
# Re-configure git credentials:
git config --global credential.helper store
echo "http://student:CiscoLive2026!@localhost:8080" > ~/.git-credentials
```

Then retry your push.

### GitLab: Pipeline stuck on "pending"

The GitLab Runner may not be registered. Ask the instructor to run:

```bash
make gitlab-setup
```

### GitLab: Pipeline fails

1. Click on the failed job in GitLab UI to see the error log
2. Common causes:
   - YAML validation error → fix the YAML syntax in your service file
   - Ansible "unreachable" → containerlab topology may need IP update
3. Fix the issue, commit, push again — a new pipeline will run automatically

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
6. **Used a GitOps workflow** to deploy network changes through GitLab — branch,
   edit YAML, Merge Request, CI/CD pipeline, automated deployment
7. **Experienced the SaC mindset:** define services as data, render with
   templates, push with automation, validate with assertions, deliver through
   CI/CD

The service definitions in `services/` are your source of truth. The
templates, playbooks, and Terraform configs are your rendering engine.
GitLab CI/CD is your delivery pipeline. The devices are just targets.
**Network configuration is code.**
