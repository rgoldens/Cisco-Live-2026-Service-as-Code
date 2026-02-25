# =============================================================================
# INSTRUCTOR PRE-SESSION CHECKLIST
# Service as Code Lab — Cisco Live 2026
#
# 30 attendees | 4 hours | Individual lab instances
# =============================================================================

---

## T-48 Hours — Infrastructure Readiness

### Host provisioning (30 instances)

- [ ] 30 Linux host VMs provisioned (Ubuntu 22.04+ or RHEL 9+ recommended)
- [ ] Each host has a public IP or jump host path documented
- [ ] SSH credentials tested for all 30 hosts (instructor can reach every one)
- [ ] Each host meets minimum resource requirements:
  - **CPU:** 16 vCPUs (2x XRd + 2x CSR @ 1 vCPU + 2x N9Kv @ 2 vCPU + GitLab @ 4 vCPU + headroom)
  - **RAM:** 32 GB minimum (2x XRd @ 2 GB + 2x CSR @ 3 GB + 2x N9Kv @ 6 GB + GitLab CE @ 8 GB + OS)
  - **Disk:** 60 GB free (images + container storage + GitLab data)

### Software installation (all 30 hosts)

Run on every host or via batch script (e.g., Ansible against the hosts themselves):

```bash
# Docker
docker --version
# Expected: Docker version 24.x+ or 26.x+

# containerlab
containerlab version
# Expected: 0.55+ (check https://containerlab.dev/install/ for latest)

# Python 3.10+
python3 --version

# Terraform 1.5+
terraform --version
```

- [ ] Docker installed and running (`systemctl status docker`)
- [ ] containerlab installed (latest stable)
- [ ] Python 3.10+ available
- [ ] Terraform 1.5+ installed
- [ ] `pip` and `python3-venv` available

### Kernel tuning (all 30 hosts)

```bash
# Required for XRd — apply and persist
sudo sysctl -w fs.inotify.max_user_instances=64000
sudo sysctl -w fs.inotify.max_user_watches=64000

# Persist across reboots
echo -e "fs.inotify.max_user_instances=64000\nfs.inotify.max_user_watches=64000" \
  | sudo tee -a /etc/sysctl.conf

# Verify
sysctl fs.inotify.max_user_instances
sysctl fs.inotify.max_user_watches
```

- [ ] `fs.inotify.max_user_instances` = 64000
- [ ] `fs.inotify.max_user_watches` = 64000
- [ ] Settings persisted in `/etc/sysctl.conf`

### Lab repo and images (all 30 hosts)

```bash
# Clone or copy the lab repo to a consistent path
ls ~/sac-lab/
# Expected: ansible/  configs/  Makefile  requirements.txt  services/  terraform/  topology/

# Verify all Docker images are loaded
docker images | grep -E "xrd|csr|n9kv|alpine"
```

- [ ] Lab repo cloned to `~/sac-lab/` on every host
- [ ] Image: `ios-xr/xrd-control-plane:25.1.1` loaded
- [ ] Image: `vrnetlab/cisco_csr1000v:<tag>` loaded (update tag in `topology/sac-lab.yml`)
- [ ] Image: `vrnetlab/cisco_n9kv:<tag>` loaded (update tag in `topology/sac-lab.yml`)
- [ ] Image: `alpine:latest` pulled (`docker pull alpine:latest`)
- [ ] Image tags in `topology/sac-lab.yml` match the actual loaded image names on all hosts

### Pre-pull GitLab images (all 30 hosts)

```bash
# Pull GitLab CE and Runner images ahead of time to avoid session-day delays
docker pull gitlab/gitlab-ce:latest
docker pull gitlab/gitlab-runner:latest
```

- [ ] Image: `gitlab/gitlab-ce:latest` pulled on all hosts
- [ ] Image: `gitlab/gitlab-runner:latest` pulled on all hosts

### Pre-install dependencies (all 30 hosts)

```bash
cd ~/sac-lab

# Python deps
pip install -r requirements.txt

# Ansible Galaxy collections
make ansible-install

# Terraform providers (caches .terraform/ directory)
make tf-init
```

- [ ] `pip install -r requirements.txt` completes without errors
- [ ] `make ansible-install` completes (cisco.ios, cisco.iosxr, cisco.nxos, ansible.netcommon, ansible.utils)
- [ ] `make tf-init` completes (CiscoDevNet/iosxe, CiscoDevNet/iosxr providers cached)

### Pre-start GitLab CE (all 30 hosts)

GitLab CE takes 3-5 minutes to fully initialize on first boot. Pre-starting it at
T-48h lets you verify it works and ensures the database is already initialized by
session day.

```bash
cd ~/sac-lab

# Start GitLab containers
make gitlab-up

# Wait 3-5 minutes, then verify health
docker inspect --format='{{.State.Health.Status}}' gitlab-ce
# Expected: healthy

# Run the full bootstrap (creates users, project, runner, CI)
make gitlab-setup
# Expected: "GitLab setup complete!" at the end

# Verify student can access GitLab
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/
# Expected: 200 or 302
```

- [ ] `make gitlab-up` starts GitLab CE and Runner containers without errors
- [ ] GitLab CE reaches "healthy" status within 5 minutes
- [ ] `make gitlab-setup` completes all 10 steps successfully
- [ ] GitLab web UI accessible at `http://<host-ip>:8080`

### Student access

- [ ] Student lab assignment sheet created (maps each attendee name → host IP/hostname)
- [ ] Student SSH key or password distributed (or VPN instructions if applicable)
- [ ] Student lab guide document distributed (PDF, printed, or URL)

---

## T-24 Hours — Full Smoke Test (Single Instance)

Pick one representative host and run through the entire session workflow end to end.

### Deploy and verify underlay

```bash
cd ~/sac-lab

# Deploy
make deploy

# Wait 8-10 minutes for all nodes to fully boot, then:
make inspect
```

- [ ] `make deploy` completes without errors
- [ ] `make inspect` shows all 7 nodes with status "running" and assigned management IPs

Record actual management IPs here for reference:

```
xrd01:        172.20.20.___
xrd02:        172.20.20.___
csr-pe01:     172.20.20.___
csr-pe02:     172.20.20.___
n9k-ce01:     172.20.20.___
n9k-ce02:     172.20.20.___
linux-client: 172.20.20.___
```

### SSH access to all node types

```bash
# XRd (credentials: clab / clab@123)
ssh clab@<xrd01-ip>
# Run: show isis neighbors
# Expected: 2 IS-IS adjacencies (xrd02 + csr-pe01)

# CSR PE (credentials: admin / admin)
ssh admin@<csr-pe01-ip>
# Run: show isis neighbors
# Run: show mpls ldp neighbor
# Run: show bgp vpnv4 unicast all summary
# Expected: IS-IS adj to xrd01 + csr-pe02, LDP neighbors, BGP neighbors to 10.0.0.1 and 10.0.0.2

# N9Kv CE (credentials: admin / admin)
ssh admin@<n9k-ce01-ip>
# Run: show ip ospf neighbors
# Expected: OSPF adjacency to n9k-ce02 on Eth1/2
```

- [ ] SSH to xrd01 succeeds — IS-IS adjacencies confirmed
- [ ] SSH to csr-pe01 succeeds — IS-IS + LDP + BGP VPNv4 confirmed
- [ ] SSH to n9k-ce01 succeeds — OSPF underlay confirmed

### Test Ansible path

```bash
# Update inventory with actual IPs
vi ansible/inventory/hosts.yml

# Provision L3VPN
make provision-l3vpn
# Expected: all tasks OK, no failures

# Validate
make validate
# Expected: BGP VPNv4 assertions pass, VRF routes present
```

- [ ] `make provision-l3vpn` — all tasks OK
- [ ] `make validate` — all assertions pass
- [ ] Re-run `make provision-l3vpn` — idempotent (no changes)

### Test Terraform path

```bash
make tf-plan
# Expected: plan shows VRF + BGP resources to create

make tf-apply
# Expected: apply completes, resources created
```

- [ ] `make tf-plan` shows expected resources
- [ ] `make tf-apply` completes without errors

### Record boot times

Note these so you know how long to wait on session day:

```
XRd (xrd01, xrd02):           ___ minutes from 'deploy' to SSH-ready
CSR1000v (csr-pe01, csr-pe02): ___ minutes from 'deploy' to SSH-ready
N9Kv (n9k-ce01, n9k-ce02):    ___ minutes from 'deploy' to SSH-ready
Alpine (linux-client):         ___ seconds (near instant)
```

### Clean and re-test

```bash
make destroy
# Wait 30 seconds
make deploy
# Wait for full boot, then:
make inspect
```

- [ ] Destroy + redeploy cycle works cleanly
- [ ] All adjacencies re-form after fresh deploy

### Smoke-test GitLab + CI/CD pipeline

On the same representative host, test the full GitOps workflow end to end:

```bash
# 1. Verify GitLab is healthy
docker inspect --format='{{.State.Health.Status}}' gitlab-ce
# Expected: healthy

# 2. Log in as student via web UI
# Open http://<host-ip>:8080 in a browser
# Login: student / CiscoLive2026!
# Navigate to: sac-lab project

# 3. Clone the repo as student
cd /tmp
git clone http://localhost:8080/student/sac-lab.git sac-lab-test
cd sac-lab-test

# 4. Create a branch, make a change, push
git checkout -b test-pipeline
echo "# test" >> services/l3vpn/vars/customer_a.yml
git add -A && git commit -m "test pipeline trigger"
git push -u origin test-pipeline

# 5. Create a Merge Request via API
curl -s --header "PRIVATE-TOKEN: $(cat ~/.gitlab-student-pat)" \
  "http://localhost:8080/api/v4/projects/1/merge_requests" \
  --data "source_branch=test-pipeline&target_branch=main&title=Test Pipeline"

# 6. Merge the MR via API
MR_IID=$(curl -s --header "PRIVATE-TOKEN: $(cat ~/.gitlab-student-pat)" \
  "http://localhost:8080/api/v4/projects/1/merge_requests?state=opened" | python3 -c "import sys,json;print(json.load(sys.stdin)[0]['iid'])")
curl -s --header "PRIVATE-TOKEN: $(cat ~/.gitlab-student-pat)" \
  -X PUT "http://localhost:8080/api/v4/projects/1/merge_requests/$MR_IID/merge"

# 7. Check pipeline triggered
sleep 5
curl -s --header "PRIVATE-TOKEN: $(cat ~/.gitlab-student-pat)" \
  "http://localhost:8080/api/v4/projects/1/pipelines" | python3 -m json.tool | head -20
# Expected: at least one pipeline with status "running" or "success"

# 8. Clean up test
cd ~ && rm -rf /tmp/sac-lab-test
```

- [ ] GitLab healthy and web UI accessible
- [ ] Student login works (student / CiscoLive2026!)
- [ ] Git clone via HTTP on port 8080 works
- [ ] Push to branch succeeds
- [ ] Merge Request creation works
- [ ] Pipeline triggers automatically on merge to main
- [ ] Pipeline runs validate + deploy stages (deploy may fail if topology is down — that's OK for this test)

---

## T-2 Hours — Day-of Setup (All 30 Instances)

### Deploy all labs

Deploy labs across all 30 hosts. If hosts share storage/network, stagger by 2-3 minutes
to avoid I/O contention. Use a batch script or parallel SSH tool:

```bash
# Example with parallel-ssh (pssh) or Ansible:
# ansible all -i lab-hosts.ini -m shell -a "cd ~/sac-lab && make deploy"
#
# Or loop with staggered starts:
# for host in $(cat hosts.txt); do
#   ssh $host "cd ~/sac-lab && make deploy" &
#   sleep 120  # 2 min stagger
# done
```

- [ ] `make deploy` initiated on all 30 hosts
- [ ] Stagger applied if hosts share infrastructure

### Start GitLab on all hosts

If GitLab was stopped after the T-48h smoke test, restart it now:

```bash
# On each host (or via batch script):
cd ~/sac-lab && make gitlab-up

# If setup-gitlab.sh was NOT run at T-48h, run it now:
cd ~/sac-lab && make gitlab-setup

# Or use the batch script:
./scripts/deploy-all.sh setup-gitlab
```

- [ ] GitLab CE container running and healthy on all 30 hosts
- [ ] GitLab Runner registered and active on all 30 hosts
- [ ] Student user and project exist on all 30 hosts

### Wait for full boot

**Minimum wait: 10 minutes after the LAST deploy command completes.**

Node boot time reference:
- XRd: ~2 min
- CSR1000v: ~6 min
- N9Kv: ~5-8 min (can vary with n9kv-lite vs full image)
- Alpine: instant

### Verify all instances (batch sweep)

Run a verification sweep across all 30 hosts. Example script:

```bash
#!/bin/bash
# verify-all.sh — run from instructor machine
HOSTS="hosts.txt"  # one IP per line

echo "=== Checking all lab instances ==="
while read -r host; do
  echo "--- $host ---"

  # Check all 7 containers running
  count=$(ssh "$host" "docker ps --filter label=lab=sac-lab -q | wc -l" 2>/dev/null)
  if [ "$count" -eq 7 ]; then
    echo "  PASS: 7/7 containers running"
  else
    echo "  FAIL: only $count/7 containers running"
  fi

  # Check xrd01 IS-IS (quick test)
  isis=$(ssh "$host" "docker exec clab-sac-lab-xrd01 /pkg/bin/xr_cli.sh 'show isis neighbors' 2>/dev/null | grep -c UP")
  if [ "$isis" -ge 1 ]; then
    echo "  PASS: xrd01 IS-IS adjacencies UP"
  else
    echo "  WARN: xrd01 IS-IS not yet up (may still be booting)"
  fi

done < "$HOSTS"
```

- [ ] All 30 instances show 7/7 containers running
- [ ] Spot-check 3-5 random instances: SSH to xrd01, csr-pe01, n9k-ce01 — all responsive

### Update inventory on each host

```bash
# On each host, update ansible/inventory/hosts.yml with actual IPs:
# Either manually, or script it:
cd ~/sac-lab
IPS=$(sudo containerlab inspect -t topology/sac-lab.yml --format json \
  | python3 -c "import sys,json; [print(n['name'],n['ipv4_address'].split('/')[0]) for n in json.load(sys.stdin)['containers']]")
echo "$IPS"
# Then update hosts.yml accordingly
```

- [ ] `ansible/inventory/hosts.yml` updated on all 30 hosts with correct management IPs

### Verify student access

- [ ] Have 2-3 students (or co-presenters) test SSH from their laptops to their assigned host
- [ ] Verify they can reach the lab host AND SSH through to a device (e.g., xrd01)

### Instructor environment

- [ ] Instructor's own lab instance is up and verified
- [ ] Screen sharing / projector tested — terminal font size large enough for back row
- [ ] Terminal tabs pre-opened: one for `make` commands, one for SSH to a device, one for editing YAML
- [ ] Topology diagram displayed (printout on tables or slide on second screen)

---

## T-30 Minutes — Final Pre-Flight

### Quick sanity checks (instructor instance only)

```bash
cd ~/sac-lab

# 1. All containers running?
docker ps --filter label=lab=sac-lab --format "table {{.Names}}\t{{.Status}}"
# Expected: all 7 show "Up X minutes"

# 2. IS-IS on xrd01
docker exec clab-sac-lab-xrd01 /pkg/bin/xr_cli.sh "show isis neighbors"
# Expected: 2 adjacencies (xrd02 via Gi0/0/0/0, csr-pe01 via Gi0/0/0/1)

# 3. LDP on csr-pe01
ssh admin@<csr-pe01-ip> "show mpls ldp neighbor"
# Expected: LDP neighbors to xrd01 and csr-pe02

# 4. BGP VPNv4 on csr-pe01
ssh admin@<csr-pe01-ip> "show bgp vpnv4 unicast all summary"
# Expected: neighbors 10.0.0.1 and 10.0.0.2 in Established state

# 5. NX-OS reachable
ssh admin@<n9k-ce01-ip> "show version | head 5"
# Expected: NX-OS version banner
```

- [ ] 7/7 containers up on instructor instance
- [ ] IS-IS adjacencies confirmed on xrd01
- [ ] LDP neighbors confirmed on csr-pe01
- [ ] BGP VPNv4 neighbors Established on csr-pe01
- [ ] N9Kv responsive to SSH

### Verify GitLab on instructor instance

```bash
# 1. GitLab healthy?
docker inspect --format='{{.State.Health.Status}}' gitlab-ce
# Expected: healthy

# 2. Runner connected?
docker exec gitlab-runner gitlab-runner list 2>&1 | head -5
# Expected: shows registered runner

# 3. Web UI accessible?
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/
# Expected: 200 or 302

# 4. Student can log in?
curl -s -o /dev/null -w "%{http_code}" \
  -d "grant_type=password&username=student&password=CiscoLive2026!" \
  http://localhost:8080/oauth/token
# Expected: 200
```

- [ ] GitLab CE healthy on instructor instance
- [ ] GitLab Runner registered and listed
- [ ] Web UI accessible at http://localhost:8080
- [ ] Student login credentials work

### Fallback readiness

- [ ] One spare pre-deployed host available (can be re-assigned if a student instance fails)
- [ ] Spare host IP and credentials documented
- [ ] Know how to do a quick `make redeploy` if a student instance is broken (takes ~10 min)

### Materials at the ready

- [ ] Student lab guide (printed or URL shared)
- [ ] Topology diagram + addressing plan visible (slide, handout, or whiteboard)
- [ ] This checklist printed for reference during session

---

## Quick Reference Card

### Credentials

| Device Type | Username | Password | SSH Port |
|-------------|----------|----------|----------|
| XRd (IOS-XR) | `clab` | `clab@123` | 22 |
| CSR1000v (IOS-XE) | `admin` | `admin` | 22 |
| N9Kv (NX-OS) | `admin` | `admin` | 22 |
| Linux client | `root` | *(none)* | docker exec |
| GitLab CE (root) | `root` | `SaCLab2026!` | HTTP :8080 |
| GitLab CE (student) | `student` | `CiscoLive2026!` | HTTP :8080 |
| GitLab SSH | — | — | SSH :2222 |

### Management Network

| Node | Expected IP Range |
|------|-------------------|
| All nodes | `172.20.20.0/24` (assigned by containerlab) |

Run `make inspect` to get exact IPs after deploy.

### Loopback Addresses

| Node | Loopback0 |
|------|-----------|
| xrd01 | 10.0.0.1/32 |
| xrd02 | 10.0.0.2/32 |
| csr-pe01 | 10.0.0.11/32 |
| csr-pe02 | 10.0.0.12/32 |
| n9k-ce01 | 10.0.0.21/32 |
| n9k-ce02 | 10.0.0.22/32 |

### Point-to-Point Links

| Link | Subnet | Endpoint A | Endpoint B |
|------|--------|------------|------------|
| P-P core | 10.0.0.0/30 | xrd01 .1 | xrd02 .2 |
| P-PE west | 10.0.1.0/30 | xrd01 .1 | csr-pe01 .2 |
| P-PE east | 10.0.1.4/30 | xrd02 .5 | csr-pe02 .6 |
| Inter-PE | 10.0.2.0/30 | csr-pe01 .1 | csr-pe02 .2 |
| PE-CE west | 10.0.3.0/30 | csr-pe01 .1 | n9k-ce01 .2 |
| PE-CE east | 10.0.3.4/30 | csr-pe02 .5 | n9k-ce02 .6 |
| DC inter-switch | 10.0.4.0/30 | n9k-ce01 .1 | n9k-ce02 .2 |
| Client subnet | 192.168.100.0/24 | n9k-ce01 .1 | linux-client .10 |

### Make Targets

```
make deploy          — Deploy containerlab topology
make destroy         — Destroy containerlab topology
make redeploy        — Destroy + redeploy (clean state)
make inspect         — Show running nodes and management IPs
make pip-install     — Install Python dependencies
make ansible-install — Install Ansible Galaxy collections
make provision-l3vpn — Deploy L3VPN via Ansible
make provision-evpn  — Deploy EVPN/VXLAN via Ansible
make validate        — Run post-deploy validation
make tf-init         — Initialize Terraform
make tf-plan         — Plan Terraform changes
make tf-apply        — Apply Terraform changes
make tf-destroy      — Destroy Terraform resources
make gitlab-up       — Start GitLab CE + Runner containers
make gitlab-setup    — Bootstrap GitLab (users, project, runner, CI)
make gitlab-down     — Stop and remove GitLab containers
make gitlab-purge    — Stop, remove, and delete GitLab data volumes
make clean           — Remove state files and clab artifacts
```

### Node Boot Time Estimates

| Node Type | Kind | Time to SSH-Ready |
|-----------|------|-------------------|
| XRd | `cisco_xrd` | ~2 min |
| CSR1000v | `cisco_csr1000v` | ~6 min |
| N9Kv | `cisco_n9kv` | ~5-8 min |
| Alpine Linux | `linux` | ~5 sec |
| GitLab CE | `docker` | ~3-5 min (first boot) |
| GitLab Runner | `docker` | ~10 sec |

**Total time from `make deploy` to all-nodes-ready: ~8-10 minutes**

---

## Known Failure Modes & Mitigations

### 1. N9Kv not fully booted

**Symptom:** SSH to n9k-ce01 hangs or is refused
**Diagnose:**
```bash
docker logs -f clab-sac-lab-n9k-ce01
# Watch for "System ready" message
```
**Fix:** Wait an additional 3-5 minutes. N9Kv is the slowest node. If it never reaches
"System ready" after 15 min, check RAM allocation (`QEMU_MEMORY` in `sac-lab.yml`).

### 2. XRd inotify errors

**Symptom:** XRd container exits or shows inotify errors in `docker logs`
**Diagnose:**
```bash
docker logs clab-sac-lab-xrd01 2>&1 | grep -i inotify
sysctl fs.inotify.max_user_instances
```
**Fix:**
```bash
sudo sysctl -w fs.inotify.max_user_instances=64000
sudo sysctl -w fs.inotify.max_user_watches=64000
make redeploy
```

### 3. CSR1000v not responding to SSH

**Symptom:** Container shows "running" in `docker ps` but SSH is refused
**Diagnose:**
```bash
docker logs -f clab-sac-lab-csr-pe01
# Watch for "Press RETURN to get started" or QEMU boot messages
```
**Fix:** CSR requires ~6 min after container start to be SSH-ready. This is normal.
If still not ready after 10 min, restart the container:
```bash
docker restart clab-sac-lab-csr-pe01
# Wait another 6 min
```

### 4. IS-IS adjacencies not forming

**Symptom:** `show isis neighbors` is empty on xrd01 or csr-pe01
**Diagnose:**
```bash
# Check startup config was applied
# On XRd:
docker exec clab-sac-lab-xrd01 /pkg/bin/xr_cli.sh "show run router isis"
# On CSR:
ssh admin@<csr-pe01> "show run | section router isis"
```
**Fix:** If config is missing, startup-config may not have been loaded. Redeploy:
```bash
make destroy
make deploy
```

### 5. Ansible collection install fails (no internet)

**Symptom:** `make ansible-install` fails with download errors
**Fix:** Pre-cache collections during T-48 setup. Alternatively, bundle them:
```bash
# On a machine with internet:
ansible-galaxy collection download -r ansible/requirements.yml -p ./collections-cache/
# Copy collections-cache/ to all lab hosts, then:
ansible-galaxy collection install -r ansible/requirements.yml -p ~/.ansible/collections --offline
```

### 6. Terraform provider download fails (no internet)

**Symptom:** `make tf-init` fails with registry errors
**Fix:** Pre-run `make tf-init` during T-48 setup so the `.terraform/` directory
is already cached. It will not re-download if the cache exists.

### 7. Student cannot reach their lab host

**Symptom:** SSH timeout from student laptop
**Diagnose:** Verify VPN connection (if applicable), check firewall rules, try from instructor machine
**Fix:**
- Re-assign student to the spare host
- If systemic (multiple students), check network/firewall with event networking team

### 8. Management IP mismatch in Ansible inventory

**Symptom:** Ansible playbook fails with "unreachable" errors
**Diagnose:**
```bash
make inspect
# Compare IPs with ansible/inventory/hosts.yml
```
**Fix:** Update `ansible_host` values in `ansible/inventory/hosts.yml` to match
`make inspect` output. Alternatively, use the containerlab-generated inventory:
```bash
ansible-playbook -i clab-sac-lab/ansible-inventory.yml ansible/playbooks/deploy_l3vpn.yml
```

### 9. GitLab CE not booting / stuck unhealthy

**Symptom:** `docker inspect --format='{{.State.Health.Status}}' gitlab-ce` shows "starting" or "unhealthy" for >5 minutes
**Diagnose:**
```bash
docker logs --tail 50 gitlab-ce
# Look for: "FATAL" messages, OOM errors, or port conflicts
docker stats gitlab-ce --no-stream
# Check memory usage — GitLab CE needs ~4 GB RAM
```
**Fix:**
```bash
# If OOM: check host has 32 GB total RAM and nothing else is consuming it
free -h

# If port conflict (8080 or 2222 already in use):
ss -tlnp | grep -E '8080|2222'
# Stop the conflicting service or change ports in gitlab/docker-compose.yml

# Nuclear option — full restart:
make gitlab-purge
make gitlab-up
# Wait 3-5 minutes, then:
make gitlab-setup
```

### 10. GitLab Runner not registering

**Symptom:** Pipeline stays "pending" forever; runner list is empty
**Diagnose:**
```bash
docker exec gitlab-runner gitlab-runner list 2>&1
# Expected: at least one runner listed

docker logs --tail 30 gitlab-runner
# Look for: "ERROR: Registering runner... failed" or connection errors
```
**Fix:**
```bash
# Runner may have failed to register if GitLab wasn't fully ready
# Re-run the setup script (it handles runner registration):
make gitlab-setup

# If that fails, manually register:
docker exec gitlab-runner gitlab-runner register \
  --non-interactive \
  --url http://gitlab-ce:8080 \
  --token "$(docker exec gitlab-ce gitlab-rails runner "puts Ci::Runner.first.token" 2>/dev/null)" \
  --executor shell \
  --description "sac-lab-runner"
```

### 11. CI/CD pipeline fails

**Symptom:** Pipeline shows "failed" in GitLab UI
**Diagnose:**
- Click on the failed job in GitLab UI to see logs
- Common causes:
  - `ansible-playbook: command not found` → Python deps not installed on runner
  - `unreachable` errors → containerlab topology not running or inventory IPs wrong
  - YAML validation errors → malformed service definition file
**Fix:**
```bash
# If ansible not found on runner:
pip install -r ~/sac-lab/requirements.txt

# If inventory IPs wrong:
cd ~/sac-lab && make inspect
# Update ansible/inventory/hosts.yml with correct IPs, commit, push

# If YAML validation error: fix the YAML file and push again
```

### 12. Student can't push to GitLab

**Symptom:** `git push` fails with "remote: HTTP Basic: Access denied" or 403
**Diagnose:**
```bash
# Check git credentials are configured:
git config credential.helper
cat ~/.git-credentials 2>/dev/null | grep -c 8080
```
**Fix:**
```bash
# Re-configure git credentials for GitLab:
git config --global credential.helper store
echo "http://student:CiscoLive2026!@localhost:8080" > ~/.git-credentials
```

---

## During-Session Emergency Procedures

### Student lab instance completely broken

1. Try `make redeploy` on the student host (~10 min to recover)
2. If that fails, reassign student to the spare host
3. Pair the student with a neighbor while waiting if applicable

### Instructor demo instance broken mid-session

1. Switch to a second pre-prepared terminal session on a backup host
2. If no backup: `make redeploy` and fill time with Q&A or whiteboard discussion
3. Recovery time: ~10 min

### Multiple instances failing simultaneously

1. Likely a host infrastructure issue (shared storage, network)
2. Switch session to instructor-led demo mode (audience watches your screen)
3. Continue with the presentation content; students attempt lab exercises after recovery
4. Extend Module 9 (Open Lab) at the end to compensate

---

## Post-Session Cleanup

```bash
# On all 30 hosts:
cd ~/sac-lab

# Tear down GitLab (remove containers + data)
make gitlab-purge

# Destroy containerlab topology
make destroy
make clean

# Optionally remove images to reclaim disk:
docker rmi ios-xr/xrd-control-plane:25.1.1
docker rmi vrnetlab/cisco_csr1000v:<tag>
docker rmi vrnetlab/cisco_n9kv:<tag>
docker rmi gitlab/gitlab-ce:latest
docker rmi gitlab/gitlab-runner:latest
```

Or use the batch script:

```bash
./scripts/deploy-all.sh teardown-gitlab   # Remove GitLab on all hosts
./scripts/deploy-all.sh destroy           # Destroy containerlab on all hosts
```

- [ ] GitLab torn down on all 30 hosts (containers + volumes removed)
- [ ] All 30 labs destroyed
- [ ] Terraform state and clab artifacts cleaned
- [ ] VMs deprovisioned (if applicable)
- [ ] Student access revoked
