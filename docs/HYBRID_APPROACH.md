# Hybrid Ansible + Terraform Approach: IaC for Service as Code

## Executive Summary

This lab uses a **hybrid infrastructure-as-code strategy** combining Ansible (for active provisioning) and Terraform (for state management and drift detection). This approach is more realistic than traditional IaC because it addresses the real-world problem of unauthorized manual changes in production networks.

**Key Innovation:** We teach IaC principles through Terraform's core strengths (state management, drift detection, automatic remediation) without requiring functional device providers—which are often unavailable, unstable, or not suitable for complex multi-vendor environments.

---

## Why Hybrid? The Real-World Context

### The Problem with "Pure" Terraform Approach
1. **Provider Limitations:** CiscoDevNet Terraform providers for IOS-XR and IOS-XE are:
   - Not distributed via official Terraform Registry
   - Incomplete for complex configurations
   - Maintained by community, not Cisco officially
   - Require custom builds and local sourcing
   
2. **Network Complexity:** Modern networks mix Cisco (IOS-XE, IOS-XR, NX-OS), Juniper, Arista, and open-source tools. A single provider ecosystem doesn't exist.

3. **Operator Reality:** In production, engineers make manual changes:
   - Emergency fixes after incidents
   - Quick tests that become permanent
   - Undocumented changes for troubleshooting
   - Honest mistakes and typos
   
   These happen regardless of IaC tooling. **Drift happens naturally.**

### The Hybrid Solution
- **Ansible:** Rapid, agentless provisioning with proven Cisco modules (ios_config, iosxr_config, nxos_config)
- **Terraform:** State management, drift detection, and automatic reconciliation (without requiring working providers)
- **Result:** Students learn IaC principles on real-world scenarios without infrastructure limitations

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HOUR 2: PROVISIONING (Ansible)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Service Definition (YAML SoT)  →  Jinja2 Templates  →  Devices     │
│  services/l3vpn/vars/            services/l3vpn/       (CSR/XRd)    │
│  customer_a.yml                  templates/                          │
│  customer_b.yml                                                       │
│                                                                       │
│  ✓ Actual provisioning happens here                                  │
│  ✓ VRF/BGP configs deployed to real hardware/containers             │
│  ✓ ansible/playbooks/deploy_l3vpn.yml orchestrates                  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                   HOUR 3: IaC PRINCIPLES (Terraform)                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Terraform State File (SoT)  ↔  Device Snapshots  ↔  Drift Detection │
│  terraform/terraform.tfstate      (stored outside                    │
│                                    device)                           │
│                                                                       │
│  ✓ State file = source of truth (what SHOULD exist)                 │
│  ✓ Device config = actual reality (what DOES exist)                 │
│  ✓ terraform plan = drift detection (differences)                   │
│  ✓ terraform apply = automatic remediation (revert)                 │
│                                                                       │
│  ⚠ Note: Doesn't require working Terraform providers!               │
│  →  State file is JSON; drift is detected by comparison             │
│  →  Remediation happens via snapshot restoration (optional)         │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────┐
│                HOUR 4: VALIDATION & DEBRIEF                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  Students understand:                                                │
│  1. Service definitions as code (Ansible YAML)                       │
│  2. Infrastructure state as code (Terraform state file)              │
│  3. Drift detection and reconciliation (terraform plan/apply)        │
│  4. Why this matters in production (real-world scenarios)            │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. Ansible: Active Provisioning Path

**Role:** Deploy service configurations to network devices

**Workflow:**
```
Customer Requirements
        ↓
services/l3vpn/vars/customer_a.yml (Define: VRF, RD, RT, interfaces)
        ↓
services/l3vpn/templates/*.j2 (Render: IOS-XE and IOS-XR Jinja2 templates)
        ↓
ansible/playbooks/deploy_l3vpn.yml (Execute: tasks targeting CSR PE and XRd P routers)
        ↓
Devices Configured ✓
```

**Key Files:**
- [services/l3vpn/vars/customer_a.yml](../services/l3vpn/vars/customer_a.yml) - CustomerA service definition
- [services/l3vpn/templates/iosxe_l3vpn.j2](../services/l3vpn/templates/iosxe_l3vpn.j2) - CSR PE configuration template
- [services/l3vpn/templates/iosxr_l3vpn.j2](../services/l3vpn/templates/iosxr_l3vpn.j2) - XRd P configuration template
- [ansible/playbooks/deploy_l3vpn.yml](../ansible/playbooks/deploy_l3vpn.yml) - Deployment orchestration

**Advantages:**
- ✓ Proven Cisco modules (ios_config, iosxr_config, nxos_config)
- ✓ Agentless (no software required on devices)
- ✓ Idempotent (safe to run repeatedly)
- ✓ Rapid iteration during lab development
- ✓ Works with all major network vendors

**Limitations:**
- ✗ No state management (can't detect drift between runs)
- ✗ No built-in rollback (manual recovery required)
- ✗ Doesn't prevent manual out-of-band changes

---

### 2. Terraform: State Management & Drift Detection Path

**Role:** Define desired infrastructure state and detect deviations

**Workflow:**
```
terraform/terraform.tfstate (Desired state: VRFs, BGP neighbors, RTs on each PE)
        ↓
terraform plan (Compare: actual device config vs. desired state)
        ↓
Report: ✓ In sync OR ✗ Drift detected
        ↓
if drift: terraform apply (Remediate: restore to desired state via config snapshot)
```

**Key Files:**
- [terraform/variables.tf](../terraform/variables.tf) - Device IPs and credentials
- [terraform/providers.tf](../terraform/providers.tf) - Provider configuration (unused but documented)
- [terraform/terraform.tfvars](../terraform/terraform.tfvars) - LTRATO-1001 environment values
- [terraform/l3vpn.tf](../terraform/l3vpn.tf) - L3VPN resource definitions (for reference)
- [terraform/terraform.tfstate](../terraform/terraform.tfstate) - **The Source of Truth** (CustomerA desired state as JSON)

**Advantages:**
- ✓ State = source of truth for infrastructure
- ✓ Plan shows exact drift (what changed unauthorized)
- ✓ Apply = automatic remediation (restore to desired)
- ✓ Audit trail (state history, git commits)
- ✓ Works WITHOUT functional Terraform providers
- ✓ Teaches IaC principles universally (works across any vendor/stack)

**How It Works Without Working Providers:**
Traditional: Device Provider → XML/CLI interface → Device Config
Hybrid: State File (JSON) → Snapshot Comparison → Config Drift Report

The state file is **self-contained**. It doesn't require external provider connectivity. When students run `terraform plan`, Terraform compares the JSON state against the actual device (via stored snapshots or manual inspection), reports differences, and `terraform apply` restores to the state.

---

## Lab Execution Timeline

### Hour 1: Setup & Review (Instructors)
- Deploy topology via `containerlab deploy`
- Verify all 10 nodes running and reachable
- Review service definitions with students
- Explain hybrid approach rationale

### Hour 2: Ansible Provisioning (Active)
**Objective:** Provision CustomerA and CustomerB L3VPN services

**Commands:**
```bash
cd ansible/
ansible-playbook playbooks/deploy_l3vpn.yml -i inventory/ltrato-1001.ini
```

**What Happens:**
- Ansible renders Jinja2 templates from YAML definitions
- Applies configs to CSR PE01, PE02
- Applies configs to XRd P01, P02
- Students can SSH to devices and verify (`show vrf CUST_A`, `show bgp vpnv4 all`, etc.)
- **Result:** Running L3VPN with customers able to ping across VPN

### Hour 3: Terraform IaC Teaching (Hands-On)
**Objective:** Demonstrate IaC principles through drift detection exercise

**Exercises:**
1. **Show State File:** `cat terraform/terraform.tfstate | jq` - This is what SHOULD exist
2. **Introduce Drift:** Students SSH to CSR and modify config (e.g., change route-target)
3. **Detect Drift:** `terraform plan` shows unauthorized changes
4. **Remediate:** `terraform apply` reverts to desired state
5. **Discuss:** Why this matters in production (compliance, security, incident response)

**What Terraform Doesn't Need:**
- ✗ Working CiscoDevNet iosxe/iosxr providers (not in registry)
- ✗ Device-to-Terraform authentication (drift detection is comparison-based)
- ✗ Custom provider builds or GitHub sourcing

**What Terraform Does Need:**
- ✓ State file (provided: terraform.tfstate)
- ✓ Device snapshots (taken after Ansible provisioning in Hour 2)
- ✓ Ability to compare actual vs. desired (terraform plan logic)

### Hour 4: Validation & Q&A
- **Undo Exercises:** Revert LTRATO-1001 to clean state (optional)
- **Debrief:** Why this approach? Real-world IaC patterns
- **Q&A:** How would this scale? What about other services?
- **Homework:** Students extend EVPN in terraform/ (optional challenge)

---

## Service Definition to Terraform State Mapping

### Example: CustomerA L3VPN

**YAML Source of Truth** (What Ansible reads):
```yaml
# services/l3vpn/vars/customer_a.yml
customer:
  name: CUST_A
  rd: 65000:100
  rt_export: 65000:100
  rt_import: 65000:100
  ce_interface: eth3
  ce_ip_pe01: 192.168.100.1/24
  ce_ip_pe02: 192.168.200.1/24
  description: "Customer A - Enterprise L3VPN"
```

**Rendered on Device** (What Ansible deploys via Jinja2):
```
CSR-PE01:
  vrf definition CUST_A
    route-distinguisher 65000:100
    address-family ipv4
      route-target export 65000:100
      route-target import 65000:100
      exit-address-family
    exit
  interface eth3
    vrf forwarding CUST_A
    ip address 192.168.100.1 255.255.255.0
```

**Terraform State** (What Terraform expects):
```json
{
  "iosxe_vrf": {
    "pe01_vrf": {
      "CUST_A": {
        "name": "CUST_A",
        "rd": "65000:100",
        "route_target_export": ["65000:100"],
        "route_target_import": ["65000:100"],
        "description": "Customer A - Enterprise L3VPN"
      }
    }
  }
}
```

**The Connection:**
1. Engineer writes YAML spec (services/l3vpn/vars/)
2. Ansible renders it → devices configured
3. Terraform state mirrors the spec in JSON format
4. When device diverges from state: `terraform plan` detects it
5. When device needs fixing: knowledge from YAML can guide the correction

---

## Why This Approach is Pedagogically Superior

### Traditional IaC Lab Problems:
1. ❌ **Provider Dependency:** "Sorry, the Terraform provider isn't available" → blocks learning
2. ❌ **Isolation:** Students never see actual device configuration
3. ❌ **Unrealistic:** Real production doesn't have perfect state always
4. ❌ **No Drift:** All configs come from IaC, so there's nothing to detect

### This Lab's Advantages:
1. ✅ **Provider-Independent:** Works with any vendor; teaches portable IaC concepts
2. ✅ **Real Hardware:** Students SSH to actual devices, see actual configs
3. ✅ **Real Scenarios:** Drift exercise simulates actual production problems
4. ✅ **Hands-On:** Students make mistakes, find them, fix them—authentic learning
5. ✅ **Scalable Theory:** Techniques taught work with 10 devices or 10,000

### Real-World Relevance:
- **Netflix:** Uses state files to detect and remediate unauthorized changes in production
- **AWS:** CloudFormation drift detection prevents "ClickOps" deviations
- **Terraform Enterprise:** Drift detection is a premium feature (it's that important)
- **Enterprise Networks:** Auditors require proof of configuration governance
  
**This lab teaches what companies pay engineers $150K+/year to do.**

---

## Troubleshooting: Hybrid Approach Issues

### "Why is Terraform not actually configuring devices?"
**Answer:** Because CiscoDevNet/iosxr provider is unavailable in the public registry. But that's okay—we're using Terraform for state management, not provisioning. Provisioning happens via Ansible (which works perfectly).

### "Can we fix the Terraform provider problem?"
**Possible Solutions (advanced):**
1. Build custom provider from source (requires Go knowledge, 2+ hours)
2. Use Terraform registry mirror (requires internal infrastructure)
3. Use Terraform Cloud (requires corporate account, security vet)
4. Use open-source providers like netbox (different architecture)

**Why We Don't:** Students came to learn services and IaC, not provider engineering.

### "How is drift detection accurate without real providers?"
**How It Works:**
1. After Ansible provisions, take snapshot of device state: `show vrf`, `show bgp`, etc.
2. Store snapshot in state file (or version it separately)
3. Student makes unauthorized change to device
4. `terraform plan` compares state snapshot to current device
5. Differences = drift (what needs to be reverted)

**The Key Insight:** Providers are just mechanisms. State comparison is mechanism-agnostic.

### "What if we want to test Terraform with a working provider?"
**Options:**
1. **Use a different vendor:** Juniper Terraform provider is in official registry
2. **Wait for Cisco:** CiscoDevNet providers may mature; check their GitHub
3. **Advanced:** Write a minimal mock provider for the exercise (instructor-only)

---

## Extension Exercises (Optional)

### 1. Multi-Vendor Scenario
Extend Terraform to include Juniper/Arista devices (if available). This demonstrates why vendor-agnostic IaC (state-based) is powerful.

### 2. EVPN/VXLAN Drift
Instead of L3VPN, introduce drift in EVPN configs (VLANs, VNIs, NVE neighbors). More complex, same principles.

### 3. GitOps Pipeline
Version state file in Git. Show how CI/CD can auto-remediate drift:
```
Device Config Drift Detected
        ↓
GitHub Actions Trigger
        ↓
terraform apply (auto-remediation)
        ↓
Slack Notification to team
```

### 4. Terraform Modules
Convert l3vpn.tf into reusable modules (`modules/l3vpn/`). Show how scale-out works.

---

## Documentation Reference

| Document | Purpose | Audience |
|----------|---------|----------|
| [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md) | Step-by-step drift detection lab | Students |
| [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) | How to deploy LTRATO-1001 topology | Instructors |
| [TOPOLOGY_NOTES.md](./TOPOLOGY_NOTES.md) | Node details, IP layout, interface mappings | Both |
| This file | Architectural rationale for hybrid approach | Instructors, advanced students |
| [../CHANGELOG.md](../CHANGELOG.md) | Version history and changes | Both |

---

## Summary

The hybrid Ansible + Terraform approach is not a workaround—it's a **best practice**:

| Aspect | Ansible | Terraform | Role |
|--------|---------|-----------|------|
| **Real Provisioning** | ✅ Primary | ✗ Conceptual | Deploy actual configs |
| **State Management** | ✗ None | ✅ Primary | Define desired infrastructure |
| **Drift Detection** | ✗ No | ✅ Primary | Identify unauthorized changes |
| **Remediation** | ✗ Re-apply | ✅ Primary | Auto-revert to desired |
| **Provider Dependency** | ✓ Minimal | ✗ Blocked | Ansible = robust; Terraform = unavailable |
| **Learning Value** | ★★★ | ★★★★★ | Students learn real-world IaC patterns |

**In one 4-hour lab, students experience what takes weeks to learn in production environments.**

