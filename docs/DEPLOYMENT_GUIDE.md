# Deployment Guide: LTRATO-1001 Topology

## Overview

This guide covers how to deploy the LTRATO-1001 topology on a lab server using Containerlab.

**Time required:** 15-20 minutes (plus ~10 minutes for container boot times)

## Prerequisites

- **Server:** Ubuntu 22.04+, RHEL 9+, or similar Linux OS
- **Hardware:** 16 CPU cores, 32 GB RAM, 60 GB free disk space
- **Docker:** Installed and running (`docker --version` returns 24.x+)
- **Containerlab:** Installed (`clab --version` returns 0.55+)
- **Device images:** XRd, CSR1000v, and N9Kv container images loaded into Docker

See [../INSTALL_GUIDE.md](../INSTALL_GUIDE.md) for detailed installation steps.

## Quick Deploy

### Step 1: Clone or Update the Repository

```bash
cd ~
git clone https://github.com/your-github/Cisco-Live-2026-Service-as-Code.git
cd Cisco-Live-2026-Service-as-Code
```

Or if already cloned, pull latest changes:
```bash
cd ~/Cisco-Live-2026-Service-as-Code
git pull origin main
```

### Step 2: Deploy the Topology

```bash
cd topology
sudo containerlab deploy --topo sac-lab.yml
```

**Expected output:**
```
INFO[0000] Containerlab v0.74.1 started
INFO[0001] Parsing & checking topology file: sac-lab.yml
INFO[0003] Creating docker network "clab"
INFO[0005] Created container xrd01
INFO[0006] Created container xrd02
INFO[0008] Created container csr-pe01
...
INFO[0060] All 10 nodes are ready
```

### Step 3: Verify the Deployment

List all containers and their status:
```bash
sudo containerlab inspect --all
```

Example output:
```
Name            Hostname    Container ID    Image           Lab Name    Status    Mgmt IPv4       
xrd01           xrd01       5c8e4a2b...     ios-xr/...      sac-lab     running   172.20.20.10    
xrd02           xrd02       7f9d2c1a...     ios-xr/...      sac-lab     running   172.20.20.11    
csr-pe01        csr-pe01    3e1f4a8b...     vrnetlab/...    sac-lab     running   172.20.20.20    
csr-pe02        csr-pe02    9a7c2e3d...     vrnetlab/...    sac-lab     running   172.20.20.21    
n9k-ce01        n9k-ce01    2b4f8e1c...     vrnetlab/...    sac-lab     running   172.20.20.30    
n9k-ce02        n9k-ce02    8d3e9a5f...     vrnetlab/...    sac-lab     running   172.20.20.31    
linux-client1   client1     4a6f1c2e...     multitool       sac-lab     running   172.20.20.40    
linux-client2   client2     5c8e2d3f...     multitool       sac-lab     running   172.20.20.41    
linux-client3   client3     7f9d4e5g...     multitool       sac-lab     running   172.20.20.42    
linux-client4   client4     8a1e5f6h...     multitool       sac-lab     running   172.20.20.43    
```

**All 10 nodes should show `running` status.** If any show `exited` or `created`, wait 1-2 minutes and check again.

### Step 4: Verify Connectivity

Test SSH to a device:
```bash
ssh clab@172.20.20.10
# or
ssh admin@172.20.20.20
```

You should get a password or key prompt. Ctrl-C to exit.

## Post-Deployment Setup

### Step 5: Update Ansible Inventory (If IPs Changed)

If the IPs don't match `172.20.20.10-43` range, update the inventory:

```bash
cd ~/Cisco-Live-2026-Service-as-Code
sudo containerlab inspect --all | grep -E "172.20.20" > /tmp/ips.txt
cat /tmp/ips.txt
```

Then manually edit `ansible/inventory/hosts.yml` to match the actual IPs.

Alternatively, regenerate from containerlab inventory:
```bash
cd ~/clab-sac-lab
cp ansible-inventory.yml ~/Cisco-Live-2026-Service-as-Code/ansible/inventory/hosts-auto.yml
```

### Step 6: Verify Device Readiness

Wait for NX-OS to boot (slowest device, ~3-5 minutes):

```bash
# Check NX-OS is fully booted
ssh admin@172.20.20.30
n9k-ce01# show version | head -1
Cisco Nexus Operating System (NX-OS) Software

# If you see "Cisco" in version output, NX-OS is ready
```

XRd and CSR are usually ready in 30-60 seconds. Linux clients are immediately ready.

## Stopping and Restarting

### Stop the Lab (Preserve Data)

```bash
cd ~/Cisco-Live-2026-Service-as-Code/topology
sudo containerlab destroy --topo sac-lab.yml
```

This stops all containers but preserves volumes (important for XRd persistent storage).

### Restart After Stop

```bash
sudo containerlab deploy --topo sac-lab.yml
```

### Full Reset (Erase All Data)

**Warning:** This deletes XRd persistent storage and all device configs.

```bash
cd ~/Cisco-Live-2026-Service-as-Code/topology
sudo containerlab destroy --topo sac-lab.yml --cleanup
```

Then redeploy.

## Troubleshooting

### Container Fails to Start

```bash
# Check logs
docker logs <container-name>

# Example: CSR won't boot
docker logs csr-pe01

# If qcow2 image is corrupted, rebuild via vrnetlab and reload
```

### Can't SSH to a Device

```bash
# Verify it's running
docker ps | grep <device-name>

# Check actual IP
sudo containerlab inspect | grep <device-name>

# Verify SSH is listening
docker exec -it <container-name> ss -tulpn | grep 22
```

### Network Links Not Working

```bash
# Verify links are created
docker network inspect clab

# Check interface status inside container
ssh clab@172.20.20.10
xrd01# show interfaces brief
```

### Out of Memory

If containers are killed or won't start:
```bash
# Free up space
docker system prune -a --volumes
```

Then redeploy.

## Power-User Tips

### Automate Deploy on Server Boot

To auto-deploy topology when server starts:

```bash
cd ~/Cisco-Live-2026-Service-as-Code/topology
cat > /etc/systemd/system/containerlab-sac.service << 'EOF'
[Unit]
Description=Containerlab SAC-Lab
After=docker.service
Wants=docker.service

[Service]
Type=oneshot
WorkingDirectory=/root/Cisco-Live-2026-Service-as-Code/topology
ExecStart=/usr/bin/sudo /usr/bin/clab deploy --topo sac-lab.yml
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable containerlab-sac
```

### Bulk Deploy Multiple Labs

For deploying to 30 student lab servers:

```bash
# See scripts/deploy-all.sh for batch operations
./scripts/deploy-all.sh deploy
./scripts/deploy-all.sh verify
```

### Monitor Resource Usage

```bash
# Watch Docker resource usage
docker stats

# Watch container boot progress
watch 'docker ps -a --format {{println .Status}}'
```

## Next Steps

Once deployed:
1. Read [TOPOLOGY_NOTES.md](./TOPOLOGY_NOTES.md) for node details and IP layout
2. Follow [LAB_GUIDE.md](./LAB_GUIDE.md) for the 4-hour session
3. Run Ansible provisioning: `make provision-l3vpn` (from repo root)
4. For drift detection exercise: [DRIFT_EXERCISE.md](./DRIFT_EXERCISE.md)

