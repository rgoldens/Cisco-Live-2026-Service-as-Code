← [Task 5](TASK5.md) | [Task 6](TASK6.md) | [Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md)

---

## What You've Accomplished

By completing all tasks, you've automated the configuration of a full
service provider network from the ground up — using two different tools
and three different protocols:

| Layer | What You Built | Devices Configured | Task |
|-------|---------------|-------------------|------|
| **L2 Switching** | VLANs, access ports | 2 NX-OS switches | Task 1 |
| **L3 Routing (IGP)** | IS-IS adjacencies, SVIs, static routes | 2 NX-OS + 2 IOS-XE + 4 Linux | Task 2 |
| **L3 VPN (BGP)** | VRFs, iBGP VPNv4, eBGP, redistribution | 2 IOS-XR + 2 IOS-XE + 4 Linux | Task 3 |
| **Terraform (gNMI)** | Same XRd config via gNMI | 2 IOS-XR | Task 4 |
| **Terraform (RESTCONF)** | IOS-XE config via RESTCONF + Docker infra | 1 IOS-XE + 2 Linux | Task 5 |
| **Version Control** | Commit and push completed work to GitHub | — | Task 6 |
| **Verification** | Automated show commands and ping tests | All 10 devices | Every task |

**By the numbers:**
- **10+ devices** managed from a single control node
- **4 different platforms** (NX-OS, IOS-XE, IOS-XR, Linux) with 3 different
  connection methods (network_cli with keys, network_cli with password, raw SSH)
- **2 IaC tools** (Ansible + Terraform) compared side-by-side on the same
  configuration, plus a second Terraform lab using RESTCONF
- **~32 configuration values** you filled in by hand, referencing topology
  diagrams and IP tables — just like real network planning
- **3 Ansible playbooks** + **2 Terraform configs** — replacing what would be
  hundreds of manual CLI commands across a dozen SSH sessions
- **0 manual device logins** — everything was done through automation
- **Version-controlled workflow** — your changes are committed and pushed to
  Git, just like a production IaC pipeline

### Key Takeaways

1. **Separation of data and logic** — Variables hold the "what" (IPs, VLANs,
   AS numbers), tasks hold the "how" (which module, which CLI commands). In
   production, you'd move the variables into separate files (group_vars,
   host_vars) so different teams can manage data and logic independently.

2. **Multi-vendor orchestration** — One playbook can configure NX-OS, IOS-XE,
   IOS-XR, and Linux in sequence. Ansible handles the platform differences
   through collections (`cisco.nxos`, `cisco.ios`, `cisco.iosxr`). You write
   one workflow; the collections translate it to each vendor's CLI.

3. **Idempotency** — Well-written playbooks are safe to run repeatedly. This
   is essential for CI/CD pipelines and production automation. You can schedule
   them to run hourly to catch config drift, or trigger them on git commits.

4. **Verification as code** — Every playbook includes verification and testing
   plays. Never assume config was applied correctly — automate the `show`
   commands and ping tests too. In production, these verification plays can
   trigger rollbacks if expected state isn't met.

5. **Infrastructure as Code (IaC)** — Everything you did today is stored in
   YAML and HCL files that can be version-controlled with Git, reviewed in
   pull requests, tested in CI pipelines, and audited for compliance. No more
   mystery changes — every change is documented in code.

6. **Right tool for the job** — Ansible and Terraform both automate network
   configuration, but they approach it differently. Ansible excels at
   multi-vendor orchestration and day-2 operations (compliance, patching,
   ad-hoc commands). Terraform excels at provisioning, state tracking, and
   clean lifecycle management (plan, apply, destroy). Most teams use both.

> **Automation Insight:** Everything you built today is in version-controllable YAML and HCL files — and you pushed them to a Git repository in Task 6. In a production workflow, someone opens a pull request to change a VLAN ID, a teammate reviews it, CI runs the playbook in a test environment, and only then does it hit production. No more mystery changes — every change has an author, a timestamp, and a review trail.

---

## Troubleshooting

> **💡 Automation Insight:** When something fails, Ansible tells you exactly which task, on which device, with what error. Compare that to a manual change where you're SSH'd into 4 devices and something stops working — was it the last command? The one before? A different device entirely? Structured automation gives you a built-in audit trail for every failure.

### Common Issues by Symptom

#### Playbook fails with YAML syntax error

```
ERROR! Syntax Error while loading YAML.
  mapping values are not allowed in this context
```

This almost always means **indentation is wrong**. YAML uses spaces (not tabs),
and the number of spaces matters. Common mistakes:
- Using 3 spaces instead of 2
- Mixing tabs and spaces (invisible but fatal)
- Misaligning a value with its siblings

**Fix:** Open the file in VS Code, which highlights YAML errors. Make sure
your filled-in values line up with the surrounding lines. Compare your
indentation to the comments on each line.

#### Playbook fails with "variable is undefined"

```
FAILED! => {"msg": "'___' is undefined"}
```

This means you left a TODO placeholder (`___`) unfilled. Ansible tried to
use it as a variable name and couldn't find it. Go back to the playbook
and fill in all the `___` values.

#### Playbook fails to connect to a device

```
UNREACHABLE! => {"msg": "Failed to connect to the host via ssh"}
```

- Check the device is reachable: `ping 172.20.20.X` (see inventory for IPs)
- For CSR: SSH may have hung after a config push. Wait 60 seconds and retry.
- For Linux clients: Try `ssh -i ~/.ssh/id_ed25519 root@172.20.20.40 hostname`
- If multiple devices are unreachable, the lab topology may need a re-deploy.
  Let your instructor know.

#### Ping tests fail after Task 1

- Verify VLANs exist and have correct ports:
  ```bash
  ansible nxos -m cisco.nxos.nxos_command -a "commands='show vlan brief'"
  ```
- Check that Eth1/3 and Eth1/4 are in the correct VLAN (23 on ce01, 34 on ce02)
- Make sure VLAN IDs match Table 1 — if you used the wrong ID, the SVI in
  Task 2 won't be in the same broadcast domain as the clients

#### IS-IS neighbors not coming up (Task 2)

- **Check NET format:** Each NET must follow `49.0002.XXXX.XXXX.XXXX.00`.
  A common mistake is wrong padding (e.g., `192.168.10.11` should pad to
  `192.168.010.011`, not `192.168.100.110`)
- **Check interface IPs:** Make sure Eth1/1 and Gi4 have IPs on the same /30
  ```bash
  ansible nxos -m cisco.nxos.nxos_command -a "commands='show ip interface brief'"
  ansible csr -m cisco.ios.ios_command -a "commands='show ip interface brief'"
  ```
- **Check IS-IS is enabled on the interface:** Both Eth1/1 (NX-OS) and Gi4 (IOS-XE)
  must be in the IS-IS process

#### BGP sessions not establishing (Task 3)

BGP issues almost always come down to IP addresses:
- **iBGP VPNv4 (`remote_lo`):** Must be the *other* XRd's Loopback0 IP.
  These loopbacks must be reachable via the pre-configured IS-IS/MPLS core.
- **eBGP (`csr_peer` / `xrd_peer`):** Must be the correct IPs on the /30 link.
  These are directly connected, so if the IP is wrong, BGP can't even start
  the TCP handshake.
- **Cross-check:** xrd01's `csr_peer` and csr-pe01's `xrd_peer` must be on
  the same /30 subnet but different IPs.

Check BGP status manually:
```bash
ansible xrd -m cisco.iosxr.iosxr_command -a "commands='show bgp vpnv4 unicast summary'"
ansible csr -m cisco.ios.ios_command -a "commands='show ip bgp summary'"
```

#### Cross-site pings fail but BGP is up

- **Check VRF routes:** Make sure both client subnets appear in the VRF table
  ```bash
  ansible xrd -m cisco.iosxr.iosxr_command -a "commands='show bgp vrf Customer-CLIVE'"
  ```
- **Check Linux routes:** Make sure clients have routes to the remote subnet
  ```bash
  ansible linux -m raw -a "ip route show"
  ```
- **Wait longer:** BGP VPNv4 convergence can take over 60 seconds on virtual
  routers. Try pinging manually after waiting:
  ```bash
  ansible linux-client1 -m raw -a "ping -c 3 -W 2 34.34.34.1"
  ```
- **Re-run the playbook:** All playbooks are idempotent. A second run with a
  fresh 90-second pause often resolves timing issues.

### General Tips

- **Always read the error message** — Ansible is verbose. The error text
  usually tells you exactly what went wrong and which task failed.
- **Re-run is safe** — All playbooks are idempotent. When in doubt, fix
  your values and re-run. It won't create duplicate config.
- **Check the solution files** — If you're stuck, peek at `solutions/` for
  the correct values:
  ```bash
  cat ~/solutions/ce-access-vlan.yml | head -20
  ```

---

← [Task 5](TASK5.md) | [Task 6](TASK6.md) | [Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md)
