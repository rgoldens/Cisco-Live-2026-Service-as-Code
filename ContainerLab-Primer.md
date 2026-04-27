[Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md) | [Ansible Primer](Ansible-Primer.md) | [Terraform Primer](Terraform-Primer.md)

---

## ContainerLab Quick Primer

If you're new to ContainerLab, take a few minutes to read this section. Understanding
how the lab environment is built will give you useful context as you work through the
tasks — even though the lab is already deployed and running for you.

### What is ContainerLab?

ContainerLab is an open-source tool that builds virtual network topologies using Docker
containers. Instead of racking physical switches and routers, you define your entire
network in a single YAML file, and ContainerLab spins it up in seconds — complete with
links, management access, and startup configurations.

**Key properties:**
- **Topology as code** — Your entire lab is defined in one YAML file
  (`LTRATO-1001.clab.yml`). Anyone with that file can recreate the exact same topology.
- **Docker-based** — Every network device runs as a Docker container. Standard Docker
  commands (`docker ps`, `docker logs`, `docker exec`) work on lab nodes.
- **Multi-vendor** — ContainerLab supports dozens of network operating systems through
  container images: Cisco IOS-XR (XRd), IOS-XE (CSR via vrnetlab), NX-OS (via vrnetlab),
  Arista cEOS, Nokia SR Linux, Linux hosts, and more.
- **vrnetlab integration** — Commercial NOS images that ship as VM disk images (like CSR
  and NX-OS) are wrapped in Docker containers using
  [vrnetlab](https://github.com/hellt/vrnetlab). The VM runs inside the container,
  and ContainerLab manages it like any other Docker workload.

### How It Works

A ContainerLab topology file defines three things:

1. **Nodes** — each device in the lab (its name, image, and kind)
2. **Links** — point-to-point connections between nodes (which interface on device A
   connects to which interface on device B)
3. **Startup configs** — optional config files that get injected into devices at boot time

When you run `sudo clab deploy`, ContainerLab:
- Creates a Docker bridge network for management access (`172.20.20.0/24` in this lab)
- Launches each node as a Docker container with the specified image
- Wires up the inter-node links as virtual Ethernet pairs
- Injects startup configurations so devices come up pre-configured
- Assigns each node a management IP address for SSH/API access

Here is a simplified view of the topology YAML structure:

```yaml
name: LTRATO-1001
topology:
  nodes:
    xrd01:
      kind: cisco_xrd        # IOS-XR container (XRd)
      image: xrd:24.2.11
      startup-config: xrd01.cfg
    csr-pe01:
      kind: vr-csr           # IOS-XE VM wrapped in Docker (vrnetlab)
      image: vrnetlab/vr-csr:17.03.08
    n9k-ce01:
      kind: vr-n9kv          # NX-OS VM wrapped in Docker (vrnetlab)
      image: vrnetlab/vr-n9kv:10.4.3
    client1:
      kind: linux             # Lightweight Linux container
      image: ghcr.io/hellt/network-multitool

  links:
    - endpoints: ["csr-pe01:eth2", "xrd01:Gi0-0-0-0"]
    - endpoints: ["n9k-ce01:eth2", "csr-pe01:eth3"]
```

> **In this lab, the topology is already deployed for you.** You do not need to run
> `clab deploy` — the instructor has set everything up before your session. This primer
> is here so you understand what's running under the hood.

### Common Commands

These are the ContainerLab and Docker commands you're most likely to encounter. You
won't need most of them during the lab, but they're useful for understanding the
environment.

| Command | What it does |
|---------|-------------|
| `sudo clab deploy -t <file>.clab.yml` | Deploy a topology (instructor only) |
| `sudo clab destroy -t <file>.clab.yml` | Tear down a topology and remove all containers |
| `sudo clab inspect -t <file>.clab.yml` | Show all nodes, their images, states, and management IPs |
| `docker ps` | List running containers (add `--filter name=clab` to show only lab nodes) |
| `docker logs <container>` | View a container's console output (useful for boot troubleshooting) |
| `docker exec -it <container> bash` | Open a shell inside a Linux container |
| `ssh clab@<mgmt-ip>` | SSH into a network device using its management IP |

#### Accessing lab devices

Every device in the topology gets a management IP on the `172.20.20.0/24` network.
The Ansible inventory (`inventory.yml`) maps device names to these IPs, so Ansible
and Terraform can reach them automatically. You can also SSH directly:

```bash
# SSH into an XRd router (uses key-based auth)
ssh -i ~/.ssh/id_rsa clab@172.20.20.10

# SSH into a CSR router (uses password auth)
ssh cisco@172.20.20.20
```

### VS Code ContainerLab Extension

The lab server has the **ContainerLab VS Code extension** installed. It provides:

- **Visual topology view** — see your network as a graph with nodes and links
- **One-click terminal access** — right-click any node to open an SSH session directly
  in VS Code
- **Node status** — quickly see which containers are running, healthy, or stopped

To access it, look for the ContainerLab icon in the VS Code sidebar. This is the
easiest way to open a terminal to a specific device (e.g., when Task 4b asks you to
SSH into xrd01 to manually break something).

### Key Concepts Reference

| Concept | What It Means |
|---------|--------------|
| **Topology file** | The YAML file (`.clab.yml`) that defines the entire lab — nodes, links, and configs |
| **Node** | A single device in the topology — runs as a Docker container |
| **Kind** | The node type — tells ContainerLab which driver to use (`cisco_xrd`, `vr-csr`, `vr-n9kv`, `linux`) |
| **Link** | A point-to-point virtual Ethernet connection between two node interfaces |
| **Management network** | A Docker bridge network (`172.20.20.0/24`) that provides SSH/API access to all nodes |
| **Startup config** | A config file injected into a node at boot — devices come up pre-configured |
| **vrnetlab** | A tool that wraps VM-based network OS images (CSR, N9Kv) in Docker containers |
| **clab prefix** | Container names are prefixed with `clab-<topology-name>-` (e.g., `clab-LTRATO-1001-xrd01`) |

---
