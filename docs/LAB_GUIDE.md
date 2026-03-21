# Cisco Live 2026: Service as Code Lab Guide

## Quick Start: What Should I Do?

### For Instructors
1. **Before the Lab (30 min):** [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - Deploy LTRATO-1001 topology
2. **Hour 1 (Review):** Show students the topology; explain hybrid Ansible+Terraform [HYBRID_APPROACH.md](./HYBRID_APPROACH.md)
3. **Hour 2 (Hands-On):** Run Ansible provisioning; students verify services working
4. **Hour 3 (Interactive):** Run [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md) step-by-step with students
5. **Hour 4 (Validation):** Debrief; answer questions; show optional advanced exercises

### For Students
1. **Hour 1:** Understand what we're building - read [TOPOLOGY_NOTES.md](./TOPOLOGY_NOTES.md) and [HYBRID_APPROACH.md](./HYBRID_APPROACH.md)
2. **Hour 2:** Watch instructors provision via Ansible; SSH to devices and verify configs
3. **Hour 3:** Participate in hands-on [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md) drift detection lab
4. **Hour 4:** Ask questions; explore optional challenges (EVPN, multi-vendor, GitOps)

---

## Lab Overview

### What Is This Lab?

This is an **Infrastructure-as-Code (IaC) training lab** where you'll learn:
- ✅ How to define network services in code (Ansible YAML)
- ✅ How to provision those services automatically (Ansible playbooks)
- ✅ How to manage infrastructure state (Terraform state files)
- ✅ How to detect and fix unauthorized configuration changes (Terraform drift detection)

**Why It Matters:** 80% of network downtime is caused by human errors in manual configuration. IaC eliminates this by making configuration automated, versioned, and auditable—just like application code.

### The Lab Topology: LTRATO-1001

**10 Nodes:**
- **2x XRd P-routers** (10.0.0.x/24 core routing)
- **2x CSR PE routers** (Customer-facing L3VPN/EVPN)
- **2x N9Kv CE switches** (Customer networks)
- **4x Linux clients** (End-user devices generating test traffic)

**Network Services:**
- **L3VPN** (CustomerA, CustomerB) - VRF-based separation
- **EVPN** (optional) - Overlay for CE bridging
- **BGP** backbone with route reflectors

**IPs:** 172.20.20.0/24 management, 10.0.0.0/24 P-core, 192.168.x.x/24 customer

See [TOPOLOGY_NOTES.md](./TOPOLOGY_NOTES.md) for details.

---

## 4-Hour Lab Schedule

| Hour | Learning Objective | Activity | Key Document |
|------|-------------------|----------|---------------|
| **1** | Understand architecture | Review topology; explain IaC | [HYBRID_APPROACH.md](./HYBRID_APPROACH.md) |
| **2** | Provision services automatically | Run Ansible; verify on devices | [deploy_l3vpn.yml](../ansible/playbooks/deploy_l3vpn.yml) |
| **3** | Detect & fix configuration drift | Hands-on drift exercise | [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md) |
| **4** | Validate & debrief | Optional challenges; real-world Q&A | This guide |

### Timing Breakdown

```
Hour 1: Setup & Education (60 min)
  10 min: Welcome, agenda, learning objectives
  20 min: Topology overview (TOPOLOGY_NOTES.md)
  20 min: IaC principles (HYBRID_APPROACH.md)
  10 min: Q&A, break

Hour 2: Ansible Provisioning (60 min)
  5 min:  Review service definitions (services/l3vpn/vars/*.yml)
  10 min: Run Ansible playbook
  30 min: Verify on devices; students SSH and test
  10 min: Troubleshoot issues
  5 min:  Q&A, recap

Hour 3: Terraform Drift Detection (60 min)
  5 min:  Review [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md)
  15 min: Phase 1-2 (show state, authorized change)
  10 min: Phase 3 (introduce drift)
  10 min: Phase 4 (detect drift)
  10 min: Phase 5 (automatic remediation)
  5 min:  Repeat with variant drift (optional)
  5 min:  Debrief

Hour 4: Validation & Advanced Topics (60 min)
  10 min: Undo lab; cleanup and questions
  20 min: Real-world IaC at scale (Netflix, AWS examples)
  15 min: Career & best practices
  10 min: Optional challeng demos
  5 min:  Final Q&A, feedback
```

---

## Key Concepts

### Infrastructure as Code (IaC)

**Definition:** Managing infrastructure (networks, servers, security) through code and automation rather than manual CLI commands.

**Benefits:**
- **Reproducibility:** Same config, every time, on every device
- **Auditability:** Version history shows who changed what, when, why
- **Faster Rollout:** No more CLI one-liners; run scripts, measure results
- **Compliance:** Automated validation ensures standards are met
- **Disaster Recovery:** Rebuild infrastructure from code in minutes

### Service as Code

**Definition:** Network services (L3VPN, MPLS, EVPN) defined in version-controlled files, not CLI manuals.

**Example:**
```yaml
# Before SaC: Operator opens SSH, types 50+ commands, documents in wiki, hopes for best
# After SaC: Code defines service, Ansible runs it, version control audits changes

customer_a:
  vrf_name: CUST_A
  rd: 65000:100
  rt_export: 65000:100
  rt_import: 65000:100
  interfaces:
    pe01: 192.168.100.1/24
    pe02: 192.168.200.1/24
```

### Drift Detection

**Definition:** Identifying deviations between desired (code) and actual (device) configuration.

**Example:**
```
Code Says:           Device Has:          Drift?
─────────────────────────────────────────────────────
rt_export 65000:100  rt_export 65000:100  ✓ OK
rt_import 65000:100  rt_import 65000:100  + 65000:200  ⚠ DRIFT!
```

**Why It Matters:** Someone (intentionally or accidentally) changed the device without updating code. Terraform detects it, alerts team, can auto-fix.

---

## Documentation Structure

### For Lab Execution

| File | Purpose | Audience | Use When |
|------|---------|----------|----------|
| **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** | How to deploy topology | Instructors | Day-of setup |
| **[TOPOLOGY_NOTES.md](./TOPOLOGY_NOTES.md)** | Node details, IP layout, links | Both | Understanding architecture |
| **[HYBRID_APPROACH.md](./HYBRID_APPROACH.md)** | Why Ansible + Terraform? | Both | Hour 1 education |
| **[DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md)** | 6-phase hands-on lab | Students | Hour 3 activity |

### For Code Exploration

| Location | What It Is | Used By |
|----------|-----------|---------|
| [services/l3vpn/](../services/l3vpn) | Service definitions (YAML) | Ansible |
| [ansible/playbooks/](../ansible/playbooks) | Deployment orchestration | Instructors |
| [terraform/terraform.tfstate](../terraform/terraform.tfstate) | IaC state file (source of truth) | Terraform, drift exercise |

### Project Root

| File | Purpose |
|------|---------|
| [README.md](../README.md) | Project overview |
| [CHANGELOG.md](../CHANGELOG.md) | Version history |
| [topology/sac-lab.yml](../topology/sac-lab.yml) | Containerlab topology definition |

---

## How to Run the Lab

### Pre-Lab (Instructor, 30 minutes before class)

```bash
# Clone repo (or update if already cloned)
git clone https://github.com/your-github/Cisco-Live-2026-Service-as-Code.git
cd Cisco-Live-2026-Service-as-Code

# Deploy topology (uses containerlab, docker)
cd topology
sudo containerlab deploy --topo sac-lab.yml

# Verify all nodes are running
sudo containerlab inspect --all
# Should show: 10 nodes, all running, all IPs in 172.20.20.x/24

# Copy Ansible files to accessible location
cd ../ansible
cp -r . ~/ansible-workspace/  # Or wherever students can access

# Review Terraform state file
cd ../terraform
cat terraform.tfstate  # Should be valid JSON
```

### Hour 1: Topology & IaC Orientation

```bash
# Show students the running topology
sudo containerlab inspect --all

# SSH to a device to show it's real
ssh admin@172.20.20.20
csr-pe01# show version
csr-pe01# show running-config | include vrf  # Should be empty (no L3VPN yet)
csr-pe01# exit
```

**Discussion Points:**
- "These are real network OS images, not simulators"
- "Each node is Docker container running actual IOS-XE/XR/NX-OS"
- "We'll provision L3VPN services via Ansible (Hour 2), then show drift detection via Terraform (Hour 3)"

### Hour 2: Ansible Provisioning

```bash
# Navigate to ansible directory
cd ansible

# Show students the service definition they'll provision
cat playbooks/deploy_l3vpn.yml
cat vars/customer_a.yml
cat vars/customer_b.yml

# Run the provisioning playbook
ansible-playbook playbooks/deploy_l3vpn.yml -i inventory/ltrato-1001.ini --verbose

# Verify on devices - show students it actually worked
ssh admin@172.20.20.20
csr-pe01# show vrf
csr-pe01# show ip bgp vpnv4 all neighbors | include "Neighbor"
csr-pe01# show ip bgp vpnv4 all summary
exit

# Let students SSH and explore
# "Pick a device, SSH to it, show me a config we just deployed"
```

### Hour 3: Terraform Drift Exercise

Follow step-by-step instructions in [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md):

```bash
# Quick preview for instructors:
cd terraform

# Look at state file (JSON representing desired config)
cat terraform.tfstate | jq '.resources[0]'  # Shows first VRF config

# During exercise:
# 1. Student goes to Phase 3, SSH and makes unauthorized change
# 2. Run: terraform plan   # Shows diff
# 3. Run: terraform apply  # Reverts device to state
```

### Hour 4: Debrief & Extensions

```bash
# Cleanup (optional - can leave running for next cohort)
cd topology
sudo containerlab destroy --topo sac-lab.yml

# Or keep running and answer advanced questions:
# "How would this scale to 100 services?"
# "What about multi-vendor networks?"
# "How do you version infrastructure?"
```

---

## Troubleshooting Quick Ref

### "I can't SSH to a device"
```bash
# Check if it's running
sudo containerlab inspect --all | grep csr

# Check IP
docker inspect <container-name> | grep -i ipaddr

# Connect directly to container
docker exec -it csr-pe01 bash
```

### "Ansible playbook is failing"
```bash
# Check inventory is correct
cat inventory/ltrato-1001.ini

# Test connectivity to one device
ansible csr-pe01 -i inventory/ltrato-1001.ini -m ios_command -a 'commands="show version"'

# Run with debug output
ansible-playbook playbooks/deploy_l3vpn.yml -i inventory/ltrato-1001.ini -vvv
```

### "Terraform state file looks wrong"
```bash
# Validate JSON
jq empty terraform/terraform.tfstate  # Silent = valid; error = invalid

# View specific resource
jq '.resources[] | select(.type=="iosxe_vrf")' terraform/terraform.tfstate

# Restore from git if corrupted
git checkout terraform/terraform.tfstate
```

### "Students can't see L3VPN configs after Ansible"
```bash
# Check if playbook actually ran successfully
# (Rerun with -vvv flag to see warnings)

# Manually check a config on device
ssh admin@172.20.20.20
csr-pe01# show run | include vrf
# If empty, Ansible provisioning didn't complete

# Try again from scratch
cd ansible
ansible-playbook playbooks/deploy_l3vpn.yml -i inventory/ltrato-1001.ini --check  # Dry run
# Then remove --check to actually apply
```

---

## Learning Resources

### IaC Concepts
- **Red Hat Ansible Best Practices:** https://docs.ansible.com/ansible/latest/user_guide/
- **Terraform Documentation:** https://www.terraform.io/docs/
- **NetDevOps at Scale:** https://learnetwork.cisco.com/ (Cisco DevNet)

### Network Service Details
- **BGP/MPLS L3VPN:** RFC 4364, Cisco IOS-XR docs
- **EVPN:** IETF drafts, vendor documentation
- **Route Targets:** RFC 4360

### Career Development
- **CiscoDevNet Certifications:** Associate DevNet, Professional DevNet
- **HashiCorp Terraform Associate:** Certifies IaC expertise
- **Network Automation Engineer:** Job title, $150K+ salary range

---

## Next Steps After the Lab

### For Students
1. **Clone the repo** to your local machine
2. **Review DRIFT_EXERCISE.md** at home; try repeating it
3. **Extend the lab:**
   - Add CustomerC L3VPN (create YAML, run Ansible, test Terraform drift)
   - Implement EVPN/VXLAN (build on existing N9K configs)
   - Write drift for different service types (OSPF, static routing)
4. **Learn Git workflows** (branching, PRs, code review)
5. **Study Terraform modules** to scale this pattern

### For Instructors
1. **Customize for your organization:**
   - Replace topology with your actual network architecture
   - Add company-specific services (traffic policies, security, monitoring)
   - Integrate with your current tooling (Netbox, ServiceNow, Slack)
2. **Extend duration:** Add 2 more hours for EVPN, multi-vendor, GitOps
3. **Make it production-relevant:** Use your actual customer service definitions

---

## Lab Support

### Questions During the Lab?
Raise your hand; instructors will help. This is a hands-on learning exercise—everyone will hit issues, that's when learning happens.

### After the Lab?
- **GitHub Issues:** File questions/issues on the repo
- **Cisco DevNet:** Post to community forums
- **Your Instructors:** Email us after the event

---

## Summary

**In 4 hours, you'll learn what takes weeks in production environments.**

You'll understand why infrastructure engineers care about source-of-truth, drift detection, and automation. You'll see that IaC isn't just about speed—it's about reliability, compliance, and sanity.

**Let's build something!**

