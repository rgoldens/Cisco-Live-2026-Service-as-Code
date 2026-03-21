# Drift Detection Exercise: Hands-On IaC Learning

## Overview

This exercise teaches the critical infrastructure-as-code principle: **Single Source of Truth (SoT)** through hands-on drift detection and automatic remediation.

### Why This Matters
In production environments, operators sometimes make unauthorized manual configuration changes that bypass change control. IaC tools detect these "drift" changes and either alert teams or automatically revert to the desired state. This exercise simulates a real-world scenario.

### Learning Objectives
1. Understand how Terraform state represents the desired configuration
2. Learn to detect unauthorized manual changes using `terraform plan`
3. Experience automatic remediation via `terraform apply`
4. Appreciate why IaC prevents configuration sprawl and ensures consistency

---

## Prerequisites

- **Lab Time: 15 minutes** (fits within Hour 3)
- **Completed:** Ansible L3VPN provisioning (Hour 2)
- **Ready:** Terraform state file (`terraform/terraform.tfstate`)
- **Network Access:** SSH access to CSR PE routers (172.20.20.20, 172.20.20.21)

---

## Exercise Steps

### Phase 1: Understand the Current State (2 minutes)

**Objective:** Show students what Terraform believes is the desired configuration.

#### Step 1.1: Review Terraform State File
```bash
cd /path/to/terraform
cat terraform.tfstate | jq '.resources[] | {type, name, attributes: .instances[0].attributes}' | head -50
```

**What Students Should See:**
- VRF `CUST_A` on both PE01 and PE02
- Route Distinguisher: `65000:100`
- Route Targets (export/import): `65000:100`
- BGP neighbors to RRs (10.0.0.1, 10.0.0.2)
- BGP address family configuration for CUST_A

**Key Talking Points:**
> "This state file is our Source of Truth. It defines exactly what the network SHOULD look like. Terraform will compare actual device config to this state and report any differences."

---

### Phase 2: Make an Authorized Change (2 minutes)

**Objective:** Change the route-target export from `65000:100` to `65000:110` via Ansible (simulating a legitimate service requirement change).

#### Step 2.1: Update Service Definition
Edit `services/l3vpn/vars/customer_a.yml`:
```yaml
rt_export: 65000:110  # ← Changed from 65000:100
```

#### Step 2.2: Re-run Ansible Playbook
```bash
cd /path/to/ansible
ansible-playbook playbooks/deploy_l3vpn.yml -i inventory/ltrato-1001.ini
```

#### Step 2.3: Verify Change on Device
```bash
ssh -u admin 172.20.20.20
# Password: admin
csr-pe01# show vrf CUST_A
VRF Name                             : CUST_A
  Default RD                         : 65000:100
  Address Family IPv4 Unicast
    Export VPN RT: 65000:110  ← ✅ Changed!
    Import VPN RT: 65000:100
```

**Key Point:**
> "Real people make real config changes. Terraform needs to understand this was intentional. Now we update the state file to match."

#### Step 2.4: Update Terraform State
```bash
cd /path/to/terraform
# Edit terraform.tfstate manually to reflect the change
sed -i 's/"value": "65000:100"/"value": "65000:110"/g' terraform.tfstate

# Or use Terraform import (if using a full provider setup)
terraform import iosxe_vrf.pe01_vrf csr-pe01/CUST_A
```

After update, state file should show:
```json
"route_target_export": [
  {
    "value": "65000:110"
  }
]
```

---

### Phase 3: Introduce Drift (2 minutes)

**Objective:** A developer manually changes config, violating change control procedures.

#### Step 3.1: SSH to CSR PE01
```bash
ssh admin@172.20.20.20
# Password: admin
```

#### Step 3.2: Make an Unauthorized Change
```bash
csr-pe01# config t
csr-pe01(config)# vrf definition CUST_A
csr-pe01(config-vrf)# route-target import 65000:200
csr-pe01(config-vrf)# exit
csr-pe01(config)# end
csr-pe01# write memory
```

**What Changed:**
- Import RT was `65000:100` → now also imports `65000:200`
- This happened **outside of change control** (no Ansible, no Terraform)
- The developer thought they had a good reason, but didn't coordinate with the IaC team

**Key Talking Point:**
> "This is the moment configuration sprawl begins. Without drift detection, nobody notices for days. Competitors change happens silently. Terraform will catch it immediately."

#### Step 3.3: Verify the Unauthorized Change
Still in SSH session:
```bash
csr-pe01# show vrf CUST_A
VRF Name                             : CUST_A
  Default RD                         : 65000:100
  Address Family IPv4 Unicast
    Export VPN RT: 65000:110
    Import VPN RT: 65000:100, 65000:200  ← ⚠️ UNAUTHORIZED!
```

---

### Phase 4: Detect the Drift (2 minutes)

**Objective:** Show how Terraform immediately reveals configuration inconsistencies.

#### Step 4.1: Run Terraform Plan
```bash
cd /path/to/terraform
terraform plan
```

**Expected Output:**
```
iosxe_vrf.pe01_vrf: Refreshing state...

  # iosxe_vrf.pe01_vrf["CUST_A"] will be updated in-place
  ~ resource "iosxe_vrf" "pe01_vrf" {
      id                       = "csr-pe01/CUST_A"
      name                     = "CUST_A"
      rd                       = "65000:100"
      route_target_export      = ["65000:110"]
      ~ route_target_import    = [
          - "65000:200",  ← This was added without authorization
          + "65000:100",  ← This is what should be present
        ]
      ipv4_unicast           = true
      description            = "Customer A - Enterprise L3VPN"
    }

Plan: 0 to add, 1 to modify, 0 to destroy.
```

**Discussion Points:**
1. **Red Flag:** Terraform detected an unauthorized import route-target
2. **Root Cause Analysis:** Someone added 65000:200 without updating service definition or IaC pipeline
3. **Automated Remediation:** `terraform apply` will automatically remove it
4. **Audit Trail:** We know EXACTLY what changed, when, and can investigate why

#### Step 4.2: Show Plan Output to Students
Display the plan and ask:
- ❓ "What changed on the device?"
- ❓ "How did Terraform know about it?"
- ❓ "Why is this a problem?"
- ✅ "Because the DESIRED state (in terraform.tfstate) becomes the source of truth"

---

### Phase 5: Automatic Remediation (2 minutes)

**Objective:** Demonstrate automatic drift correction.

#### Step 5.1: Apply Terraform Changes
```bash
cd /path/to/terraform
terraform apply
```

**Output:**
```
iosxe_vrf.pe01_vrf["CUST_A"] will be modified as planned...

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

#### Step 5.2: Verify Correction on Device
```bash
ssh admin@172.20.20.20
csr-pe01# show vrf CUST_A
VRF Name                             : CUST_A
  Default RD                         : 65000:100
  Address Family IPv4 Unicast
    Export VPN RT: 65000:110
    Import VPN RT: 65000:100  ← ✅ Back to SoT!
```

**Key Moment:**
> "Without any manual intervention, Terraform reverted the configuration back to the desired state. The unauthorized change is gone. This is the power of IaC."

---

## Phase 6: Repeat with Different Drift (Optional, 3-5 minutes)

To reinforce learning, repeat with a different unauthorized change:

### Variant A: BGP Neighbor Password Change
```bash
csr-pe01# config t
csr-pe01(config)# router bgp 65000
csr-pe01(config-router)# neighbor 10.0.0.1 password MySecretPassword123
csr-pe01(config-router)# end
```

Then `terraform plan` will show the password field changed, and `terraform apply` reverts it.

### Variant B: VRF Description Modification
```bash
csr-pe01# config t
csr-pe01(config)# vrf definition CUST_A
csr-pe01(config-vrf)# description HACKED BY OPERATOR
csr-pe01(config-vrf)# end
```

Then `terraform plan` will show the description drift, and `terraform apply` reverts it.

---

## Debrief & Key Takeaways (3 minutes)

### Discussion Questions:
1. **Before IaC:** How would you discover that an unauthorized change happened? (Answer: You wouldn't, until something breaks)
2. **With IaC:** How much time did it take to detect and fix? (Answer: Seconds)
3. **In Production:** What if someone accidentally changed a route-target that broke customer connectivity? (Answer: IaC catches it immediately; without IaC, you notice when customers complain)
4. **Compliance:** Why would auditors love this? (Answer: Automated drift detection = compliance proof)

### Key Principles Demonstrated:
- ✅ **Single Source of Truth:** State file is authoritative
- ✅ **Drift Detection:** Plan detects unauthorized changes
- ✅ **Automatic Remediation:** Apply reverts to desired state
- ✅ **Infrastructure as Code:** Code (state) is law; actual config must match

### Real-World Application:
> "In most enterprises, 40-60% of 'infrastructure' is undocumented manual changes. IaC with drift detection prevents this. You're learning what Netflix, Google, and AWS do at scale."

---

## Terraform State File Format Reference

For instructors: The provided `terraform.tfstate` file is pre-populated with CustomerA L3VPN configuration. Students don't need to create it; it provides:

```json
{
  "iosxe_vrf": {
    "pe01_vrf": { "CUST_A": { "rd": "65000:100", "rt_export": "65000:100", "rt_import": "65000:100" } },
    "pe02_vrf": { "CUST_A": { "rd": "65000:100", "rt_export": "65000:100", "rt_import": "65000:100" } }
  },
  "iosxe_bgp_neighbor": {
    "pe01_rr1": { "asn": 65000, "ip": "10.0.0.1" },
    "pe01_rr2": { "asn": 65000, "ip": "10.0.0.2" },
    "pe02_rr1": { "asn": 65000, "ip": "10.0.0.1" },
    "pe02_rr2": { "asn": 65000, "ip": "10.0.0.2" }
  },
  "iosxe_bgp_address_family_ipv4_vrf": {
    "pe01_vrf_af": { "CUST_A": { "asn": 65000, "maximum_paths": 32 } },
    "pe02_vrf_af": { "CUST_A": { "asn": 65000, "maximum_paths": 32 } }
  }
}
```

This represents the **desired state** that Terraform will enforce. Any deviation triggers a plan diff.

---

## Troubleshooting

### Problem: `terraform plan` shows no drift
**Cause:** Manual changes on device were reverted by someone else
**Solution:** Repeat Phase 3 (introduce drift) with new unauthorized change

### Problem: Cannot SSH to CSR routers
**Cause:** Networking issue or container not running
**Solution:** Verify topology: `docker ps | grep csr`

### Problem: Terraform state file is invalid JSON
**Cause:** Manual editing mistake
**Solution:** Restore from backup: `git checkout terraform/terraform.tfstate`

---

## Time Budget

| Phase | Duration | Activity |
|-------|----------|----------|
| Phase 1 (Review State) | 2 min | Show desired config in state file |
| Phase 2 (Auth Change) | 2 min | Update service definition via Ansible |
| Phase 3 (Introduce Drift) | 2 min | Make unauthorized manual change via SSH |
| Phase 4 (Detect Drift) | 2 min | Run `terraform plan` and show diff |
| Phase 5 (Remediate) | 2 min | Run `terraform apply` and verify revert |
| Variant Drift (Optional) | 3-5 min | Repeat with different change type |
| Debrief | 3 min | Discuss IaC principles and real-world impact |
| **Total** | **15-20 min** | Fits within Hour 3 Terraform block |

---

## For Instructors: Post-Exercise Talking Points

1. **Why State Files Matter:** "The state file is ground truth. It's more important than the actual device config."
2. **Why Terraform (Not Just Ansible):** "Ansible is great for deploying. Terraform adds drift detection, making Ansible safer and more auditable."
3. **Hybrid Approach Advantage:** "We use Ansible for the heavy lifting (provisioning), Terraform for the safety net (drift detection). Best of both worlds."
4. **Scaling:** "In 1-2 devices, manual config is manageable. With 100+ devices, drift detection becomes critical. IaC is not optional at scale."
5. **Career Impact:** "Companies literally hire engineers for 'IaC' knowledge. This exercise teaches what they're paid to do."

