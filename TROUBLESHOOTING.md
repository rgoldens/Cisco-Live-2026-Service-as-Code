← [Task 5](TASK5.md) | [Task 6](TASK6.md) | [Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md)

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
