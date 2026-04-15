← [Getting Started](GETTING-STARTED.md) | [Lab Guide](LAB-GUIDE.md) | [Primer →](PRIMER.md)

---

## Reference Tables

These tables are your primary reference when filling in playbook variables.
Keep this section open while you work.

### Table 1: VLAN Assignments

| Switch | VLAN ID | VLAN Name | Ports | Connected Clients |
|--------|---------|-----------|-------|-------------------|
| n9k-ce01 | 23 | CLIENT-VLAN-23 | Eth1/3, Eth1/4 | client1 (23.23.23.1), client2 (23.23.23.2) |
| n9k-ce02 | 34 | CLIENT-VLAN-34 | Eth1/3, Eth1/4 | client3 (34.34.34.1), client4 (34.34.34.2) |

### Table 2: IP Addressing

| Device | Interface | IP Address | Subnet | Purpose |
|--------|-----------|-----------|--------|---------|
| **xrd01** | Loopback0 | 192.168.0.1 | /32 | Router ID / iBGP source |
| **xrd01** | Gi0/0/0/0 | 10.0.0.1 | /30 | Core link to xrd02 |
| **xrd01** | Gi0/0/0/1 | 10.1.0.5 | /30 | Link to csr-pe01 |
| **xrd02** | Loopback0 | 192.168.0.2 | /32 | Router ID / iBGP source |
| **xrd02** | Gi0/0/0/0 | 10.0.0.2 | /30 | Core link to xrd01 |
| **xrd02** | Gi0/0/0/1 | 10.1.0.9 | /30 | Link to csr-pe02 |
| **csr-pe01** | Loopback0 | 192.168.10.11 | /32 | Router ID |
| **csr-pe01** | Gi2 | 10.1.0.6 | /30 | Link to xrd01 |
| **csr-pe01** | Gi4 | 10.2.0.1 | /30 | Link to n9k-ce01 |
| **csr-pe02** | Loopback0 | 192.168.10.12 | /32 | Router ID |
| **csr-pe02** | Gi2 | 10.1.0.10 | /30 | Link to xrd02 |
| **csr-pe02** | Gi4 | 10.2.0.5 | /30 | Link to n9k-ce02 |
| **n9k-ce01** | Loopback0 | 192.168.20.21 | /32 | Router ID |
| **n9k-ce01** | Eth1/1 | 10.2.0.2 | /30 | Uplink to csr-pe01 |
| **n9k-ce01** | SVI (Vlan23) | 23.23.23.254 | /24 | Client gateway (west) |
| **n9k-ce02** | Loopback0 | 192.168.20.22 | /32 | Router ID |
| **n9k-ce02** | Eth1/1 | 10.2.0.6 | /30 | Uplink to csr-pe02 |
| **n9k-ce02** | SVI (Vlan34) | 34.34.34.254 | /24 | Client gateway (east) |
| **linux-client1** | eth1 | 23.23.23.1 | /24 | West client |
| **linux-client2** | eth1 | 23.23.23.2 | /24 | West client |
| **linux-client3** | eth1 | 34.34.34.1 | /24 | East client |
| **linux-client4** | eth1 | 34.34.34.2 | /24 | East client |

### Table 3: BGP Peering

| Session | Type | Local Device | Local AS | Local IP | Remote Device | Remote AS | Remote IP |
|---------|------|-------------|----------|----------|---------------|-----------|-----------|
| XRd iBGP | VPNv4 | xrd01 | 65000 | 192.168.0.1 (Lo0) | xrd02 | 65000 | 192.168.0.2 (Lo0) |
| XRd iBGP | VPNv4 | xrd02 | 65000 | 192.168.0.2 (Lo0) | xrd01 | 65000 | 192.168.0.1 (Lo0) |
| West eBGP | IPv4 VRF | xrd01 | 65000 | 10.1.0.5 (Gi0/0/0/1) | csr-pe01 | 65001 | 10.1.0.6 (Gi2) |
| East eBGP | IPv4 VRF | xrd02 | 65000 | 10.1.0.9 (Gi0/0/0/1) | csr-pe02 | 65001 | 10.1.0.10 (Gi2) |

### Table 4: IS-IS Configuration

| Device | Loopback0 IP | IS-IS NET Address | Role |
|--------|-------------|-------------------|------|
| n9k-ce01 | 192.168.20.21 | 49.0002.1921.6802.0021.00 | CE |
| n9k-ce02 | 192.168.20.22 | 49.0002.1921.6802.0022.00 | CE |
| csr-pe01 | 192.168.10.11 | 49.0002.1921.6801.0011.00 | PE |
| csr-pe02 | 192.168.10.12 | 49.0002.1921.6801.0012.00 | PE |

> **How IS-IS NET addresses are derived:** See the "Deriving IS-IS NET
> Addresses" section under [Task 2](TASK2.md) for a step-by-step walkthrough.

---

← [Getting Started](GETTING-STARTED.md) | [Lab Guide](LAB-GUIDE.md) | [Primer →](PRIMER.md)
