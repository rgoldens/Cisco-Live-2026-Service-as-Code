# Pre-Lab Checklist: LTRATO-1001 Lab Readiness (INSTRUCTOR ONLY)

**Purpose:** Validate all infrastructure before students arrive. Students should NOT need to run these commands.

**Time:** 5 minutes (run once before class starts)

---

## Network Devices (6 nodes)

| Device | IP | User | Expected OS |
|--------|-----|------|------|
| xrd01 | 172.20.20.10 | clab | IOS XR |
| xrd02 | 172.20.20.11 | clab | IOS XR |
| csr-pe01 | 172.20.20.20 | admin | IOS XE |
| csr-pe02 | 172.20.20.21 | admin | IOS XE |
| n9k-ce01 | 172.20.20.30 | admin | NX-OS |
| n9k-ce02 | 172.20.20.31 | admin | NX-OS |

## Test Clients (4 nodes)

| Device | IP | User |
|--------|-----|------|
| linux-client1 | 172.20.20.40 | root |
| linux-client2 | 172.20.20.41 | root |
| linux-client3 | 172.20.20.42 | root |
| linux-client4 | 172.20.20.43 | root |

---

## Step 1: Verify Ansible Inventory

```bash
cd ~/lab-exercises
ls -la inventory/hosts.yml
```

**Expected output:** File exists and is readable

---

## Step 2: Test SSH Connectivity (with proper KEX options for legacy devices)

Test SSH directly to each device type. CSR devices require legacy SSH algorithms configured:

```bash
# Test CSR-PE01 (IOS XE)
ssh -o StrictHostKeyChecking=no -o HostKeyAlgorithms=ssh-rsa -o PubkeyAcceptedKeyTypes=ssh-rsa -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1 admin@172.20.20.20 "show version | include Cisco"

# Test N9K-CE01 (NX-OS)
ssh -o StrictHostKeyChecking=no admin@172.20.20.30 "show version | include NX-OS"

# Test XRd01 (IOS XR)
ssh -o StrictHostKeyChecking=no clab@172.20.20.10 "show version | utility tail -3"
```

**Expected:** All three commands succeed without errors.

---

## Step 3: Verify Ansible Can Reach All Devices

```bash
# Test N9K and XRd connectivity (use standard Ansible ping - they support modern SSH)
ansible nxos -m ping -i inventory/hosts.yml
ansible xrd -m ping -i inventory/hosts.yml

# Test CSR connectivity via raw module (CSR uses legacy KEX, handled by ansible.cfg)
ansible csr -m raw -a "show version" -i inventory/hosts.yml
```

**Expected output:**
- N9K: `SUCCESS` with ping response
- XRd: `SUCCESS` with ping response
- CSR: Shows version output (confirms SSH with KEX options works)

---

## Step 4: Test Linux Clients

```bash
# Test connectivity to all Linux clients
ansible clients -m raw -a "hostname" -i inventory/hosts.yml
```

**Expected output:**
```
linux-client1 | SUCCESS | rc=0 >> clab-LTRATO-1001-linux-client1
linux-client2 | SUCCESS | rc=0 >> clab-LTRATO-1001-linux-client2
linux-client3 | SUCCESS | rc=0 >> clab-LTRATO-1001-linux-client3
linux-client4 | SUCCESS | rc=0 >> clab-LTRATO-1001-linux-client4
```

---

## Step 5: Verify Group Variables Are Loaded

```bash
# Check that group_vars are being used
ansible-inventory -i inventory/hosts.yml --graph

# Expected output shows device groupings:
#  @all:
#    |--@network_devices:
#    |  |--xrd01
#    |  |--xrd02
#    |  |--csr-pe01
#    |  |--csr-pe02
#    |  |--n9k-ce01
#    |  |--n9k-ce02
#    |--@clients:
#    |  |--linux-client1
#    |  |--linux-client2
#    |  |--linux-client3
#    |  |--linux-client4
```

---

## ✅ Lab Ready Checklist

- [ ] Step 1: Inventory file exists
- [ ] Step 2: All 10 devices respond to ping
- [ ] Step 3: Group connectivity works
- [ ] Step 4: Device-specific commands work
- [ ] Step 5: ansible-inventory shows correct grouping

**If all checked:** Lab is ready to begin Task 1! 🚀

**If any fail:** Check the troubleshooting section below.

---

## Troubleshooting

### `ansible: command not found`
```bash
pip install ansible-core ansible
```

### `FAILED - name or service not known`
- Device IP is wrong in inventory
- DNS resolution issue
- Device is down
→ Check device IP: `ping 172.20.20.20`

### `FAILED - Permission denied (publickey)`
- SSH key not found or permissions wrong
- Verify key path in inventory matches actual key location
- Test manually: `ssh -i ~/.ssh/id_rsa admin@172.20.20.20`

### `FAILED - Timeout waiting for privilege escalation prompt`
- Device credentials wrong
- Device requires different authentication
- Test manually with exact credentials

### `UNREACHABLE - Invalid/incorrect password`
- Password in inventory doesn't match device
- Double-check inventory passwords vs. actual device passwords

---

## When Lab is Ready

Once all 10 devices respond to `ansible all -m ping`, you're ready to:
1. Start **Task 1: VLAN Configuration** (fill inventory with VLAN vars)
2. Continue to **Task 2: ISIS Configuration** (add isis process vars)
3. Complete **Task 3: BGP + ISIS Peering** (add bgp vars)

**Proceed to Task 1 README when ready.**
