
---

## Reference Tables

These tables are your primary reference when filling in playbook variables.
Keep this section open while you work.

### Table 1: VLAN Assignments — Task 1

| Switch | `vlan_id` | `vlan_name` | Ports | Connected Clients |
|--------|-----------|-------------|-------|-------------------|
| n9k-ce01 | `23` | `CLIENT-VLAN-23` | Eth1/3, Eth1/4 | client1, client2 |
| n9k-ce02 | `34` | `CLIENT-VLAN-34` | Eth1/3, Eth1/4 | client3, client4 |

### Table 2: IS-IS Configuration — Task 2

Use these values to fill in the `isis_config` variables in `igp-pe-ce.yml`.

| Device | `net` | `vlan_id` | `svi_ip` |
|--------|-------|-----------|----------|
| n9k-ce01 | `49.0002.1921.6802.0021.00` | `23` | `23.23.23.254/24` |
| n9k-ce02 | `49.0002.1921.6802.0022.00` | `34` | `34.34.34.254/24` |
| csr-pe01 | `49.0002.1921.6801.0011.00` | — | — |
| csr-pe02 | `49.0002.1921.6801.0012.00` | — | — |

Use these values to fill in the `route_config` variables for Linux clients:

| Client | `gateway` | Routes |
|--------|-----------|--------|
| linux-client1 | `23.23.23.254` | `192.168.10.0/24`, `10.2.0.0/30` |
| linux-client2 | `23.23.23.254` | `192.168.10.0/24`, `10.2.0.0/30` |
| linux-client3 | `34.34.34.254` | `192.168.10.0/24`, `10.2.0.4/30` |
| linux-client4 | `34.34.34.254` | `192.168.10.0/24`, `10.2.0.4/30` |

### Table 3: BGP Peering — Task 3

Use these values to fill in the `bgp_config` variables in `inter-as-option-a.yml`.

**XRd routers (`xrd_bgp_config`):**

| Device | `remote_lo` (iBGP peer Lo0) | `gi1_ip` | `gi1_mask` | `csr_peer` |
|--------|-----------------------------|----------|------------|------------|
| xrd01 | `192.168.0.2` | `10.1.0.5` | `255.255.255.252` | `10.1.0.6` |
| xrd02 | `192.168.0.1` | `10.1.0.9` | `255.255.255.252` | `10.1.0.10` |

**CSR PE routers (`csr_bgp_config`):**

| Device | `xrd_peer` |
|--------|------------|
| csr-pe01 | `10.1.0.5` |
| csr-pe02 | `10.1.0.9` |

**Linux client routes (`route_config`):**

| Client | `dest` | `gw` |
|--------|--------|------|
| linux-client1 | `34.34.34.0/24` | `23.23.23.254` |
| linux-client2 | `34.34.34.0/24` | `23.23.23.254` |
| linux-client3 | `23.23.23.0/24` | `34.34.34.254` |
| linux-client4 | `23.23.23.0/24` | `34.34.34.254` |

### Table 4: Full IP Address Reference

Complete address reference for all devices — useful for verification and troubleshooting.

| Device | Interface | Address | Purpose |
|--------|-----------|---------|---------|
| **xrd01** | Loopback0 | 192.168.0.1/32 | Router ID / iBGP source |
| **xrd01** | Gi0/0/0/0 | 10.0.0.1/30 | Core link to xrd02 |
| **xrd01** | Gi0/0/0/1 | 10.1.0.5/30 | Link to csr-pe01 |
| **xrd02** | Loopback0 | 192.168.0.2/32 | Router ID / iBGP source |
| **xrd02** | Gi0/0/0/0 | 10.0.0.2/30 | Core link to xrd01 |
| **xrd02** | Gi0/0/0/1 | 10.1.0.9/30 | Link to csr-pe02 |
| **csr-pe01** | Loopback0 | 192.168.10.11/32 | Router ID |
| **csr-pe01** | Gi2 | 10.1.0.6/30 | Link to xrd01 |
| **csr-pe01** | Gi4 | 10.2.0.1/30 | Link to n9k-ce01 |
| **csr-pe02** | Loopback0 | 192.168.10.12/32 | Router ID |
| **csr-pe02** | Gi2 | 10.1.0.10/30 | Link to xrd02 |
| **csr-pe02** | Gi4 | 10.2.0.5/30 | Link to n9k-ce02 |
| **n9k-ce01** | Loopback0 | 192.168.20.21/32 | Router ID |
| **n9k-ce01** | Eth1/1 | 10.2.0.2/30 | Uplink to csr-pe01 |
| **n9k-ce01** | SVI Vlan23 | 23.23.23.254/24 | Client gateway (west) |
| **n9k-ce02** | Loopback0 | 192.168.20.22/32 | Router ID |
| **n9k-ce02** | Eth1/1 | 10.2.0.6/30 | Uplink to csr-pe02 |
| **n9k-ce02** | SVI Vlan34 | 34.34.34.254/24 | Client gateway (east) |
| **linux-client1** | eth1 | 23.23.23.1/24 | West client |
| **linux-client2** | eth1 | 23.23.23.2/24 | West client |
| **linux-client3** | eth1 | 34.34.34.1/24 | East client |
| **linux-client4** | eth1 | 34.34.34.2/24 | East client |

---

