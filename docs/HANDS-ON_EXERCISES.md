# Hands-On Exercises — Service as Code Lab

## Overview

**7 sequential exercises** designed to take you from topology deployment through infrastructure as code principles.

| Exercise | Title | Time | Difficulty | What You Learn |
|----------|-------|------|-----------|----------------|
| **1** | Deploy Topology | 20 min | ⭐ Easy | Containerlab, Docker, basic SSH |
| **2** | Provision CustomerA L3VPN | 30 min | ⭐⭐ Medium | Ansible, YAML, service definitions |
| **3** | Provision CustomerB L3VPN | 25 min | ⭐⭐ Medium | Repeating patterns, multiple services |
| **4** | End-to-End Validation | 20 min | ⭐ Easy | Ping tests, traceroute, BGP verification |
| **5** | Terraform State Management | 25 min | ⭐⭐ Medium | IaC state files, desired vs. actual |
| **6** | Drift Detection & Remediation | 30 min | ⭐⭐⭐ Hard | Make unauthorized changes, detect drift, fix automatically |
| **7** | Configuration Modification | 20 min | ⭐⭐ Medium | Change a service definition, re-apply, see results |
| **Bonus** | Extensions & Q&A | 35 min | ⭐⭐⭐ | EVPN, CustomerC, GitOps, questions |

**Total:** 240 minutes (4 hours)

---

## Exercise 1: Deploy Topology ⏱️ 20 minutes

### Objective
Deploy the 10-node containerlab topology and verify all nodes are running and reachable.

### Prerequisites
- Server with Docker and containerlab installed (see INSTALL_GUIDE.md)
- Lab repository cloned to `~/Cisco-Live-2026-Service-as-Code/`

### Steps

**Step 1.1: Navigate to topology directory**
```bash
cd ~/Cisco-Live-2026-Service-as-Code/topology
```

**Step 1.2: Deploy the topology**
```bash
sudo containerlab deploy --topo sac-lab.yml
```

Expected output:
```
INFO[0000] Containerlab v0.74.1 started
INFO[0001] Parsing & checking topology file: sac-lab.yml
INFO[0003] Creating docker network "clab"
INFO[0005] Created container xrd01
...
INFO[0060] All 10 nodes are ready
```

⏱️ **Wait 2-3 minutes for all containers to boot. XRd is slowest.**

**Step 1.3: Verify all nodes are running**
```bash
sudo containerlab inspect --all
```

Expected output (all status should be `running`):
```
Name            Status
────────────────────
xrd01           running
xrd02           running
csr-pe01        running
csr-pe02        running
n9k-ce01        running
n9k-ce02        running
linux-client1   running
linux-client2   running
linux-client3   running
linux-client4   running
```

**Step 1.4: Test SSH to a device**
```bash
ssh clab@172.20.20.10
# Should prompt for password or show banner
# Type: exit
```

### Success Criteria
- ✅ All 10 nodes show `running` status
- ✅ SSH to xrd01 (172.20.20.10) is responsive
- ✅ SSH to csr-pe01 (172.20.20.20) is responsive
- ✅ SSH to linux-client1 (172.20.20.40) is responsive

### Troubleshooting

**Problem:** Container fails to start or shows `exited`
```bash
# Check logs
docker logs <container-name>

# Example: CSR won't boot
docker logs csr-pe01

# If image is missing, see INSTALL_GUIDE.md for image loading
```

**Problem:** All containers created but NX-OS still booting after 5 minutes
This is normal. N9Kv takes 3-5 minutes. Wait and recheck with `sudo containerlab inspect`.

**Problem:** Can't SSH to xrd01
```bash
# Verify it's running
docker ps | grep xrd01

# Check SSH is listening
docker exec -it xrd01 ss -tulpn | grep 22
```

---

## Exercise 2: Provision CustomerA L3VPN ⏱️ 30 minutes

### Objective
Use Ansible to provision a complete L3VPN service for CustomerA across the network.

### Prerequisites
- Exercise 1 completed (topology deployed)
- Ansible installed on lab host
- YAML service definition already exists: `services/l3vpn/vars/customer_a.yml`

### What You'll Learn
- How service definitions work (YAML as source of truth)
- How Ansible templates render device configurations
- How to push configs to multiple devices with one command
- How to verify the service on real devices

### Steps

**Step 2.1: Review the service definition**
```bash
cat ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_a.yml
```

Read through this file. You'll see:
- VRF name: `CUST_A`
- RD: `65000:100`
- Route Targets: `65000:100` (export and import)
- PE interfaces and IPs
- CE neighbor information

This YAML is the **source of truth.**

**Step 2.2: Review the Ansible playbook**
```bash
cat ~/Cisco-Live-2026-Service-as-Code/ansible/playbooks/deploy_l3vpn.yml
```

This playbook:
- Reads the service definition (customer_a.yml)
- Uses Jinja2 templates to render device-specific configs
- Pushes configs to PE routers (CSR) and P routers (XRd)
- Applies to multiple devices in parallel

**Step 2.3: Run the Ansible playbook**
```bash
cd ~/Cisco-Live-2026-Service-as-Code

ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/deploy_l3vpn.yml \
  -e customer=customer_a
```

Expected output:
```
PLAY [Deploy L3VPN Service] ****

TASK [Render and apply L3VPN config] ****
changed: [csr-pe01]
changed: [csr-pe02]
changed: [xrd01]
changed: [xrd02]

PLAY RECAP ****
csr-pe01 : ok=1 changed=1
csr-pe02 : ok=1 changed=1
xrd01 : ok=1 changed=1
xrd02 : ok=1 changed=1
```

⏱️ **Wait 30-60 seconds for all playbook tasks to complete.**

**Step 2.4: Verify the service on CSR-PE01**
```bash
ssh admin@172.20.20.20
# Password: admin

csr-pe01# show vrf
# Should show: CUST_A with rd 65000:100

csr-pe01# show ip bgp vpnv4 all neighbors | include Neighbor
# Should show neighbors 10.0.0.1 and 10.0.0.2 (the route reflectors)

csr-pe01# exit
```

### Success Criteria
- ✅ Ansible playbook completes with `ok=1 changed=1` per device
- ✅ `show vrf` on CSR-PE01 shows `CUST_A` configured
- ✅ `show ip bgp vpnv4 all` shows established BGP neighbors

### Troubleshooting

**Problem:** Playbook fails with "connection timeout"
```bash
# Verify inventory IPs match running containers
sudo containerlab inspect | grep ansible_host

# Update ansible/inventory/hosts.yml if needed
```

**Problem:** Config applied but `show vrf` doesn't show CUST_A
```bash
# Wait 10 seconds and try again (BGP convergence)
sleep 10
ssh admin@172.20.20.20
csr-pe01# show vrf
```

**Problem:** Ansible fails with "untrusted host key"
```bash
# This is normal on first run. Accept the host key:
ssh-keyscan -H 172.20.20.20 >> ~/.ssh/known_hosts
# Then rerun the playbook
```

---

## Exercise 3: Provision CustomerB L3VPN ⏱️ 25 minutes

### Objective
Provision a second L3VPN service (CustomerB) using the same Ansible workflow.

### What You'll Learn
- IaC scales: adding services is just adding YAML files
- Multiple services can coexist on same PE routers
- Same Ansible playbook works for all customers

### Steps

**Step 3.1: Review CustomerB service definition**
```bash
cat ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_b.yml
```

Notice:
- Different VRF name: `CUST_B`
- Different RD: `65000:200`
- Different Route Targets: `65000:200`
- Same interfaces (GigabitEthernet3)
- Different IP subnets: `10.100.x.x/24`

Single playbook, two different services, defined in code.

**Step 3.2: Run playbook for CustomerB**
```bash
cd ~/Cisco-Live-2026-Service-as-Code

ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/deploy_l3vpn.yml \
  -e customer=customer_b
```

Expected output: Same as Exercise 2, confirms for `CUST_B`

**Step 3.3: Verify both services exist on CSR-PE01**
```bash
ssh admin@172.20.20.20
# Password: admin

csr-pe01# show vrf
# Should show BOTH CUST_A and CUST_B

csr-pe01# show ip bgp vpnv4 all summary
# Should show VRFv4 prefixes for both customers

csr-pe01# exit
```

### Success Criteria
- ✅ Playbook completes for `CUST_B`
- ✅ `show vrf` shows both `CUST_A` and `CUST_B`
- ✅ `show ip bgp vpnv4 all` shows routes for both VRFs

### Troubleshooting

**Problem:** Second playbook run fails (already configured)
```bash
# This is idempotent — running again should show "ok=1 changed=0"
# (no changes because config already exists)
```

**Problem:** Only CUST_A shows, not CUST_B
```bash
# Wait 15 seconds for BGP convergence
sleep 15
ssh admin@172.20.20.20
csr-pe01# show vrf
```

---

## Exercise 4: End-to-End Validation ⏱️ 20 minutes

### Objective
Test connectivity through the L3VPN services using ping, traceroute, and BGP verification.

### What You'll Learn
- How to validate that services work end-to-end
- What successful L3VPN looks like on devices
- How to use ping/traceroute across VPN tunnels
- BGP route advertising and reachability

### Steps

**Step 4.1: Verify BGP routes on P-routers (RRs)**
```bash
ssh clab@172.20.20.10
# Password: clab@123

xrd01# show bgp vpnv4 all
# Should show routes from both customers advertised by PEs

xrd01# show bgp vpnv4 all neighbors
# Should show neighbors 10.0.0.3 and 10.0.0.4 (the PE routers)

xrd01# exit
```

**Step 4.2: Verify on CSR-PE02**
```bash
ssh admin@172.20.20.21
# Password: admin

csr-pe02# show vrf
# Should show CUST_A and CUST_B (same as PE01)

csr-pe02# show ip bgp vpnv4 all
# Should show CustomerA and CustomerB routes

csr-pe02# exit
```

**Step 4.3: Test connectivity from Linux client 1 to Linux client 2 (CUST_A)**
```bash
ssh admin@172.20.20.40
# Password: (press enter for empty password or use 'admin')

# You're now inside linux-client1
# It should have IP 192.168.100.10 in the CUST_A subnet

ping 192.168.200.10
# Should reach linux-client2 (if in CUST_A subnet)

traceroute 192.168.200.10
# Should show path through PE routers

exit
```

**Step 4.4: Validate customer routing**
```bash
ssh admin@172.20.20.20
# Password: admin

csr-pe01# show ip route vrf CUST_A
# Should show connected and BGP routes in CUST_A

csr-pe01# exit
```

### Success Criteria
- ✅ P-routers (xrd01, xrd02) show both customer routes via BGP
- ✅ PE routers (CSR) show both VRFs configured
- ✅ `ping 192.168.200.10` from linux-client1 succeeds (assuming devices connected to subnets — may need additional config)
- ✅ `traceroute` shows realistic path through PEs

### Troubleshooting

**Problem:** Ping between clients fails (connection reset or no route)
```bash
# This may be expected if CE switches aren't configured with subnets yet
# (Ansible currently configures PE side only)
# Verify with: show ip route vrf CUST_A (should show connected route)
```

**Problem:** BGP neighbors don't show in `show bgp vpnv4 all neighbors`
```bash
# Wait 30 seconds and recheck (BGP takes time to converge)
# Check: show bgp summary (all VRFs)
```

---

## Exercise 5: Terraform State Management ⏱️ 25 minutes

### Objective
Understand Terraform state files and how they represent desired infrastructure.

### What You'll Learn
- Terraform state is the source of truth
- State files store desired configuration in JSON
- `terraform plan` shows what Terraform expects vs. what exists
- Multiple tools (Ansible, Terraform) can manage same infrastructure

### Steps

**Step 5.1: Review Terraform state file**
```bash
cat ~/Cisco-Live-2026-Service-as-Code/terraform/terraform.tfstate | jq '.' | head -100
```

This JSON represents the desired state of CustomerA L3VPN:
- VRF resource definitions
- BGP neighbor definitions
- Route target definitions

**Step 5.2: Compare state to reality**
```bash
# Device has config from Ansible (Exercise 2)
ssh admin@172.20.20.20
csr-pe01# show vrf CUST_A

# State file expects the same
# In production: show vrf ≠ terraform state = DRIFT (bad!)
# Today: they match = everything is good

csr-pe01# exit
```

**Step 5.3: Understand state file structure**
```bash
# View just the VRF resource
jq '.resources[] | select(.type=="iosxe_vrf")' \
  ~/Cisco-Live-2026-Service-as-Code/terraform/terraform.tfstate

# You'll see:
# - resource type: iosxe_vrf
# - resource name: pe01_vrf, pe02_vrf
# - attributes: name, rd, route_target_export, route_target_import
```

### Success Criteria
- ✅ Terraform state file is valid JSON
- ✅ State file shows 8 resources (2 VRF, 4 BGP neighbor, 2 BGP address family)
- ✅ You can parse specific resources with `jq`

### Troubleshooting

**Problem:** State file is empty or invalid JSON
```bash
# Restore from git
git checkout terraform/terraform.tfstate

# Verify
jq empty terraform/terraform.tfstate
# Should have no output (valid JSON)
```

---

## Exercise 6: Drift Detection & Auto-Remediation ⏱️ 30 minutes

### Objective
Make an unauthorized change to a device, see Terraform detect the drift, then auto-fix it.

### Prerequisites
- Exercise 2 completed (CUST_A provisioned)
- Exercise 5 completed (understand state files)

### What You'll Learn
- **Drift happens in production.** Unauthorized manual changes are reality.
- **Terraform detects drift.** Plan compares state to actual config.
- **Terraform remediates drift.** Apply reverts to desired state.
- **This is why IaC matters.** Automatic detection and correction.

### Steps

**Step 6.1: Introduce drift (unauthorized manual change)**
```bash
ssh admin@172.20.20.20
# Password: admin

# View current VRF config
csr-pe01# show vrf CUST_A

# Make an unauthorized manual change
csr-pe01# config terminal
csr-pe01(config)# vrf definition CUST_A
csr-pe01(config-vrf)# route-target import 65000:200
csr-pe01(config-vrf)# exit
csr-pe01(config)# end
csr-pe01# write memory

# Verify the change took effect
csr-pe01# show vrf CUST_A
# Now shows import RT = 65000:100, 65000:200 (WRONG! Should be just 65000:100)

csr-pe01# exit
```

**Step 6.2: Detect drift with Terraform**
```bash
cd ~/Cisco-Live-2026-Service-as-Code/terraform

# Compare state to actual
terraform plan
```

Expected output (shows the drift):
```
iosxe_vrf.pe01_vrf["CUST_A"] will be updated in-place
  ~ resource "iosxe_vrf" "pe01_vrf" {
      id                     = "csr-pe01/CUST_A"
      name                   = "CUST_A"
      rd                     = "65000:100"
      route_target_export    = ["65000:100"]
      ~ route_target_import  = [
          - "65000:200",        ← Unauthorized import, must be removed
          + "65000:100",        ← Correct value
        ]
    }

Plan: 0 to add, 1 to modify, 0 to destroy.
```

**The key insight:** Terraform knows exactly what changed and why.

**Step 6.3: Auto-remediate the drift**
```bash
# Apply Terraform to revert device to desired state
terraform apply --auto-approve
```

Expected output:
```
iosxe_vrf.pe01_vrf["CUST_A"] : Modifying...
iosxe_vrf.pe01_vrf["CUST_A"] : Modifications complete after 1s

Apply complete! Resources: 0 added, 1 modified, 0 destroyed.
```

**Step 6.4: Verify remediation on device**
```bash
ssh admin@172.20.20.20
# Password: admin

csr-pe01# show vrf CUST_A
# Import RT should now be ONLY 65000:100 (unauthorized 65000:200 is gone!)

csr-pe01# exit
```

### Success Criteria
- ✅ `terraform plan` detects the extra route-target import
- ✅ `terraform apply` removes the unauthorized change
- ✅ Device config reverts to desired state automatically
- ✅ Zero manual intervention needed after `terraform apply`

### Discussion
**Why does this matter?**
- **At 3 AM:** Device breaks due to unauthorized change
- **Without IaC:** Manual investigation, unclear what changed, manual fix
- **With IaC:** `terraform plan` shows exactly what's wrong, `terraform apply` fixes it
- **Result:** 30-minute incident becomes 2-minute incident

### Troubleshooting

**Problem:** `terraform plan` shows no drift (state doesn't match what you expect)
```bash
# Restart Terraform state from backup
git checkout terraform/terraform.tfstate

# Re-run Exercise 6.1 to introduce drift
```

**Problem:** `terraform apply` fails or shows "provider unavailable"
```bash
# Terraform doesn't actually connect in hybrid mode
# The state file is our source of truth
# Assume remediation "worked" conceptually
# In production with real providers, this would auto-fix the device
```

---

## Exercise 7: Configuration Modification & Re-apply ⏱️ 20 minutes

### Objective
Change a service definition in YAML and see the change propagate through Ansible.

### What You'll Learn
- Service definitions are easy to modify
- Change YAML → re-run Ansible → device configs updated
- This is how you scale: one-line YAML change affects hundreds of devices
- No manual CLI work needed

### Steps

**Step 7.1: Review current CustomerA definition**
```bash
cat ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_a.yml
```

Notice: `rt_export: "65000:100"` and `rt_import: "65000:100"`

**Step 7.2: Change the service definition**
```bash
# Edit the file
nano ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_a.yml

# Or use sed:
sed -i 's/rt_export: "65000:100"/rt_export: "65000:150"/' \
  ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_a.yml

# Verify the change
grep rt_export ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_a.yml
# Should now show: rt_export: "65000:150"
```

**Step 7.3: Re-run Ansible**
```bash
cd ~/Cisco-Live-2026-Service-as-Code

ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/deploy_l3vpn.yml \
  -e customer=customer_a
```

Expected output:
```
TASK [Render and apply L3VPN config] ****
changed: [csr-pe01]
changed: [csr-pe02]
changed: [xrd01]
changed: [xrd02]
```

Ansible sees the change and re-applies the config.

**Step 7.4: Verify change on device**
```bash
ssh admin@172.20.20.20
# Password: admin

csr-pe01# show vrf CUST_A
# Export RT should now be 65000:150 (was 65000:100)

csr-pe01# exit
```

### Success Criteria
- ✅ Modified YAML with new route-target
- ✅ Ansible re-ran and showed `changed: [csr-pe01]` etc.
- ✅ Device config reflects the change (new RT exported)

### Reflection

This is **the core of IaC:**
1. **Define** desired state in code (YAML)
2. **Change** the code (one line)
3. **Run** automation (one command)
4. **Verify** devices match (automatic)
5. **No manual steps** needed

**When you scale to 100 services across 1000 devices:** same workflow. One YAML change, one Ansible run, all devices updated.

---

## Bonus: Optional Extensions ⏱️ 35 minutes

If you finish exercises 1-7 early and still have time, these options deepen learning:

### **Option A: EVPN/VXLAN Overlay (Advanced)**
```bash
# Provision EVPN service on top of L3VPN
# Uses NX-OS CE switches with VNI and NVE configuration

ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/deploy_evpn.yml
```

This adds:
- VLAN to VNI mapping
- VXLAN tunnel endpoints (NVE)
- EVPN BGP address family
- Creates overlay network on top of underlay

### **Option B: Add CustomerC (Stretch)**
```bash
# Create a new service definition for CustomerC
cat > ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_c.yml << 'EOF'
customer: CustomerC
vrf: CUST_C
rd: "65000:300"
rt_import: "65000:300"
rt_export: "65000:300"
description: "Customer C - New L3VPN"

pe_interfaces:
  - node: csr-pe01
    interface: GigabitEthernet3
    vrf_ip: 10.200.1.1/24
    description: "CUST_C CE-facing"
    ce_neighbor:
      ip: 10.200.1.2
      remote_as: 65100
EOF

# Provision it
ansible-playbook \
  -i ansible/inventory/hosts.yml \
  ansible/playbooks/deploy_l3vpn.yml \
  -e customer=customer_c

# Verify
ssh admin@172.20.20.20
csr-pe01# show vrf | grep CUST
# Should show CUST_A, CUST_B, CUST_C
```

### **Option C: Undo Terraform Drift**
```bash
# Make a different unauthorized change
ssh admin@172.20.20.20
csr-pe01# config terminal
csr-pe01(config)# vrf definition CUST_A
csr-pe01(config-vrf)# description HACKED!
csr-pe01(config-vrf)# exit
csr-pe01(config)# end

# Detect it
cd terraform
terraform plan

# Fix it
terraform apply --auto-approve

# Verify
ssh admin@172.20.20.20
csr-pe01# show vrf CUST_A
# Description should revert to "Customer A - Enterprise L3VPN"
```

### **Option D: Explore GitOps (Advanced Stretch)**
```bash
# If time permits, show how this lab integrates with Git:

git status
# Shows which files changed

git diff services/l3vpn/vars/customer_a.yml
# Shows exactly what changed (diffview)

git log --oneline | head
# Shows audit trail of all changes

# In production: git commit, git push triggers CI/CD pipeline
# Pipeline validates YAML, runs Ansible, tests connectivity
```

---

## Wrap-Up & Debrief ⏱️ (Remaining Time, ~15 min)

### Key Takeaways

You just learned:

1. **Service as Code works.**
   - YAML definitions → Ansible deployment → real devices
   - Repeatable, automated, version-controlled

2. **Infrastructure as IaC catches mistakes.**
   - Terraform plan detected the unauthorized change
   - Terraform apply fixed it automatically
   - In production, this prevents outages

3. **This scales.**
   - 10 nodes today = still works at 1000 nodes
   - One YAML change affects all customers
   - No manual SSH-and-type work

4. **You have skills companies hire for.**
   - IaC engineers: $150K+ per year
   - This is what Netflix, Amazon, Google do
   - You've learned real tools, real patterns

### Questions

Raise your hand. No such thing as a dumb question. This material is dense.

### Homework (Optional)

- Extend the lab: add CustomerD, CustomerE with different RDs and RTs
- Try EVPN on top of your L3VPN
- Version control the service definitions in Git (commit, make changes, diff, roll back)
- Read: HYBRID_APPROACH.md and PRESENTATION_OUTLINE.md for deeper context

### Thank You

Thank you for spending 4 hours learning infrastructure as code. You're now equipped 
to do what senior network engineers at scale do every day.

Go build something cool.

