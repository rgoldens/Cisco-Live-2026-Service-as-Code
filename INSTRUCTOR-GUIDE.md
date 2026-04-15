# LTRATO-1001 Instructor Guide

## Lab Overview

**Session:** LTRATO-1001 — Automating Service Provider Networks with Ansible
**Audience:** Beginner to intermediate (automation focus, not routing theory)
**Platform:** ContainerLab on dCloud (one instance per student)
**Duration:** ~30 min for pre-lab setup; students have ~2.5 hours for Ansible tasks

### What Students Will Learn

- How Ansible inventory and playbooks work
- Using platform-specific modules (nxos, ios, iosxr)
- Variables, loops, conditionals, and idempotency
- Multi-vendor orchestration in a single workflow
- Verification and testing as part of automation

### Topology Summary

```
           ┌─────────┐         ┌─────────┐
           │  xrd01  │─────────│  xrd02  │       SP Core (IS-IS + MPLS)
           │ AS65000 │ Gi0/0/0 │ AS65000 │       Pre-configured via startup-config
           └────┬────┘         └────┬────┘
                │ Gi0/0/0/1         │ Gi0/0/0/1
                │                   │
           ┌────┴────┐         ┌────┴────┐
           │ csr-pe01│         │ csr-pe02│       PE Routers (IOS-XE)
           │ AS65001 │         │ AS65001 │       IPs configured by lab-setup.yml
           └────┬────┘         └────┬────┘
                │ Gi4                │ Gi4
                │                   │
           ┌────┴────┐         ┌────┴────┐
           │n9k-ce01 │         │n9k-ce02 │       CE Switches (NX-OS)
           │         │         │         │       IPs configured by lab-setup.yml
           └──┬───┬──┘         └──┬───┬──┘
           E1/3  E1/4           E1/3  E1/4
            │     │              │     │
         ┌──┴─┐ ┌─┴──┐       ┌──┴─┐ ┌─┴──┐
         │ C1 │ │ C2 │       │ C3 │ │ C4 │    Linux Clients
         └────┘ └────┘       └────┘ └────┘    IPs configured by lab-setup.yml
```

**10 nodes total:** 2 XRd (IOS-XR), 2 CSR1000v (IOS-XE), 2 N9Kv (NX-OS), 4 Linux containers

---

## How the Lab Works (Big Picture)

Understanding the full flow helps you troubleshoot if anything goes sideways.

### What the instructor does (before students arrive)

1. **Access each dCloud instance** and SSH in
2. **Clone the GitHub repo** — all lab files come from here
3. **Generate SSH keys** — Ansible needs them to authenticate to the lab devices
4. **Deploy the ContainerLab topology** — spins up all 10 nodes
5. **Wait for nodes to boot** — vrnetlab nodes (CSR, N9K) take 12-15 minutes
6. **Run `lab-setup.yml`** — injects SSH keys, configures baseline IPs, verifies connectivity
7. **Verify** — confirm all 10 nodes respond

### What the student does (when they sit down)

1. Open VS Code and SSH Remote into their dCloud server
2. Clone the lab repo into their home directory
3. Verify Ansible connectivity (`ansible all -m ping`)
4. **Task 1:** Open `ce-access-vlan.yml`, fill in VLAN variables from the lab guide tables, run it (~30 min)
5. **Task 2:** Open `igp-pe-ce.yml`, derive IS-IS NET addresses, fill in all vars, run it (~45 min)
6. **Task 3:** Open `inter-as-option-a.yml`, fill in BGP/VRF/peering vars, run it (~60 min)
7. Idempotency check — re-run a playbook to see `ok` vs `changed` (~15 min buffer)

**The key difference from the non-interactive version:** Students must edit each
playbook's `vars:` section before running it. The TODO placeholders prevent
"just run it and watch" — they have to understand the topology and reference
the lab guide tables to fill in the correct values.

The students never touch the topology or run lab-setup.yml. From their perspective,
the network is already there with baseline IPs, and they're building on top of it.

---

## Pre-Lab Setup (Detailed Steps)

These are the exact steps to prepare each dCloud instance. **Do all of this
before students arrive.** If you're splitting instances with a co-presenter,
each person follows the same steps on their assigned instances.

### Step 1: Access the dCloud Instance

Each student has their own dCloud reservation with a dedicated server.

```bash
ssh cisco@<dcloud-server-ip>
# Password: C1sco12345
# Sudo password: C1sco12345
```

**Why:** Everything runs on this server — ContainerLab, Ansible, the lab devices.
Students will SSH into this same server via VS Code.

### Step 2: Generate SSH Keys (If They Don't Already Exist)

Check for existing keys first:

```bash
ls -la ~/.ssh/id_ed25519 ~/.ssh/id_rsa 2>/dev/null
```

If either key is missing, generate them:

```bash
# Ed25519 key (used for NX-OS and Linux containers)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q

# RSA key (used for XRd — IOS-XR does NOT support ed25519)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
```

**Why this matters:** Ansible uses SSH key authentication to connect to the lab
devices. Different platforms require different key types:

| Key | Used By | Why |
|-----|---------|-----|
| `~/.ssh/id_ed25519` | N9K switches, Linux containers | Modern, fast — these platforms support it |
| `~/.ssh/id_rsa` | XRd (IOS-XR) | XRd's SSH server does not support ed25519 |
| (none — password) | CSR (IOS-XE) | CSR 16.12 rejects paramiko's rsa-sha2 signatures, so we fall back to password auth |

If the keys don't exist, `lab-setup.yml` will have nothing to inject into the
Linux containers, and Ansible won't be able to authenticate to XRd or N9K.

### Step 3: Clone the GitHub Repo

The files need to be directly in `/home/cisco/` (not in a subdirectory) because
`ansible.cfg` uses an absolute inventory path. Use this pattern:

```bash
cd ~
git clone <REPO_URL> .lab-tmp
mv .lab-tmp/* .lab-tmp/.* . 2>/dev/null
rm -rf .lab-tmp
```

Verify:

```bash
ls ~/LTRATO-1001.clab.yml ~/inventory.yml ~/ansible.cfg ~/lab-setup.yml
```

> **TODO:** Replace `<REPO_URL>` with the actual GitHub repo URL once created.

**Why from a repo:** Every dCloud instance starts clean. We can't pre-stage files
on the servers. The repo is the single source of truth — instructors clone it to
deploy the topology, and students clone it later to run the playbooks.

### Step 4: Deploy the ContainerLab Topology

```bash
sudo clab deploy -t LTRATO-1001.clab.yml
```

**What this does:**
- Creates 10 containers: 2 XRd, 2 CSR1000v, 2 N9Kv, 4 Linux
- Wires them together per the topology (see diagram above)
- Loads XRd startup configs (IS-IS, MPLS, loopback IPs — fully pre-configured)
- Linux containers install OpenSSH and start SSHD via `exec` blocks
- Creates a management network (172.20.20.0/24) connecting all nodes

**Expected time:** Containers start in ~30 seconds, but vrnetlab nodes need time
to boot their virtual machine images inside the container:

| Node Type | Boot Time | How You Know It's Ready |
|-----------|-----------|------------------------|
| XRd | ~1-2 min | `docker ps` shows `Up` |
| Linux | Instant | `docker ps` shows `Up` |
| CSR1000v | ~10-12 min | `docker ps` shows `(healthy)` |
| N9Kv | ~12-15 min | `docker ps` shows `(healthy)` |

### Step 5: Wait for All Nodes to Be Healthy

This is the longest step. Monitor with:

```bash
watch -n 10 'sudo docker ps --format "table {{.Names}}\t{{.Status}}"'
```

**Do NOT proceed until every vrnetlab node shows `(healthy)`.** Running Ansible
against nodes that are still booting will fail with SSH timeouts.

**What "healthy" means:** vrnetlab runs a health check that repeatedly tries to
log into the virtual machine inside the container. Once login succeeds, it
marks the container healthy. For CSR1000v, this is IOS-XE completing its boot
sequence. For N9Kv, it's NX-OS finishing initialization.

**What to do while waiting:** This is a good time to set up additional instances.
You can deploy multiple instances in parallel since each one boots independently.

### Step 6: Run the Pre-Lab Setup Playbook

```bash
ansible-playbook lab-setup.yml
```

**What this does (in order):**

| Play | What It Configures | Why Students Need It |
|------|-------------------|---------------------|
| **Clear SSH host keys** | Removes stale entries from `~/.ssh/known_hosts` | Every fresh deploy generates new host keys. Stale entries from previous deploys cause "HOST IDENTIFICATION HAS CHANGED" errors. |
| **Inject SSH keys into Linux containers** | Copies the server's public keys into each Linux container's `/root/.ssh/authorized_keys` via `docker exec` | Linux containers start with no SSH keys. Without this, Ansible can't connect to the Linux clients. |
| **NX-OS hostnames + features** | Sets `hostname n9k-ce01/02`, enables `feature interface-vlan` | Makes output readable. `feature interface-vlan` must be enabled before students can create SVIs in Task 2. |
| **CSR PE IP addresses** | Configures Loopback0, Gi2 (toward XRd), Gi4 (toward N9K) | CSR boots with no IP config. Students need the PE-CE links addressed for their routing tasks. |
| **N9K CE IP addresses** | Configures Loopback0, Eth1/1 (toward CSR) | N9K boots with all ports in switchport mode. Eth1/1 needs an IP and `no switchport` to reach the CSR PE. Client ports (Eth1/3, Eth1/4) are left in their default switchport mode — students will create VLANs and assign them in Task 1. |
| **Linux client IPs** | Assigns IP addresses on eth1 (23.23.23.x west, 34.34.34.x east) | Clients need IPs so students can run ping tests after each task. |
| **Verify connectivity** | Runs a `show version` or `hostname` on every node | Confirms all 10 nodes are SSH-reachable from Ansible. If this play fails, something above went wrong. |

**Expected result:** 0 failures. If any tasks fail, the most likely cause is a
node that hasn't finished booting (go back to Step 5).

**About the SSH key injection:** The playbook reads the server's public keys
(`~/.ssh/id_ed25519.pub` and `~/.ssh/id_rsa.pub`) and injects them into the
Linux containers using `docker exec`. This approach is deliberate — we don't
use bind mounts because they create read-only files with wrong ownership that
can't be fixed inside the container. The `docker exec` method works cleanly
regardless of how the topology was deployed.

### Step 7: Final Verification

Quick spot-check that everything is ready:

```bash
# Can Ansible reach all 10 devices?
ansible all -m ping 2>/dev/null | grep -E 'SUCCESS|UNREACHABLE'

# Do Linux clients have IPs?
ansible linux -m raw -a "ip addr show eth1 | grep inet"
```

All 10 hosts should return `SUCCESS`. All 4 Linux clients should show their
assigned IP address.

**The lab is now ready for students.**

---

## What Students See When They Arrive

When a student sits down, they:

1. Open VS Code on their laptop
2. Use VS Code Remote-SSH to connect to their dCloud server
3. Open a terminal in VS Code
4. Clone the lab repo directly into their home directory:

```bash
cd ~
git clone <REPO_URL> .lab-tmp
mv .lab-tmp/* .lab-tmp/.* . 2>/dev/null
rm -rf .lab-tmp
```

5. Verify Ansible can reach the devices:

```bash
ansible all -m ping
```

6. Follow the lab guide (`LAB-GUIDE.md`) to work through Tasks 1, 2, and 3

**Students do NOT need to:**
- Deploy or manage ContainerLab
- Run `lab-setup.yml`
- Generate SSH keys (they use the same keys the instructor generated)
- Know anything about docker or container management

Everything below the Ansible layer is invisible to them.

---

## Student Task Sequence

Students edit and run these 3 playbooks in order. Each builds on the previous one.
**Playbooks ship with TODO placeholders** — students must fill in variable values
from the lab guide reference tables before running.

### Time Budget (2.5 hours)

| Section | Time | What Students Do |
|---------|------|-----------------|
| Intro + Setup | 15 min | Connect, clone, verify, read Ansible primer |
| Task 1: VLANs | 30 min | Fill in 4 values, run, verify, understand output |
| Task 2: IS-IS | 45 min | Derive NET addresses, fill in ~12 values, run, verify |
| Task 3: BGP/VPN | 60 min | Fill in ~16 values across 3 plays, run, verify |
| Buffer / Q&A | 15 min | Idempotency check, re-run, explore, questions |

### Task 1: L2 Access VLANs (`ce-access-vlan.yml`)

**Student edits:** Fill in VLAN IDs and names in the `vars:` section
**Then runs:** `ansible-playbook ce-access-vlan.yml`
**Success criteria:** client1 pings client2, client3 pings client4
**Playbook runtime:** ~2 minutes

### Task 2: IS-IS PE-CE Routing (`igp-pe-ce.yml`)

**Student edits:** Fill in IS-IS NET addresses, SVI IPs, VLAN IDs, and Linux client routes
**Then runs:** `ansible-playbook igp-pe-ce.yml`
**Success criteria:** All clients can ping their local CSR PE loopback
**Playbook runtime:** ~3 minutes

### Task 3: Inter-AS Option A (`inter-as-option-a.yml`)

**Student edits:** Fill in BGP peering IPs, VRF config references, and cross-site routes
**Then runs:** `ansible-playbook inter-as-option-a.yml`
**Success criteria:** client1 pings client3, client2 pings client4 (full east-west)
**Playbook runtime:** ~3 minutes + 60 second BGP convergence pause

### Solution Files

Complete, tested playbooks are in `solutions/`. Use these if:
- A student is stuck and needs to check their work
- You need to quickly demonstrate the expected output
- A student's playbook has a YAML syntax error and you need a working copy

```bash
# To use a solution file directly:
cp solutions/ce-access-vlan.yml ~/ce-access-vlan.yml
ansible-playbook ~/ce-access-vlan.yml
```

---

## Answer Key

### Task 1: ce-access-vlan.yml

```yaml
vlan_config:
  n9k-ce01:
    id: 23
    name: CLIENT-VLAN-23
  n9k-ce02:
    id: 34
    name: CLIENT-VLAN-34
```

### Task 2: igp-pe-ce.yml

**Play 1 (NX-OS):**
```yaml
isis_config:
  n9k-ce01:
    net: "49.0002.1921.6802.0021.00"
    vlan_id: 23
    svi_ip: "23.23.23.254/24"
  n9k-ce02:
    net: "49.0002.1921.6802.0022.00"
    vlan_id: 34
    svi_ip: "34.34.34.254/24"
```

**Play 2 (CSR):**
```yaml
isis_config:
  csr-pe01:
    net: "49.0002.1921.6801.0011.00"
  csr-pe02:
    net: "49.0002.1921.6801.0012.00"
```

**Play 3 (Linux):**
```yaml
route_config:
  linux-client1:
    gateway: 23.23.23.254
    routes:
      - 192.168.10.0/24
      - 10.2.0.0/30
  linux-client2:
    gateway: 23.23.23.254
    routes:
      - 192.168.10.0/24
      - 10.2.0.0/30
  linux-client3:
    gateway: 34.34.34.254
    routes:
      - 192.168.10.0/24
      - 10.2.0.4/30
  linux-client4:
    gateway: 34.34.34.254
    routes:
      - 192.168.10.0/24
      - 10.2.0.4/30
```

### Task 3: inter-as-option-a.yml

**Play 1 (XRd):**
```yaml
xrd_config:
  xrd01:
    remote_lo: 192.168.0.2
    gi1_ip: 10.1.0.5
    gi1_mask: 255.255.255.252
    csr_peer: 10.1.0.6
  xrd02:
    remote_lo: 192.168.0.1
    gi1_ip: 10.1.0.9
    gi1_mask: 255.255.255.252
    csr_peer: 10.1.0.10
```

**Play 2 (CSR):**
```yaml
bgp_config:
  csr-pe01:
    xrd_peer: 10.1.0.5
  csr-pe02:
    xrd_peer: 10.1.0.9
```

**Play 3 (Linux):**
```yaml
cross_routes:
  linux-client1:
    dest: 34.34.34.0/24
    gw: 23.23.23.254
  linux-client2:
    dest: 34.34.34.0/24
    gw: 23.23.23.254
  linux-client3:
    dest: 23.23.23.0/24
    gw: 34.34.34.254
  linux-client4:
    dest: 23.23.23.0/24
    gw: 34.34.34.254
```

---

## Known Issues and Troubleshooting

### 1. SSH Host Key Errors After Redeploy

**Symptom:** `REMOTE HOST IDENTIFICATION HAS CHANGED` errors
**Cause:** Every `clab destroy` + `clab deploy` cycle generates new SSH host keys.
The old keys cached in `~/.ssh/known_hosts` no longer match.
**Fix:** `lab-setup.yml` Play 0 handles this automatically. If running manually:

```bash
for ip in 172.20.20.{10,11,20,21,30,31,40,41,42,43}; do
  ssh-keygen -f ~/.ssh/known_hosts -R $ip 2>/dev/null
done
```

### 2. Linux Client SSH "Permission Denied"

**Symptom:** Ansible can't connect to Linux clients (`publickey denied`)
**Cause:** SSH public keys haven't been injected into the container, or
the `authorized_keys` file has wrong ownership/permissions.
**Fix:** `lab-setup.yml` handles this via `docker exec`. If you need to
re-inject manually:

```bash
KEYS=$(cat ~/.ssh/id_ed25519.pub 2>/dev/null; cat ~/.ssh/id_rsa.pub 2>/dev/null)
for c in linux-client1 linux-client2 linux-client3 linux-client4; do
  docker exec clab-LTRATO-1001-$c sh -c "
    mkdir -p /root/.ssh && chmod 700 /root/.ssh &&
    echo '$KEYS' > /root/.ssh/authorized_keys &&
    chmod 600 /root/.ssh/authorized_keys
  "
done
```

**Why `docker exec` instead of bind mounts:** Bind-mounted files in containers
end up read-only with wrong ownership (the host user's UID, not root). You can't
`chmod` or `chown` them from inside the container. We learned this the hard way.
The `docker exec` approach writes directly into the container filesystem with
correct permissions every time.

### 3. CSR1000v SSH Hangs

**Symptom:** Ansible tasks on CSR hosts hang or timeout after config push
**Cause:** CSR1000v (16.12.05) running inside a container has a relatively heavy
control plane. When you push config, it may restart internal processes,
recalculate routing, or rebuild interfaces. During these moments, the SSH server
becomes unresponsive — sometimes long enough for Ansible to timeout.

Contributing factors:
- Control plane CPU spikes during config apply
- SSH rate-limiting when connections open/close quickly
- `save_when: always` triggering slow write-mem (we use `modified` instead)

**Mitigations already in the playbooks:**
- `wait_for` tasks after CSR config pushes (5-second delay, 60-second timeout)
- `save_when: modified` instead of `save_when: always`
- Paramiko SSH with password-only auth (no pubkey — CSR rejects rsa-sha2 signatures)

**If it happens during the lab:**
1. Wait 60 seconds, then retry the playbook (all playbooks are idempotent)
2. Check CSR is reachable: `ssh admin@172.20.20.20` (password: `admin`)
3. If SSH is completely dead, restart the container:
   ```bash
   sudo docker restart clab-LTRATO-1001-csr-pe01
   # Wait ~5 minutes for CSR to reboot, then re-run the playbook
   ```

### 4. N9Kv Port Mode Transition Breaks vrnetlab Dataplane

**Symptom:** After changing an N9K port from routed (`no switchport`) to L2
(`switchport`) mode, the port stops forwarding traffic entirely. MAC table is
empty, ARP gets no response, pings fail with "Destination Host Unreachable."
Port bounce (shut/no-shut) does NOT fix it — only a full container restart does.

**Root cause:** vrnetlab maps container veth interfaces to the virtual NIC
inside the N9Kv VM. When NX-OS transitions a port from routed to switchport
mode, the vrnetlab virtual NIC mapping doesn't properly reinitialize. The port
looks correct in NX-OS output (`show vlan brief` shows the port in the VLAN),
but no frames are forwarded.

**How we avoid this:** `lab-setup.yml` does NOT put client-facing ports (Eth1/3,
Eth1/4) into routed mode. They stay in their N9K default switchport mode from
the moment the topology is deployed. `ce-access-vlan.yml` then simply creates
VLANs and assigns ports — no mode transition, no breakage.

**CRITICAL: Do NOT add `no switchport` to Eth1/3 or Eth1/4 in lab-setup.yml.**
This was the original design and it caused consistent L2 failures that couldn't
be fixed without restarting the N9K containers (12-15 min reboot each time).

**If someone accidentally triggers this:**
```bash
# Only fix is a full container restart
sudo docker restart clab-LTRATO-1001-n9k-ce01 clab-LTRATO-1001-n9k-ce02
# Wait ~12-15 min for healthy, then re-run lab-setup.yml and ce-access-vlan.yml
```

### 5. Linux Client SSHD Doesn't Survive Server Reboots

**Symptom:** After a server reboot, Ansible can't SSH into Linux clients
(`Connection refused` or `publickey denied`), even though `docker ps` shows
the containers are running.

**Cause:** ContainerLab `exec` blocks in the topology file only run once —
at initial deploy. They install OpenSSH and start SSHD inside each Linux
container. When the server reboots, the containers restart but the `exec`
blocks don't re-run, so SSHD is gone and SSH keys are lost.

**Fix:** Re-run `lab-setup.yml`. Play 1 re-injects SSH keys into the Linux
containers via `docker exec`, which also restarts SSHD. This is by design —
`lab-setup.yml` is idempotent and safe to re-run at any time.

```bash
ansible-playbook lab-setup.yml
```

**If you only need to fix the Linux clients** (everything else is fine):
```bash
for c in linux-client1 linux-client2 linux-client3 linux-client4; do
  docker exec clab-LTRATO-1001-$c sh -c "
    apk add --no-cache openssh-server &&
    ssh-keygen -A &&
    mkdir -p /root/.ssh && chmod 700 /root/.ssh &&
    echo '$(cat ~/.ssh/id_ed25519.pub 2>/dev/null; cat ~/.ssh/id_rsa.pub 2>/dev/null)' > /root/.ssh/authorized_keys &&
    chmod 600 /root/.ssh/authorized_keys &&
    /usr/sbin/sshd
  "
done
```

### 6. IOS-XR `iosxr_command` Workaround

**Symptom:** If you try using `cisco.iosxr.iosxr_config` on XRd 25.4.1,
tasks fail with errors about `show commit changes diff` being an
unrecognized command.

**Cause:** The `cisco.iosxr` collection v12.1.1 uses `show commit changes diff`
to detect configuration changes, but XRd 25.4.1 doesn't support that command.
The `iosxr_config` module is effectively broken for this platform version.

**Workaround (already in the playbooks):** Task 3 uses `iosxr_command` with
raw CLI commands instead of `iosxr_config`. Each configuration block is sent
as a list of commands including `configure terminal` and `commit`. This
bypasses the broken diff detection entirely.

**Trade-off:** `iosxr_command` always reports `changed` even when the config
is already applied (it can't detect idempotency). This is why the XRd tasks
show `changed` on every run — it's cosmetic, not a real issue.

### 7. IOS-XR "Incomplete Command" Errors

**Symptom:** Task 3 iosxr_config tasks fail with "Incomplete command"
**Cause:** IOS-XR has deeply nested config hierarchies (e.g.,
`router bgp → vrf → neighbor → address-family`). Each nesting level must be a
separate Ansible task with explicit `parents` lists. Trying to put everything
in one task results in "Incomplete command" because Ansible sends lines in the
wrong context.
**Fix:** Already handled in the playbook design. Each nesting level is a
separate task. If adding new IOS-XR config, follow the same pattern.

---

## Destroying and Rebuilding the Lab

If you need to reset a student's environment to a clean state (or if something
goes badly wrong):

```bash
# 1. Destroy the topology
sudo clab destroy -t LTRATO-1001.clab.yml --cleanup

# 2. Redeploy
sudo clab deploy -t LTRATO-1001.clab.yml

# 3. Wait for healthy (~15 min)
watch -n 10 'sudo docker ps --format "table {{.Names}}\t{{.Status}}"'

# 4. Re-run setup
ansible-playbook lab-setup.yml

# 5. Verify
ansible all -m ping
```

**After a server reboot:** ContainerLab containers are stopped. Just redeploy:

```bash
sudo clab deploy -t LTRATO-1001.clab.yml
# Wait for healthy, then run lab-setup.yml
```

**Important:** After `clab destroy`, the containers and their configurations are
gone. `lab-setup.yml` recreates everything from scratch — that's the whole point.
You do NOT need to manually configure anything between destroy and setup.

---

## File Inventory

### What's in the GitHub Repo

| File | Purpose | Who Uses It |
|------|---------|-------------|
| `LTRATO-1001.clab.yml` | ContainerLab topology definition | Instructor (deploy) |
| `lab-setup.yml` | Pre-lab baseline configuration | Instructor (before students arrive) |
| `xrd01-startup.cfg` | XRd01 startup config (IS-IS, MPLS, interfaces) | ContainerLab (loaded at deploy) |
| `xrd02-startup.cfg` | XRd02 startup config (IS-IS, MPLS, interfaces) | ContainerLab (loaded at deploy) |
| `inventory.yml` | Ansible inventory — all 10 nodes, grouped by platform | Students + Instructor |
| `ansible.cfg` | Ansible settings (paramiko, host key handling) | Students + Instructor |
| `ce-access-vlan.yml` | Task 1: L2 VLANs on NX-OS | Students |
| `igp-pe-ce.yml` | Task 2: IS-IS PE-CE routing | Students |
| `inter-as-option-a.yml` | Task 3: Inter-AS Option A | Students |
| `LAB-GUIDE.md` | Student-facing lab guide | Students |
| `INSTRUCTOR-GUIDE.md` | This file | Instructors only |
| `solutions/ce-access-vlan.yml` | Task 1 answer key (complete, tested) | Instructor / stuck students |
| `solutions/igp-pe-ce.yml` | Task 2 answer key (complete, tested) | Instructor / stuck students |
| `solutions/inter-as-option-a.yml` | Task 3 answer key (complete, tested) | Instructor / stuck students |

---

## Credentials

| Device | Username | Password | Auth Method | Notes |
|--------|----------|----------|-------------|-------|
| dCloud Server | cisco | C1sco12345 | SSH key + password | Sudo password: C1sco12345 |
| XRd (IOS-XR) | clab | — | SSH key (`~/.ssh/id_rsa`) | Ed25519 not supported |
| CSR (IOS-XE) | admin | admin | Password only (paramiko) | Pubkey causes hard disconnect |
| N9K (NX-OS) | admin | — | SSH key (`~/.ssh/id_ed25519`) | Requires legacy KEX algorithms |
| Linux clients | root | root | SSH key (`~/.ssh/id_ed25519`) | Alpine containers |

---

## Quick Reference — Full Setup Checklist

Print this out or have it on a second screen.

```
□  SSH into the dCloud server
□  Verify SSH keys exist (id_ed25519 + id_rsa), generate if missing
□  git clone <REPO_URL> .lab-tmp && mv .lab-tmp/* .lab-tmp/.* . 2>/dev/null && rm -rf .lab-tmp
□  sudo clab deploy -t LTRATO-1001.clab.yml
□  Wait for all vrnetlab nodes to show (healthy) — ~15 min
□  ansible-playbook lab-setup.yml  →  expect 0 failures
□  ansible all -m ping  →  all 10 hosts SUCCESS
□  Lab is ready for students
```
