# =============================================================================
# PRESENTATION OUTLINE
# Service as Code Lab — Cisco Live 2026
#
# Duration: 4 hours (240 minutes)
# Audience: 30 attendees, individual lab instances
# Format:   Modular sections (each standalone-reusable)
# =============================================================================

---

## Session Overview

**Title:** Service as Code — Provisioning Network Services with Ansible, Terraform, and YAML

**Subtitle:** A hands-on lab using Cisco XRd, CSR1000v, and Nexus 9000v on containerlab

**Primary Takeaway:** Network configuration IS code. The mindset shift from CLI-first to definition-first service provisioning.

**Approach:** Tool-agnostic. Ansible and Terraform are presented as full alternatives — not competitors. The focus is on the *concept* of declaring services in YAML and rendering them to device config, regardless of which engine you use.

**Target Audience:** Network engineers with basic CLI familiarity. Mixed experience levels — some may know Ansible, some Terraform, some neither.

---

## Time Budget

| Module | Title | Duration | Running Total |
|--------|-------|----------|---------------|
| 0 | Welcome & Environment Setup | 15 min | 0:15 |
| 1 | The Service as Code Mindset | 15 min | 0:30 |
| 2 | Lab Topology & Underlay Walk-Through | 20 min | 0:50 |
| 3 | Source of Truth: YAML Service Definitions | 15 min | 1:05 |
| 4 | Lab Exercise 1 — Explore the Topology | 15 min | 1:20 |
| 5 | Ansible Path: L3VPN Provisioning | 25 min | 1:45 |
| 6 | Lab Exercise 2 — Provision L3VPN with Ansible | 30 min | 2:15 |
| 7 | Terraform Path: Declarative L3VPN | 20 min | 2:35 |
| 8 | Lab Exercise 3 — Provision L3VPN with Terraform | 15 min | 2:50 |
| 9 | EVPN/VXLAN Extension & Validation | 25 min | 3:15 |
| 10 | Lab Exercise 4 — EVPN + Validation | 30 min | 3:45 |
| 11 | Wrap-Up, Q&A & Open Lab | 15 min | 4:00 |

**Total: 240 minutes (4 hours)**

---

## Module 0 — Welcome & Environment Setup (15 min)

**Objective:** Get every attendee connected to their lab instance and verify the environment is working.

### Instructor Actions
- Welcome, introductions, housekeeping (Wi-Fi, restrooms, breaks)
- Distribute lab assignment sheet (attendee name → host IP)
- Display topology diagram on projector

### Attendee Actions
- SSH to their assigned lab host
- Verify Docker is running: `docker ps`
- Confirm lab is deployed: `make inspect`
- Verify all 7 containers are running

### Key Points
- Lab is pre-deployed — no waiting for boot
- All `make` commands are available; run `make help` for reference
- Credentials: XRd `clab/clab@123`, CSR and N9Kv `admin/admin`

### Checkpoint
- [ ] All 30 attendees can SSH to their lab host
- [ ] `make inspect` shows 7/7 running on every instance

---

## Module 1 — The Service as Code Mindset (15 min)

**Objective:** Establish the core concept — network services should be defined as data, versioned, reviewed, and rendered by automation.

### Content (Presentation / Discussion)

1. **The problem with CLI-first operations**
   - Config drift, tribal knowledge, manual errors
   - "The network is a snowflake" anti-pattern
   - No review process for network changes

2. **What is Service as Code?**
   - Service = customer-facing intent (L3VPN, EVPN tenant)
   - Code = YAML definitions + templates + automation engine
   - The service definition is the single source of truth
   - Device config is a *rendered output*, not the source

3. **The SaC workflow**
   ```
   YAML Service Definition → Git (branch + MR) → CI/CD Pipeline → Template Engine → Device Config → Validation
         (human intent)       (review + approve)   (auto-trigger)    (Jinja2/HCL)    (push to device)   (assert state)
   ```

4. **Why tool-agnostic?**
   - Ansible = imperative push (playbook runs, applies config)
   - Terraform = declarative state (plan → apply → state tracking)
   - Same YAML input, same result — different engine
   - Choose based on your team's workflow, not religion

### No lab exercise in this module — concept-only.

---

## Module 2 — Lab Topology & Underlay Walk-Through (20 min)

**Objective:** Understand the 7-node SP topology, the role of each device, and the underlay protocols already configured.

### Content (Instructor-led with topology diagram)

1. **Topology overview** (refer to `topology/sac-lab.yml`)
   ```
   [xrd01]---P-P core---[xrd02]           ← IS-IS + LDP backbone
      |                     |
   [csr-pe01]---inter-PE---[csr-pe02]      ← PE routers, L3VPN termination
      |                     |
   [n9k-ce01]---DC link---[n9k-ce02]       ← CE/DC switches, VXLAN/EVPN
      |
   [linux-client]                          ← Test endpoint
   ```

2. **Device roles**
   - **XRd (P-routers / Route Reflectors):** IS-IS area 49.0001, LDP, BGP VPNv4 RR
   - **CSR1000v (PE routers):** IS-IS, LDP, VRF-aware, BGP VPNv4 to RRs, NETCONF enabled
   - **N9Kv (CE/DC switches):** OSPF underlay, VXLAN VTEP, BGP EVPN
   - **Alpine Linux:** Simple test client in CUST_A subnet

3. **Addressing plan** (see INSTRUCTOR_CHECKLIST.md Quick Reference Card)
   - Loopbacks: 10.0.0.X/32
   - Point-to-point: 10.0.X.Y/30
   - Customer subnets: 192.168.X.0/24

4. **What's pre-configured vs. what we'll provision**
   - Pre-configured (startup-config): interfaces, IS-IS, LDP, BGP structure, OSPF underlay
   - To be provisioned (lab exercises): VRFs, VRF interfaces, VPNv4 neighbors, VXLAN VNIs, EVPN

---

## Module 3 — Source of Truth: YAML Service Definitions (15 min)

**Objective:** Understand the YAML service definition files that drive all provisioning.

### Content (Live walkthrough + code review)

1. **L3VPN definitions** — `services/l3vpn/vars/customer_a.yml`
   - Customer name, VRF, RD, RT
   - PE interface bindings (which PE, which interface, what IP)
   - CE neighbor information
   - Expected prefixes (for validation)
   - "This is the *entire* service definition. Everything else is derived."

2. **EVPN definitions** — `services/evpn/vars/vxlan_tenant.yml`
   - Tenant name, VLANs, VNIs
   - VTEP source per switch
   - BGP EVPN peering
   - OSPF underlay parameters

3. **Templates** — `services/l3vpn/templates/csr_pe_l3vpn.j2`
   - Jinja2 template that reads the YAML and produces IOS-XE CLI
   - "The template is the bridge between human intent and device syntax"

4. **Key insight:** To add a new customer, you write a YAML file. You don't touch device CLI. You don't modify playbooks or Terraform. You add data, and the system renders it.

---

## Module 4 — Lab Exercise 1: Explore the Topology (15 min)

**Objective:** Hands-on verification that the underlay is working and all adjacencies are formed.

### Exercise Steps (Attendee Guide)

1. SSH to xrd01 and verify IS-IS adjacencies:
   ```
   ssh clab@<xrd01-ip>
   show isis neighbors
   show mpls ldp neighbor brief
   show bgp vpnv4 unicast summary
   ```

2. SSH to csr-pe01 and verify PE underlay:
   ```
   ssh admin@<csr-pe01-ip>
   show isis neighbors
   show mpls ldp neighbor
   show bgp vpnv4 unicast all summary
   show ip vrf
   ```

3. SSH to n9k-ce01 and verify OSPF:
   ```
   ssh admin@<n9k-ce01-ip>
   show ip ospf neighbors
   show nve peers
   ```

4. Note: VRFs are not yet configured. `show ip vrf` on CSR will show nothing or minimal output. This is expected — we'll provision them next.

### Checkpoint
- [ ] IS-IS adjacencies UP on xrd01 (2 neighbors) and csr-pe01 (2 neighbors)
- [ ] LDP sessions established between P and PE routers
- [ ] BGP VPNv4 sessions Established on RRs
- [ ] N9Kv OSPF neighbor UP between ce01 and ce02

---

## Module 5 — Ansible Path: L3VPN Provisioning (25 min)

**Objective:** Walk through the Ansible playbook that reads YAML and pushes L3VPN config.

### Content (Instructor-led code review + live demo)

1. **Ansible inventory** — `ansible/inventory/hosts.yml`
   - Groups: xrd, csr, n9kv, linux
   - Convenience groups: pe_routers, p_routers, ce_switches
   - Connection vars per group (group_vars/)

2. **L3VPN playbook** — `ansible/playbooks/deploy_l3vpn.yml`
   - Play 1: PE routers (IOS-XE) — load YAML vars, render Jinja2 template, apply via `cisco.ios.ios_config`
   - Play 2: P-routers (IOS-XR) — ensure BGP VPNv4 RR config
   - Dynamic: fileglob finds all `*.yml` in `services/l3vpn/vars/` — add a file, get a new customer

3. **Template rendering** — `services/l3vpn/templates/csr_pe_l3vpn.j2`
   - VRF definition, RD, RT import/export
   - Interface → VRF binding + IP assignment
   - BGP VRF address-family + CE neighbor
   - "One template serves all customers — the YAML varies, the template stays constant"

4. **Idempotency demo** (instructor shows on own instance)
   ```bash
   make provision-l3vpn    # First run — changes applied
   make provision-l3vpn    # Second run — no changes (idempotent)
   ```

5. **Validation playbook** — `ansible/playbooks/validate.yml`
    - Asserts BGP VPNv4 sessions are established
    - Checks VRF route table for expected prefixes
    - Pings from linux-client through the VRF

---

## Module 5.5 — YANG Schema Validation in GitOps Pipelines (Bonus Content)

**Context:** Before Ansible templates are rendered and configs deployed, the GitLab CI/CD pipeline validates service definitions against a YANG data model — this adds a **schema enforcement layer** that catches errors early.

### Why YANG?

YANG (RFC 6020) is the **standard notation for data models** used by network devices. Rather than reinventing validation, we use Cisco's YANG models to:
- Define the canonical schema for L3VPN services
- Enforce constraints (required fields, value patterns, ranges)
- Provide vendor-aware validation before any device is touched

### How It Works in the Pipeline

```
1. Student edits YAML service file (customer_c.yml)
   ↓
2. Push to GitLab (triggers CI pipeline)
   ↓
3. Pipeline Stage 1: validate-yang-l3vpn
   → Runs: python3 scripts/validate-yang.py services/l3vpn/vars/*.yml
   → Checks: required fields (customer, vrf, rd, rt_import, rt_export, pe_interfaces)
   → Validates: field types and patterns (VRF must be uppercase, RD must match ASN:value format)
   → Result: PASS → proceed to Stage 2 | FAIL → block deployment (hard blocker)
   ↓
4. Pipeline Stage 2: validate-l3vpn-yaml (Ansible assertions)
   → Runs only if YANG validation passes
   → Checks: business logic (BGP neighbors, prefix assertions, etc.)
   ↓
5. Pipeline Stage 3: deploy-l3vpn (Ansible playbook)
   → Runs only if both YANG and Ansible validations pass
   → Pushes config to routers
```

### The Defense-in-Depth Pattern

- **YANG validation** → catches schema errors (missing fields, bad types)
- **Ansible validation** → catches business logic errors (BGP convergence, routing)
- **Deploy** → pushes only when all validations pass

This layered approach ensures that both the **intent** (YAML service definition) and the **logic** (BGP peering, route targets) are correct before any device is configured.

### Key Takeaway

In the "Break It, Fix It" exercise coming up, you'll delete the `rd:` field. The pipeline will catch this **before** deployment, showing that YANG validation is your first line of defense. The CI/CD pipeline is a safety net.

---

## Module 6 — Lab Exercise 2: Provision L3VPN with Ansible (30 min)

**Objective:** Attendees provision L3VPN services using Ansible and validate the result.

### Exercise Steps

1. Review the Customer A service definition:
   ```bash
   cat services/l3vpn/vars/customer_a.yml
   ```

2. Run the L3VPN provisioning playbook:
   ```bash
   make provision-l3vpn
   ```

3. Verify on csr-pe01:
   ```
   ssh admin@<csr-pe01-ip>
   show ip vrf
   show ip vrf CUST_A
   show ip route vrf CUST_A
   show bgp vpnv4 unicast all summary
   ```

4. Run validation:
   ```bash
   make validate
   ```

5. **GitOps workflow:** Use GitLab to deploy Customer C. Clone from local GitLab (`http://localhost:8080`), create a branch, add `customer_c.yml`, commit, push, create a Merge Request in the web UI, wait for the validation pipeline to pass, merge, and watch the deploy pipeline automatically run `ansible-playbook`.

6. **Break It, Fix It:** After Customer C is deployed, have attendees deliberately delete the `rd:` field from `customer_c.yml`, commit, and push. 
   - The pipeline's **YANG validation stage fails first** with `YANG validation failed` and reports `Missing required field: 'rd'`
   - The **deploy job never runs** because YANG validation is a hard blocker
   - Students observe that the pipeline caught the error *before* any device config was touched
   - Then students restore the `rd:` field, push again, watch YANG validation pass, Ansible validation pass, and deploy run
   - Confirm CUST_C is on the router
   - This demonstrates the **defense-in-depth pattern**: YANG schema check → Ansible business logic check → Deploy only if both pass

### Checkpoint
- [ ] `make provision-l3vpn` completes without errors
- [ ] VRF CUST_A and CUST_B appear on both PEs
- [ ] `make validate` passes all assertions
- [ ] (GitOps) Customer C deployed via GitLab CI/CD pipeline
- [ ] (Break It) Pipeline failed on missing `rd:` — deploy did NOT run
- [ ] (Fix It) Pipeline passed after restoring `rd:` — CUST_C confirmed on router

---

## Module 7 — Terraform Path: Declarative L3VPN (20 min)

**Objective:** Show the same L3VPN provisioning using Terraform — same outcome, different engine.

### Content (Instructor-led code review + live demo)

1. **Why Terraform as an alternative?**
   - Declarative: you define desired state, Terraform figures out changes
   - State tracking: Terraform knows what it created and can destroy/update precisely
   - Plan before apply: `terraform plan` shows what WILL change before it does

2. **Provider setup** — `terraform/providers.tf`
   - CiscoDevNet/iosxe provider (RESTCONF-based)
   - CiscoDevNet/iosxr provider
   - Two instances per PE (aliased: pe01, pe02)

3. **Service as HCL variables** — `terraform/terraform.tfvars`
   - Same data as the YAML SoT, but in HCL format
   - "In production, you'd generate .tfvars from YAML automatically"

4. **Resource definitions** — `terraform/l3vpn.tf`
   - `iosxe_vrf` resources (VRF, RD, RT)
   - `iosxe_bgp_neighbor` resources (VPNv4 peering)
   - `for_each` iteration over service bindings
   - Outputs showing what was provisioned

5. **Live demo** (instructor on own instance):
   ```bash
   make tf-init     # Download providers
   make tf-plan     # Preview changes
   make tf-apply    # Apply declaratively
   make tf-destroy  # Clean removal
   ```

6. **Comparison slide:**
   | Aspect | Ansible | Terraform |
   |--------|---------|-----------|
   | Model | Imperative push | Declarative state |
   | Execution | Playbook runs | Plan → Apply |
   | State | None (stateless) | terraform.tfstate |
   | Idempotency | Template checks | State diff |
   | Rollback | Reverse playbook | `terraform destroy` |

---

## Module 8 — Lab Exercise 3: Provision L3VPN with Terraform (15 min)

**Objective:** Attendees run the Terraform workflow and see the same VRFs provisioned.

### Exercise Steps

1. **Important:** If you still have Ansible-provisioned VRFs, that's fine — Terraform will manage its own resources via RESTCONF. For a clean comparison, you can remove the Ansible-pushed config first (optional).

2. Initialize Terraform:
   ```bash
   make tf-init
   ```

3. Review the plan:
   ```bash
   make tf-plan
   ```
   - Note the resources Terraform wants to create
   - Compare with what Ansible did — same VRFs, same config

4. Apply:
   ```bash
   make tf-apply
   ```

5. Verify on csr-pe01 (same checks as Exercise 2):
   ```
   show ip vrf
   show ip route vrf CUST_A
   ```

6. Review Terraform state:
   ```bash
   cat terraform/terraform.tfstate | python3 -m json.tool | head -50
   ```

7. Clean up (destroy Terraform-managed resources only):
   ```bash
   make tf-destroy
   ```

### Checkpoint
- [ ] `make tf-plan` shows expected resources
- [ ] `make tf-apply` completes without errors
- [ ] VRFs verified on PE routers
- [ ] `make tf-destroy` cleanly removes Terraform-managed resources

---

## Module 9 — EVPN/VXLAN Extension & Validation (25 min)

**Objective:** Extend the SaC concept to a second service type — EVPN/VXLAN on the N9Kv DC switches.

### Content (Instructor-led + demo)

1. **EVPN/VXLAN service definition** — `services/evpn/vars/vxlan_tenant.yml`
   - Tenant, VLANs, VNIs, VTEP sources
   - BGP EVPN peering between DC switches
   - "Same pattern: YAML in, config out"

2. **EVPN playbook** — `ansible/playbooks/deploy_evpn.yml`
   - Loads tenant YAML
   - Renders NX-OS VXLAN/EVPN template
   - Applies via `cisco.nxos.nxos_config`
   - Verifies NVE peers post-deployment

3. **EVPN template** — `services/evpn/templates/n9k_evpn.j2`
   - VLAN + VNI mapping
   - NVE interface + VTEP source
   - BGP EVPN address family
   - "Different service type, same SaC workflow"

4. **Validation** — `ansible/playbooks/validate.yml` (EVPN section)
   - BGP L2VPN EVPN summary
   - NVE peer status
   - VXLAN VNI status

5. **Demo:**
   ```bash
   make provision-evpn
   make validate
   ```

6. **The SaC pattern generalizes:**
   - L3VPN: YAML → Jinja2 → IOS-XE CLI
   - EVPN: YAML → Jinja2 → NX-OS CLI
   - Any future service: YAML → template → any device
   - "The pattern is the product. The tools are interchangeable."

---

## Module 10 — Lab Exercise 4: EVPN + Full Validation (30 min)

**Objective:** Attendees deploy EVPN, run full validation, and test end-to-end connectivity.

### Exercise Steps

1. Review the EVPN tenant definition:
   ```bash
   cat services/evpn/vars/vxlan_tenant.yml
   ```

2. Deploy EVPN:
   ```bash
   make provision-evpn
   ```

3. Verify on n9k-ce01:
   ```
   ssh admin@<n9k-ce01-ip>
   show vxlan
   show nve peers
   show bgp l2vpn evpn summary
   ```

4. Run full validation:
   ```bash
   make validate
   ```
   - L3VPN checks on PEs
   - EVPN checks on CEs
   - RR checks on P-routers
   - End-to-end ping from linux-client

5. **GitOps workflow:** Modify the EVPN tenant via GitLab — add VLAN 300 with VNI 10300 to `vxlan_tenant.yml`, commit on a branch, push, create MR, merge, and watch the pipeline deploy automatically. Verify the new VNI appears on the N9Kv switches.

### Checkpoint
- [ ] `make provision-evpn` completes without errors
- [ ] NVE peers UP on both N9Kv switches
- [ ] BGP L2VPN EVPN sessions Established
- [ ] `make validate` passes all sections
- [ ] Linux-client can ping 192.168.100.1 (CUST_A gateway)

---

## Module 11 — Wrap-Up, Q&A & Open Lab (15 min)

**Objective:** Reinforce key takeaways, answer questions, and give time for exploration.

### Content

1. **Recap: What did we build?**
   - A 7-node SP topology in containerlab
   - L3VPN and EVPN services defined as YAML
   - Two complete provisioning paths (Ansible + Terraform)
   - Automated validation with assertions
   - A complete GitOps workflow: GitLab → branch → MR → CI/CD pipeline → automated deployment

2. **The SaC principles to take home:**
   - Define services as data (YAML), not as CLI commands
   - Templates bridge human intent to device syntax
   - Automation engines are interchangeable — pick one, or use both
   - Version control your service definitions (git) — you did this today
   - Use Merge Requests for peer review of network changes — you did this today
   - CI/CD pipelines automate validation and deployment — you did this today
   - Validate after every change (assertions, not eyeballs)
   - "If it's not in the YAML, it doesn't exist"

3. **Where to go next:**
   - Scale GitLab CI/CD with more advanced pipelines (staging → production)
   - Add approval gates and manual triggers for critical changes
   - Replace flat-file YAML with NetBox or Nautobot as SoT
   - Explore pyATS/Genie for deeper state validation
   - Scale with AWX/Tower or Terraform Cloud
   - Integrate ChatOps (Slack/Teams notifications on pipeline events)

4. **Open lab time** (remaining minutes)
   - Try the stretch goals if you haven't
   - Create Customer C or Customer D
   - Add a new EVPN VLAN
   - Break something and fix it
   - Ask questions

5. **Feedback & contact**
   - Session survey link
   - Presenter contact info
   - Lab repo access (if sharing post-session)

---

## Appendix: Module Dependency Map

Each module is designed to be standalone-reusable. However, the recommended sequence is:

```
Module 0 (setup) ─── always required
    │
Module 1 (mindset) ─── recommended first
    │
Module 2 (topology) ─── required for exercises
    │
Module 3 (YAML SoT) ─── required for exercises
    │
Module 4 (Exercise 1: explore) ─── prereq for exercises 2-4
    │
    ├── Module 5-6 (Ansible path + Exercise 2 + GitOps) ─── standalone
    │       └── GitOps: branch → MR → CI/CD deploy (replaces stretch goal)
    │
    ├── Module 7-8 (Terraform path + Exercise 3) ─── standalone
    │
    └── Module 9-10 (EVPN + Exercise 4 + GitOps) ─── standalone (but benefits from 5-6)
            └── GitOps: branch → MR → CI/CD deploy (replaces stretch goal)
         │
Module 11 (wrap-up) ─── always last
```

**GitLab dependency:** GitLab CE must be running on each host before Modules 6 and 10
(the GitOps workflow exercises). Run `make gitlab-up && make gitlab-setup` at T-2h.

**For a shorter session (2 hours):** Use Modules 0, 1, 2, 3, 4, 5, 6, 11
**For Ansible-only (3 hours):** Use Modules 0-6, 9, 10, 11
**For Terraform-only (3 hours):** Use Modules 0-4, 7, 8, 9, 10, 11
