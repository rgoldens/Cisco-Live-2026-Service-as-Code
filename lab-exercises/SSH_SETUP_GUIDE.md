# SSH Configuration Guide - What Students Need to Know

**Bottom Line:** Everything is pre-configured. Students don't need to do anything special, but should understand WHY the setup is designed this way.

---

## 🔐 The SSH Challenge

**Problem:** CSR routers use legacy SSH algorithms, but modern SSH clients (and Ansible libraries) advertise modern algorithms first and won't negotiate down.

**Algorithms:**
- CSR supports: `diffie-hellman-group14-sha1`, `diffie-hellman-group-exchange-sha1`
- Modern SSH clients advertise: mlkem, curve25519, ecdh-sha2, diffie-hellman-group14-sha256

Result: KEX (key exchange) negotiation fails without explicit algorithm restriction.

---

## ✅ What's Pre-Configured

### 1. **ansible.cfg** - SSH Connection Settings

```ini
[ssh_connection]
ssh_args = -o HostKeyAlgorithms=ssh-rsa -o PubkeyAcceptedKeyTypes=ssh-rsa \
           -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1
```

**What this does:** Tells Ansible SSH to use legacy algorithms for CSR connectivity.

**Coverage:** Works for N9K and XRd too (they accept these options even though they support modern algorithms).

### 2. **inventory/hosts.yml** - Device SSH Options

Each device group has `ansible_ssh_common_args` configured:

```yaml
csr:
  vars:
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o HostKeyAlgorithms=ssh-rsa..."
nxos:
  vars:
    ansible_ssh_common_args: "-o StrictHostKeyChecking=no -o HostKeyAlgorithms=ssh-rsa..."
```

**What this does:** Applies SSH options at the inventory level (redundant with ansible.cfg, but explicit).

### 3. **Task 2 CSR Playbook** - Direct SSH Workaround

The CSR playbook uses `shell` + direct SSH instead of Ansible's `network_cli` plugin:

```yaml
- name: "{{ inventory_hostname }} | Configure ISIS..."
  shell: |
    ssh {{ ssh_args }} admin@{{ ansible_host }} <<'EOF'
    configure terminal
    router isis CORE
    ...
    EOF
```

**Why:** Ansible's network_cli plugin (libssh/paramiko) has limitations with legacy algorithm negotiation. Direct SSH bypasses this.

**Result:** Identical configuration output, but using a different transport mechanism.

### 4. **N9K Playbook** - Standard Ansible

The N9K playbook uses standard Ansible network_cli:

```yaml
- name: "{{ inventory_hostname }} | Deploy ISIS..."
  cisco.nxos.nxos_config:
    lines: [...]
```

**Why:** N9K uses Ethernet interfaces and NX-OS commands that work fine with ansible.cfg SSH options. No workaround needed.

---

## 📋 Pre-Lab Checklist (Updated)

**New Step 2:** Tests SSH connectivity using proper KEX options

```bash
# Test CSR with legacy algorithms
ssh -o HostKeyAlgorithms=ssh-rsa -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1 \
    admin@172.20.20.20 "show version | include Cisco"

# Test N9K
ssh admin@172.20.20.30 "show version | include NX-OS"

# Test XRd
ssh clab@172.20.20.10 "show version | utility tail -3"
```

**Expected:** All 3 commands succeed without "kex error" messages.

**If CSR SSH fails:** Check that ansible.cfg KEX options are in place.

---

## 🎓 What Students Learn

**Task 1 & Task 2:**
- Standard Ansible network automation patterns
- Using playbooks for L2 and L3 configuration
- Variable-driven device configuration
- Validation via show commands

**Transparent to Students:**
- SSH KEX algorithm negotiation (handled by ansible.cfg)
- Difference between network_cli (N9K) and direct SSH (CSR)
- Why the playbooks look different

**Hidden Complexity:**
- Students run `ansible-playbook` and configuration deploys
- They don't need to understand the SSH workaround details
- If something "just works," that's a good lab experience

---

## 🔧 Troubleshooting for Instructors

### Students See: `kex error : no match for method kex algos`

**Cause:** ansible.cfg not being read or SSH options missing

**Fix:**
1. Verify `ansible.cfg` exists in `lab-exercises/` directory
2. Verify `[ssh_connection]` section is present
3. Check inventory `ansible_ssh_common_args` are set

### Students See: `Permission denied (publickey)`

**Cause:** Credentials wrong or SSH key issues

**Fix:**
1. Verify username: CSR = `admin`, N9K = `admin`, XRd = `clab`
2. Verify passwords in inventory match device credentials
3. Try manual SSH: `ssh admin@172.20.20.20`

### Students See: `Connection timeout`

**Cause:** Device unreachable or SSH port blocked

**Fix:**
1. Ping device: `ping 172.20.20.20`
2. Check device is powered on
3. Verify IP in inventory/hosts.yml

---

## ✅ What Students Don't See

✅ KEX errors — pre-configured in ansible.cfg  
✅ SSH library limitations — bypassed in CSR playbook  
✅ SSH option complexity — hidden in playbook vars  
✅ Legacy algorithm deprecation warnings — suppressed  

**Result:** Clean, professional lab experience focused on learning Ansible, not SSH debugging.

