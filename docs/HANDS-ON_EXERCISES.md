# Hands-On Exercises — Service as Code Lab

## Overview

**8 sequential exercises** designed to take you from topology deployment through infrastructure as code principles.

| Exercise | Title | Time | Difficulty | What You Learn |
|----------|-------|------|-----------|----------------|
| **1** | Explore & Understand Deployed Topology | 15 min | ⭐ Easy | Topology structure, device roles, IP plan |
| **2** | Provision CustomerA L3VPN | 30 min | ⭐⭐ Medium | Ansible, YAML, service definitions |
| **3** | Provision CustomerB L3VPN | 25 min | ⭐⭐ Medium | Repeating patterns, multiple services |
| **4** | End-to-End Validation | 20 min | ⭐ Easy | Ping tests, traceroute, BGP verification |
| **5** | Terraform State Management | 25 min | ⭐⭐ Medium | IaC state files, desired vs. actual |
| **6** | Drift Detection & Remediation | 30 min | ⭐⭐⭐ Hard | Make unauthorized changes, detect drift, fix automatically |
| **7** | Configuration Modification & Re-apply | 20 min | ⭐⭐ Medium | Change Terraform vars, apply, see results |
| **8** | GitOps Workflow & Source of Truth | 30 min | ⭐⭐ Medium | Git-driven orchestration, Ansible sync, drift prevention |

**Total:** 210 minutes core + 30 minutes buffer = 240 minutes (4 hours)

---

## Lab Readiness Verification ⏱️ 15 minutes

**START HERE.** Before attempting any exercises, verify that your lab environment is ready and all devices are reachable. The topology is already deployed on dCloud — this section confirms you can reach it from your local environment.

### Objective
- Verify the containerlab topology is running on dCloud
- Confirm all 10 nodes are reachable
- Learn to use VS Code containerlab extension to visualize the topology
- Test SSH connectivity to representative devices
- Validate the 172.20.20.0/24 management network

### Prerequisites
- VS Code installed on your workstation
- VS Code containerlab extension installed (see INSTALL_GUIDE.md)
- SSH client installed (should be default on Linux/macOS, Windows 11+ includes OpenSSH)
- Network access to dCloud lab server
- Lab repository cloned: `~/Cisco-Live-2026-Service-as-Code/`

---

### Step 1: Verify Topology is Running on dCloud

From your local terminal (or dCloud shell), check containerlab status:

```bash
# If SSHed into dCloud server
ssh <dcloud-lab-server>

# Once connected to dCloud, verify containerlab is running
sudo containerlab inspect --all
```

Expected output (all 10 nodes should show `running`):
```
+-----------+-----------+------+------+------+--------------------+
| Container ID  | Name            | State     | Labs |
|───────────────|────────────────────|─────────────|──────|
| abc123def456  | xrd01           | running   |  ✓  |
| def456ghi789  | xrd02           | running   |  ✓  |
| ghi789jkl012  | csr-pe01        | running   |  ✓  |
| jkl012mno345  | csr-pe02        | running   |  ✓  |
| mno345pqr678  | n9k-ce01        | running   |  ✓  |
| pqr678stu901  | n9k-ce02        | running   |  ✓  |
| stu901vwx234  | linux-client1   | running   |  ✓  |
| vwx234yza567  | linux-client2   | running   |  ✓  |
| yza567bcd890  | linux-client3   | running   |  ✓  |
| bcd890efg123  | linux-client4   | running   |  ✓  |
+-----------+-----------+------+------+------+--------------------+
```

**If all show `running`, proceed. Otherwise, contact your instructor.**

---

### Step 2: Open VS Code and Install Containerlab Extension

1. **Open VS Code** on your local workstation
2. **Click Extensions** (Ctrl+Shift+X on Linux/Windows, Cmd+Shift+X on macOS)
3. **Search for "containerlab"** in the marketplace
4. **Find the extension by Karim Radhouani** (`karimra.containerlab`)
5. **Click Install** if not already installed
6. **Wait for installation to complete**

---

### Step 3: Open the Lab Topology in VS Code Extension

1. **Click the Containerlab icon** in the left sidebar (looks like a tree/network diagram)
2. **A "Containerlab" panel opens** on the left side
3. **You should see your dCloud lab listed** (if connected to the same network)
4. **Click on your lab to expand it** — you'll see all 10 nodes listed as a tree:

```
🏢 Cisco Live 2026 Lab
├── 🔷 xrd01 (172.20.20.10)
├── 🔷 xrd02 (172.20.20.11)
├── 🟢 csr-pe01 (172.20.20.20)
├── 🟢 csr-pe02 (172.20.20.21)
├── 🟠 n9k-ce01 (172.20.20.30)
├── 🟠 n9k-ce02 (172.20.20.31)
├── 🐧 linux-client1 (172.20.20.40)
├── 🐧 linux-client2 (172.20.20.41)
├── 🐧 linux-client3 (172.20.20.42)
└── 🐧 linux-client4 (172.20.20.43)
```

**Colors indicate device type:**
- 🔷 Blue = IOS-XR
- 🟢 Green = IOS-XE
- 🟠 Orange = NX-OS
- 🐧 Linux = Alpine/Linux

---

### Step 4: View Topology Graph (Optional)

1. **In the Containerlab panel, look for "Topology" or graph view button**
2. **Click to see a visual diagram of node connections**
3. **This shows link topology: PE-to-PE, PE-to-CE, CE-to-Linux connections**
4. **This is the physical/logical layout of your lab**

---

### Step 5: Test SSH to XRd (Route Reflector #1)

**From VS Code Terminal (Ctrl+`) or local terminal:**

```bash
ssh clab@172.20.20.10
```

When prompted:
- **Username:** `clab` (default)
- **Password:** `clab@123` (default)

Expected output:
```
Welcome to XRd (version 25.4.1)

xrd01#
```

**Commands to try:**
```bash
xrd01# show version
xrd01# exit
```

---

### Step 6: Test SSH to CSR-PE (Provisioning Target)

```bash
ssh admin@172.20.20.20
```

When prompted:
- **Username:** `admin`
- **Password:** `admin` (default)

Expected output:
```
csr-pe01#
```

**Commands to try:**
```bash
csr-pe01# show version brief
csr-pe01# exit
```

---

### Step 7: Test SSH to Linux Client

```bash
ssh root@172.20.20.40
```

When prompted:
- **Username:** `root`
- **Password:** `clab` (Alpine default)

Expected output:
```
/ # 
```

**Commands to try:**
```bash
/ # hostname
linux-client1
/ # exit
```

---

### Step 8: Quick Reachability Check (All 10 Devices)

Run this bash loop to verify all devices are reachable:

```bash
#!/bin/bash
for i in 10 11 20 21 30 31 40 41 42 43; do
  timeout 2 ping -c 1 172.20.20.$i > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "✓ 172.20.20.$i is reachable"
  else
    echo "✗ 172.20.20.$i is NOT reachable"
  fi
done
```

Expected output:
```
✓ 172.20.20.10 is reachable
✓ 172.20.20.11 is reachable
✓ 172.20.20.20 is reachable
✓ 172.20.20.21 is reachable
✓ 172.20.20.30 is reachable
✓ 172.20.20.31 is reachable
✓ 172.20.20.40 is reachable
✓ 172.20.20.41 is reachable
✓ 172.20.20.42 is reachable
✓ 172.20.20.43 is reachable
```

**If all show ✓, your lab is ready. If any show ✗, troubleshoot (see below).**

---

### Step 9: Verify Management Network

Confirm you're on the correct subnet:

```bash
ip -4 addr show | grep "172.20"
```

Expected: You should see an IP in the `172.20.20.0/24` range (or via DHCP/docker bridge).

If this is remote dCloud access, this is less critical — the important thing is that you can ping all 10 addresses above.

---

### Success Criteria ✅

Before proceeding to Exercise 1, verify ALL of these:

- [ ] **Containerlab status**: `sudo containerlab inspect --all` shows all 10 nodes `running`
- [ ] **VS Code extension**: Containerlab extension is installed and shows topology in sidebar
- [ ] **SSH to XRd**: `ssh clab@172.20.20.10` connects and shows XRd prompt
- [ ] **SSH to CSR-PE**: `ssh admin@172.20.20.20` connects and shows CSR prompt
- [ ] **SSH to Linux**: `ssh root@172.20.20.40` connects and shows `/` prompt
- [ ] **Ping all 10 IPs**: All 172.20.20.{10,11,20,21,30,31,40,41,42,43} respond to ping
- [ ] **Understand device IPs**:
  - XRd: .10, .11
  - CSR-PE: .20, .21
  - N9Kv-CE: .30, .31
  - Linux-clients: .40, .41, .42, .43

**If all boxes are checked ✅, your lab is ready. Proceed to Exercise 1.**

---

### Troubleshooting

**Problem: "Connection refused" when SSH-ing to a device**

The container might still be booting (especially XRd, which takes 3-5 min):
```bash
# Wait 30 seconds
sleep 30

# Try again
ssh clab@172.20.20.10

# If still failing, check if container is actually running
sudo docker ps | grep xrd01
```

**Problem: "No route to host" when pinging**

Network connectivity issue — verify you can reach the dCloud lab server at all:
```bash
ping 172.20.20.1  # Try gateway or another known IP
ping 1.1.1.1      # Can you reach external internet?
```

If the problem is dCloud connectivity, contact your instructor.

**Problem: SSH hangs for 30+ seconds before connecting**

Normal for first SSH connection (device is still fully booting). Wait for the connection. Subsequent connections will be faster.

**Problem: Wrong credentials for a device (password rejected)**

Double-check:
- **XRd/IOS-XR**: Username `clab`, password `clab@123`
- **CSR/IOS-XE**: Username `admin`, password `admin`
- **N9Kv/NX-OS**: Username `admin`, password `admin`
- **Linux/Alpine**: Username `root`, password `clab`

These are set in the containerlab topology file (topology/sac-lab.yml).

**Problem: Containerlab extension doesn't show topology in VS Code**

1. Check the extension is actually installed: Ctrl+Shift+X → search "containerlab"
2. Reload VS Code: Ctrl+Shift+P → type "Reload Window"
3. If still not showing, it's possible the extension requires additional dependencies (rare)
4. Alternative: Use CLI commands only (`sudo containerlab inspect --all`)

---

## Exercise 1: Explore & Understand the Deployed Topology ⏱️ 15 minutes

### Objective
Understand the structure, components, and IP addressing scheme of the already-deployed 10-node lab topology. Learn what's running and how it's connected before you start provisioning services.

### Prerequisites
- Lab Readiness Verification completed (all 10 nodes reachable)
- Lab repository cloned: `~/Cisco-Live-2026-Service-as-Code/`
- Basic familiarity with network device types (XR, IOS-XE, NX-OS)

### What You'll Learn
- How to inspect a containerlab deployment with CLI tools
- The role of each device in the topology (Route Reflectors, PE routers, CE routers, test clients)
- YAML-as-code: How the topology is defined in `sac-lab.yml`
- IP addressing plan: management network and device IPs
- Device images and versions running

---

### Step 1.1: View the Topology YAML File

```bash
cat ~/Cisco-Live-2026-Service-as-Code/topology/sac-lab.yml
```

This file defines everything: node types, container images, management network settings, and inter-node links.

Key sections to notice:
- `nodedef`: Specifies device name, image, container environment
- `topology`: Defines all nodes (10 total)
- `links`: Defines connections between nodes (eth interfaces)
- `management`: Configures the management network (172.20.20.0/24)

---

### Step 1.2: Inspect All Running Nodes

```bash
sudo containerlab inspect --topo ~/Cisco-Live-2026-Service-as-Code/topology/sac-lab.yml
```

Output shows all 10 nodes with their:
- Container ID
- Name
- Status
- Image
- IPv4 Management Address
- IPv6 Address (if applicable)

Expected output (key columns):
```
+--------+------------------+-----------+----------------------------------------+------------------+
| Name   | Container ID     | Status    | Image                                  | Mgmt IPv4        |
+--------+------------------+-----------+----------------------------------------+------------------+
| xrd01  | abc1234567890def | running   | ghcr.io/nokia/srl:25.4.1-xrd          | 172.20.20.10     |
| xrd02  | def2345678901ghi | running   | ghcr.io/nokia/srl:25.4.1-xrd          | 172.20.20.11     |
| csr-pe01 | ghi3456789012jkl | running   | cisco/csr1000v:16.12.05               | 172.20.20.20     |
| csr-pe02 | jkl4567890123mno | running   | cisco/csr1000v:16.12.05               | 172.20.20.21     |
| n9k-ce01 | mno5678901234pqr | running   | cisco/n9kv:10.5.4.M                   | 172.20.20.30     |
| n9k-ce02 | pqr6789012345stu | running   | cisco/n9kv:10.5.4.M                   | 172.20.20.31     |
| linux-client1 | stu7890123456vwx | running | alpine:latest                          | 172.20.20.40     |
| linux-client2 | vwx8901234567yza | running | alpine:latest                          | 172.20.20.41     |
| linux-client3 | yza9012345678bcd | running | alpine:latest                          | 172.20.20.42     |
| linux-client4 | bcd0123456789efg | running | alpine:latest                          | 172.20.20.43     |
+--------+------------------+-----------+----------------------------------------+------------------+
```

✅ **Verify all 10 show `running` status.**

---

### Step 1.3: Understand Device Roles

Based on the topology, here's what each node does:

**Route Reflectors (IOS-XR XRd):**
- **xrd01** (172.20.20.10) — BGP RR #1, VPN route reflection
- **xrd02** (172.20.20.11) — BGP RR #2, redundancy

**PE Routers (IOS-XE CSR):**
- **csr-pe01** (172.20.20.20) — Provider Edge #1, L3VPN support, CustomerA/B home
- **csr-pe02** (172.20.20.21) — Provider Edge #2, L3VPN support, CustomerA/B redundancy

**CE Routers (NX-OS N9Kv):**
- **n9k-ce01** (172.20.20.30) — Customer Edge #1, gateway for clients (linux-client1/2)
- **n9k-ce02** (172.20.20.31) — Customer Edge #2, gateway for clients (linux-client3/4)

**Test Clients (Alpine Linux):**
- **linux-client1/2/3/4** (172.20.20.40-43) — Customer test endpoints, ping/traceroute sources

---

### Step 1.4: View Topology Connections

See which nodes are connected to which:

```bash
sudo containerlab graph --topo ~/Cisco-Live-2026-Service-as-Code/topology/sac-lab.yml
```

This displays a visual diagram (if supported by your terminal) or text representation of links.

**Expected topology structure:**
```
xrd01 ←→ csr-pe01 (BGP adjacency)
xrd02 ←→ csr-pe02 (BGP adjacency)
csr-pe01 ←→ csr-pe02 (inter-PE link)
csr-pe01 ←→ n9k-ce01 (PE-CE link, CustomerA traffic)
csr-pe02 ←→ n9k-ce02 (PE-CE link, CustomerA traffic)
n9k-ce01 ←→ linux-client1 & linux-client2 (access links)
n9k-ce02 ←→ linux-client3 & linux-client4 (access links)
```

---

### Step 1.5: Check Device Images & Versions

Verify which OS versions are running:

**XRd versions:**
```bash
ssh clab@172.20.20.10 "show version"
```
Expected: IOS-XR 25.4.1 or similar

**CSR versions:**
```bash
ssh admin@172.20.20.20 "show version | include Cisco IOS"
```
Expected: IOS-XE 16.12.05 or similar

**N9Kv versions:**
```bash
ssh admin@172.20.20.30 "show version | include version"
```
Expected: NX-OS 10.5.4.M or similar

---

### Step 1.6: Understand the IP Addressing Plan

All management IPs are on **172.20.20.0/24**:

```
IP Range          Device Type       Count  Assignment
──────────────────────────────────────────────────────
172.20.20.10-11   XRd (IOS-XR)       2     Route Reflectors
172.20.20.20-21   CSR (IOS-XE)       2     PE routers
172.20.20.30-31   N9Kv (NX-OS)       2     CE routers
172.20.20.40-43   Alpine Linux       4     Test clients
```

**Important:** These are **management IPs only** (SSH access). Data plane IPs (for L3VPN, BGP neighbors) are configured separately via Ansible in Exercises 2 & 3.

---

### Step 1.7: View Interface Mappings

Understand how containerlab interfaces map to device interface names:

**eth0** → Management interface (172.20.20.x)  
**eth1** → First data interface (maps to Gi0-0-0-0 on XRd, Gi1 on CSR, eth1 on Alpine)  
**eth2, eth3, eth4** → Additional data interfaces  

These mappings are important when you provision services (Exercises 2-3) because the YAML service definitions reference device interface names (like `GigabitEthernet3` on CSR), which map back to containerlab's `eth3`.

---

### Step 1.8: Quick Health Checks

Verify basic connectivity between backbone nodes:

**Ping from csr-pe01 to csr-pe02:**
```bash
ssh admin@172.20.20.20
csr-pe01# ping 172.20.20.21
# Should succeed
csr-pe01# exit
```

**Ping from csr-pe01 to n9k-ce01:**
```bash
ssh admin@172.20.20.20
csr-pe01# ping 172.20.20.30
# Should succeed
csr-pe01# exit
```

**Ping from linux-client1 to its CE router:**
```bash
ssh root@172.20.20.40
linux-client1# ping 172.20.20.30  # Points to n9k-ce01
# Should succeed
linux-client1# exit
```

✅ **If pings succeed between these key pairs, the topology is healthy.**

---

### Success Criteria ✅

- [ ] All 10 nodes show `running` status in `containerlab inspect`
- [ ] You understand device roles (RR, PE, CE, Linux clients)
- [ ] You can view the topology YAML and understand its structure
- [ ] You understand the IP addressing plan (172.20.20.0/24)
- [ ] You know which interface names map to which eth ports
- [ ] Pings between PE1 ↔ PE2, PE1 ↔ CE1, Client1 ↔ CE1 all succeed
- [ ] You understand that management IPs ≠ data plane IPs (configured later)

**If all boxes are checked ✅, you're ready for Exercise 2.**

---

### Troubleshooting

**Problem: "containerlab graph" doesn't display topology**

Graph visualization requires specific terminal features (rare). Just skip this step — the YAML file shows the same topology information.

**Problem: Ping between devices fails**

Check if the target device is still booting (XRd and N9Kv can take 5+ min):
```bash
# Retry after 30 seconds
sleep 30
ssh admin@172.20.20.20
csr-pe01# ping 172.20.20.30
```

If still failing, see Lab Readiness Verification troubleshooting section.

**Problem: SSH into a device shows "Connection refused" or "No route"**

The device is still booting. XRd and N9Kv take 3-5 minutes before fully responsive. Wait 2 minutes and retry.

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

## Exercise 8: GitOps Workflow & Source of Truth ⏱️ 30 minutes

### Objective
Understand GitOps principles: Git as single source of truth, drift detection, and automatic synchronization. Learn why this architecture matters in production networks and how it differs from Terraform-based approaches.

### Prerequisites
- Exercises 1-2 completed (CustomerA is provisioned and running on csr-pe01 and csr-pe02)
- Lab repository cloned with Git
- SSH access to csr-pe01 (172.20.20.20)
- `git` command line available

### What You'll Learn
- How to detect configuration drift (running config vs source of truth in Git)
- Why Git should be the single source of truth for infrastructure
- How Ansible enforces consistency and idempotency
- GitOps concepts you'll see in production (Argo CD, Gitlab CI, GitHub Actions, etc.)
- The difference between Git-driven vs Terraform-driven orchestration

---

### Step 1: Review Current State — Git vs Running Config (5 min)

**Step 1.1: View the source of truth in Git**

```bash
cat ~/Cisco-Live-2026-Service-as-Code/services/l3vpn/vars/customer_a.yml
```

Expected output (your source of truth):
```yaml
vrf_name: CUST_A
rd: "65000:100"
rt_import: "65000:100"
rt_export: "65000:100"
pe01_interface: GigabitEthernet3
pe01_ip: 192.168.100.1/24
pe02_interface: GigabitEthernet3
pe02_ip: 192.168.200.1/24
ce01_neighbor: 192.168.100.2
ce02_neighbor: 192.168.200.2
```

**This YAML file is your source of truth.** Everything you need to know about CustomerA is here.

**Step 1.2: View running configuration on the PE router**

```bash
ssh admin@172.20.20.20
csr-pe01# show run vrf CUST_A
```

Expected output (what's actually running):
```
vrf definition CUST_A
 rd 65000:100
 !
 address-family ipv4
  import map route-map IMPORT_MAP
  export map route-map EXPORT_MAP
  route-target import 65000:100
  route-target import 65000:100 stitching
  route-target export 65000:100
  route-target export 65000:100 stitching
 exit-address-family
!
```

**Compare:** The Git version (source of truth) ≈ Running version ✅

This match is because Ansible ran and synced them. This is **healthy state**.

```bash
csr-pe01# exit
```

---

### Step 2: Make a Change in Git (The Source of Truth) (5 min)

**Step 2.1: Edit the customer_a.yml file to add metadata**

```bash
cd ~/Cisco-Live-2026-Service-as-Code

# Open in nano or your favorite editor
nano services/l3vpn/vars/customer_a.yml
```

Add a description field after the vrf_name:

```yaml
vrf_name: CUST_A
description: "Customer A L3VPN - Finance Dept - Updated 2026-03-22"
rd: "65000:100"
rt_import: "65000:100"
...
```

Save and exit (Ctrl+X in nano, then Y).

Alternatively, use sed to add it:

```bash
sed -i '/^vrf_name: CUST_A/a description: "Customer A L3VPN - Finance Dept - Updated 2026-03-22"' \
  services/l3vpn/vars/customer_a.yml
```

Verify the change was made:

```bash
head -5 services/l3vpn/vars/customer_a.yml
```

Expected output:
```yaml
vrf_name: CUST_A
description: "Customer A L3VPN - Finance Dept - Updated 2026-03-22"
rd: "65000:100"
...
```

**Step 2.2: Commit this change to Git**

```bash
cd ~/Cisco-Live-2026-Service-as-Code

# Stage the change
git add services/l3vpn/vars/customer_a.yml

# Commit with a message
git commit -m "docs: add description field to CustomerA VRF configuration"

# Expected output:
# [main abc1234] docs: add description field to CustomerA VRF configuration
#  1 file changed, 1 insertion(+)
```

**Step 2.3: Push to GitHub**

```bash
git push origin main
```

Expected output:
```
Counting objects: 3, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 356 bytes | 0 bytes/s, done.
Total 3 (delta 1), reused 0 (delta 0)
remote: Running post-receive hook: update
To https://github.com/YOUR-ACCOUNT/Cisco-Live-2026-Service-as-Code.git
   abc1234..def5678  main -> main
```

✅ **Your change is now in GitHub. You've updated the source of truth.**

---

### Step 3: Detect Configuration Drift (5 min)

Now your **Git source of truth** (with description) is **different** from **actual running config** (still without description).

**Configuration Drift Detected:** Running config ≠ Git config ⚠️

**Step 3.1: Visualize the drift**

```bash
ssh admin@172.20.20.20
csr-pe01# show run vrf CUST_A | include description
# Output: (nothing — description is NOT in running config yet)

csr-pe01# exit
```

**What changed:**
- **Git:** Now has `description: "Customer A L3VPN - Finance Dept - Updated 2026-03-22"`
- **Device:** Still doesn't have description field

This is the problem GitOps solves: **How do you know when reality doesn't match your source of truth?**

**In production, this drift happens because:**
- Engineer SSH's to device during emergency, makes quick fix
- Fix works, crisis ends
- But Git wasn't updated
- Days later, someone runs automation and it reverts the fix (or overwrites it)
- Or worse: different engineers don't know what's configured where

---

### Step 4: Understand the Problem & GitOps Solution (2 min)

**Instructor discusses these key points:**

1. **The Problem Without GitOps:**
   - Config lives on devices (🔴 Bad)
   - Engineers SSH and make changes (🔴 Bad)
   - No audit trail (🔴 Bad)
   - Can't easily rollback (🔴 Bad)
   - Different people make conflicting changes (🔴 Bad)

2. **The Solution With GitOps:**
   - Config lives in Git (🟢 Good — version controlled)
   - All changes go through Git first (🟢 Good — audit trail)
   - Pull requests + reviews before deploy (🟢 Good — prevents mistakes)
   - Easy rollback: `git revert` (🟢 Good)
   - Automation keeps reality in sync (🟢 Good)

3. **How Major Companies Do It:**
   - **Netflix:** Every config change in Git, auto-deployed via CI/CD
   - **Google:** Infrastructure as Code in Git, Terraform/Ansible enforce state
   - **AWS:** CloudFormation/Terraform in Git, automated deployments
   - **GitHub Actions, Gitlab CI, ArgoCD:** All watch Git, auto-deploy on commit

4. **Career Context:**
   - "GitOps Engineer" = $140K-170K salary (US, 2026)
   - Companies specifically hire for "platform engineer" who understands this
   - You now understand the pattern

---

### Step 5: Enforce Consistency with Ansible (5 min)

**The goal:** Re-run Ansible to sync Git → Devices, fixing the drift.

**Step 5.1: Run Ansible playbook to re-apply L3VPN configuration**

```bash
cd ~/Cisco-Live-2026-Service-as-Code

ansible-playbook ansible/playbooks/deploy_l3vpn.yml
```

Expected output:
```
PLAY [ConfigureL3VPN] ****
TASK [Load customer variables] **
ok: [pe01]
TASK [Deploy L3VPN Configuration] **
changed: [csr-pe01]
changed: [csr-pe02]
...
PLAY RECAP **
csr-pe01: ok=X changed=1 unreachable=0 failed=0
csr-pe02: ok=X changed=1 unreachable=0 failed=0
```

The `changed` status means Ansible **detected the differences** and pushed the updated configuration from Git.

**Why idempotent?** If you run it again without changing Git:

```bash
ansible-playbook ansible/playbooks/deploy_l3vpn.yml
# Output: ok=X changed=0 (nothing to change — Git and devices are in sync)
```

This is what **GitOps** is: **Ansible compares desired state (Git) vs actual state (devices) and makes changes only if needed.**

---

### Step 6: Verify Drift is Resolved (3 min)

**Step 6.1: Check running config again**

```bash
ssh admin@172.20.20.20
csr-pe01# show run vrf CUST_A | include description
```

Expected output (the description is now visible):
```
description Customer A L3VPN - Finance Dept - Updated 2026-03-22
```

✅ **Running config now includes the description from Git. Drift is resolved.**

```bash
csr-pe01# exit
```

---

### Step 7: Compare with Terraform Approach (Contrast) (5 min)

**Instructor explains:**

**Two approaches to "source of truth":**

| Aspect | Git/Ansible (This Exercise) | Terraform (Exercises 5-7) |
|--------|--------------------------|-------------------------|
| **Where truth lives** | Git YAML files | Terraform state file |
| **How you define state** | Edit YAML, commit to Git | Edit .tf files, run terraform |
| **Drift detection** | Manual: run Ansible again | Automated: `terraform plan` shows diff |
| **Sync enforcement** | Ansible: compare & apply | Terraform: `terraform apply` |
| **Audit trail** | Git commit history (excellent) | Terraform state + Git history |
| **When to use** | Day-2 operations, config mgmt | Infrastructure provisioning |
| **Real-world** | Netflix, Gitlab CI pipelines | AWS, Azure, cloud infrastructure |

**Both live together in production:**
- **Terraform:** Creates infrastructure (VPCs, subnets, instances)
- **Ansible:** Configures infrastructure (sets BGP, VRFs, firewall rules)
- **Git:** Holds both Terraform AND Ansible code

You now understand **both paradigms**, which is exactly what production teams need.

---

### Step 8: Optional Extension — Simulate Bad Practice (5 min, if time)

**"What if someone changed config directly (bypassing Git)?"**

Demonstrate the problem:

```bash
ssh admin@172.20.20.20

# BAD PRACTICE: Config directly on device, not through Git
csr-pe01# config t
csr-pe01(config)# vrf definition CUST_A
csr-pe01(config-vrf)# no description
csr-pe01(config-vrf)# exit
csr-pe01(config)# exit
csr-pe01# write mem  # Save config
csr-pe01# exit
```

Now the device config **doesn't have description**, but Git **still does**.

**Ask students: "What should happen now?"**

**Answer: Run Ansible again — Git is king, it always wins.**

```bash
cd ~/Cisco-Live-2026-Service-as-Code
ansible-playbook ansible/playbooks/deploy_l3vpn.yml
# It will re-push the description because Git says it should be there
```

Check device again:
```bash
ssh admin@172.20.20.20
csr-pe01# show run vrf CUST_A | include description
# Output: description Customer A L3VPN - Finance Dept - Updated 2026-03-22
```

✅ **GitOps principle: Git always wins. Automation enforces consistency.**

---

### Success Criteria ✅

Before moving to Bonus exercises, verify ALL of these:

- [ ] You edited customer_a.yml in Git and committed/pushed the change
- [ ] You verified running config was different from Git (drift detected) ⚠️
- [ ] You ran `ansible-playbook` to re-sync configuration
- [ ] You verified running config now matches Git (drift resolved) ✅
- [ ] You understand that Git should be the single source of truth
- [ ] You understand that Ansible is the automation tool that enforces consistency
- [ ] You can explain why this matters (audit, rollback, visibility, career)
- [ ] You understand the contrast between Git/Ansible vs Terraform approaches

**If all boxes are checked ✅, you understand GitOps principles and are ready for Bonus exercises.**

---

### Troubleshooting

**Problem: Ansible playbook shows no changes (status: `ok` instead of `changed`)**

This is **good**, not bad! It means the config already matched. To see changes in action, edit customer_a.yml again and run Ansible again. Or, proceed to the optional extension above where you intentionally remove the description.

**Problem: Can't push to GitHub ("permission denied" error)**

Check your remote is correct:
```bash
git remote -v
# Should show your fork, e.g.: origin https://github.com/YOUR-ACCOUNT/repo.git
```

If it's pointing to the original repo and you don't have write access, update it:
```bash
git remote set-url origin https://github.com/YOUR-ACCOUNT/Cisco-Live-2026-Service-as-Code.git
git push origin main
```

If you don't have a fork or SSH keys set up, ask your instructor for help.

**Problem: Ansible fails to deploy after you push**

Verify SSH to the PE still works:
```bash
ssh admin@172.20.20.20
csr-pe01# exit
```

If SSH works, Ansible should work. If it fails, check:
- Are you in the right directory? `cd ~/Cisco-Live-2026-Service-as-Code`
- Do you have Ansible installed? `ansible --version`
- Is the playbook path correct? `ansible/playbooks/deploy_l3vpn.yml`

**Problem: "fatal: not a git repository" error**

Make sure you're in the lab repo directory:
```bash
cd ~/Cisco-Live-2026-Service-as-Code
git status
```

---

### Key Takeaway

**GitOps = Declarative infrastructure + Git as source of truth + Automation to enforce consistency**

1. You declare desired state in **Git** (YAML, Terraform, etc.)
2. You commit it (audit trail, review, rollback capability)
3. **Automation** (Ansible, Terraform, ArgoCD) compares desired vs. actual
4. Automation **enforces consistency** automatically
5. Git becomes the single source of truth — the pane of glass for your entire infrastructure

This is how Netflix, Google, AWS, and every modern tech company manages infrastructure at scale. You now understand this pattern and can apply it to any infrastructure problem.

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

