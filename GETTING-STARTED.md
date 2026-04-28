[← Lab Access](LAB-ACCESS.md) | [Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md) | [Primer →](PRIMER.md)

---

# Getting Started

Complete these steps **before** starting Task 1. This sets up your
environment and verifies everything is working.

---

## What You Will Learn

- **Ansible fundamentals:** playbooks, plays, tasks, variables, modules
- **Multi-vendor automation:** configuring NX-OS, IOS-XE, IOS-XR, and Linux
  from a single workflow
- **Infrastructure as Code:** defining network state in YAML, not CLI commands
- **Verification and testing:** automating not just config, but validation

## What You Will Build

| Task | Technology | Outcome |
|------|-----------|---------|
| Task 1 | L2 VLANs (NX-OS) | Clients on the same switch can communicate |
| Task 2 | IS-IS routing (NX-OS + IOS-XE) | Clients can reach their local PE router |
| Task 3 | BGP VPN / Inter-AS Option A (IOS-XR + IOS-XE) | Full east-west connectivity across the SP core |
| Task 4 | Terraform (IOS-XR via gNMI) | Same XRd config as Task 3, different tool |

Each task builds on the previous one. By Task 3, traffic crosses 6 network
devices and 4 different platforms.

![Connectivity Progress](images/before-after.png)

---

## Lab Topology

![Full Lab Topology](images/full-topology.png)

Your lab has **10 devices** across 4 platforms:

| Layer | Devices | Platform | Role |
|-------|---------|----------|------|
| SP Core | xrd01, xrd02 | IOS-XR | P routers — IS-IS, MPLS, BGP VPNv4 (pre-configured) |
| PE Edge | csr-pe01, csr-pe02 | IOS-XE | PE routers — eBGP to XRd, IS-IS to N9K |
| CE Access | n9k-ce01, n9k-ce02 | NX-OS | CE switches — VLANs, SVIs, IS-IS to CSR |
| Clients | client1-4 | Linux (Alpine) | Traffic endpoints for ping tests |

> **What's pre-configured?** The XRd core routers come with IS-IS, MPLS LDP,
> and Loopback0 already configured in their startup configs. All other devices
> have baseline IP addressing on their uplink interfaces. You will configure
> everything else through automation.

<details>
<summary>Text topology diagram (click to expand)</summary>

```
           ┌─────────────┐             ┌─────────────┐
           │    xrd01     │─────────────│    xrd02     │    SP Core (IOS-XR)
           │   AS 65000   │  Gi0/0/0/0  │   AS 65000   │    IS-IS + MPLS
           │ Lo0: .0.1    │             │ Lo0: .0.2    │    (pre-configured)
           └──────┬───────┘             └──────┬───────┘
                  │ Gi0/0/0/1                  │ Gi0/0/0/1
                  │ 10.1.0.5                   │ 10.1.0.9
                  │                            │
                  │ 10.1.0.6                   │ 10.1.0.10
                  │ Gi2                        │ Gi2
           ┌──────┴───────┐             ┌──────┴───────┐
           │   csr-pe01   │             │   csr-pe02   │    PE Routers (IOS-XE)
           │   AS 65001   │             │   AS 65001   │
           │ Lo0: .10.11  │             │ Lo0: .10.12  │
           └──────┬───────┘             └──────┬───────┘
                  │ Gi4                        │ Gi4
                  │ 10.2.0.1                   │ 10.2.0.5
                  │                            │
                  │ 10.2.0.2                   │ 10.2.0.6
                  │ Eth1/1                     │ Eth1/1
           ┌──────┴───────┐             ┌──────┴───────┐
           │   n9k-ce01   │             │   n9k-ce02   │    CE Switches (NX-OS)
           │ Lo0: .20.21  │             │ Lo0: .20.22  │
           └──┬────────┬──┘             └──┬────────┬──┘
           Eth1/3    Eth1/4              Eth1/3    Eth1/4
             │         │                  │         │
          ┌──┴──┐   ┌──┴──┐           ┌──┴──┐   ┌──┴──┐
          │ C1  │   │ C2  │           │ C3  │   │ C4  │    Linux Clients
          │.23.1│   │.23.2│           │.34.1│   │.34.2│
          └─────┘   └─────┘           └─────┘   └─────┘
```

> **Notation:** IP addresses are shortened. For example, `.0.1` means
> `192.168.0.1`, `.10.11` means `192.168.10.11`, `.23.1` means `23.23.23.1`.

</details>

---

## Step 1: Open Your Terminal

If you completed [Lab Access](LAB-ACCESS.md), your terminal is already open in VS Code with the prompt `cisco@ubuntu:~$`. Use that same terminal for all commands in this guide.

> **Not set up yet?** Go to [Lab Access](LAB-ACCESS.md) first — it walks you through VPN, VS Code Remote-SSH, and opening your terminal.

---

## Step 2: Clone the Lab Repository

The lab files need to live directly in your home directory (`/home/cisco/`)
because the Ansible configuration expects them there. Since the home directory
already has other files in it, we clone into a temporary folder first, then
move everything into place.

**2a.** Make sure you are in your home directory:

```bash
cd ~
```

**2b.** Clone the repository into a temporary folder:

```bash
git clone https://<TOKEN>@github.com/rgoldens/Cisco-Live-2026-Service-as-Code.git .lab-tmp
```

> **Note:** Your instructor will provide the `<TOKEN>` value. This is a shared
> access token that allows everyone to clone and push to the repository.

**2c.** Move all files (including hidden `.git` folder) from the temporary folder
into your home directory, then remove the empty temporary folder:

```bash
mv .lab-tmp/* .lab-tmp/.* . 2>/dev/null
rm -rf .lab-tmp
```

> The `2>/dev/null` suppresses harmless warnings about `.` and `..` — you can
> safely ignore any that appear.

**2d.** Create your own branch. Replace `XX` with your student number
(e.g., `student-01`, `student-12`):

```bash
git checkout -b student-XX
```

**2e.** Verify the files are in place:

```bash
ls ~/inventory.yml ~/ansible.cfg ~/ce-access-vlan.yml
```

You should see all three files listed without errors:

<pre>
/home/cisco/ansible.cfg  /home/cisco/ce-access-vlan.yml  /home/cisco/inventory.yml
</pre>

> **What did you just clone?** The repository contains:
> - `ansible.cfg` — Ansible configuration (tells Ansible where the inventory is)
> - `inventory.yml` — All 10 devices with IPs, credentials, and connection settings
> - `ce-access-vlan.yml` — Task 1 playbook (VLANs)
> - `igp-pe-ce.yml` — Task 2 playbook (IS-IS)
> - `inter-as-option-a.yml` — Task 3 playbook (BGP VPN)
> - `task5-terraform/` — Terraform files for Task 5
> - `solutions/` — Completed playbooks (if you get stuck)

---

## Step 3: Verify Ansible Is Working

```bash
ansible --version
```

You should see Ansible core 2.x with Python 3.x. Example:

```
ansible [core 2.20.3]
  config file = /home/cisco/ansible.cfg
  ...
  python version = 3.12.3
```

> **Key check:** Make sure `config file` points to `/home/cisco/ansible.cfg`.
> If it says `None`, the file didn't land in the right place — re-check Step 2.

---

## Step 4: Verify Terraform Is Working

```bash
terraform --version
```

You should see Terraform v1.x.x. Example:

```
Terraform v1.14.7
on linux_amd64
```

> You won't use Terraform until Task 4, but verifying it now catches any
> issues early.

---

## Step 5: Understand the Inventory

The inventory file defines all the devices Ansible will manage. Open it:

```bash
cat ~/inventory.yml
```

Notice how devices are organized into **groups** (`xrd`, `csr`, `nxos`,
`linux`). Each group has platform-specific connection settings. This is how
Ansible knows which module and transport to use for each device type.

**Key things to notice:**
- `ansible_network_os` tells Ansible which platform collection to use
- `ansible_connection: network_cli` means Ansible connects via SSH and
  sends CLI commands (just like you would manually)
- Different devices use different SSH authentication (keys vs passwords) —
  Ansible handles this transparently

> **Automation Insight:** This inventory file is your single source of truth.
> Every IP, every credential, every platform mapping — one file. When a device
> gets replaced or an IP changes, you update it here and every playbook
> automatically picks up the change.

---

## Step 6: Test Connectivity

This is the most important pre-check. Run:

```bash
ansible all -m ping
```

The **6 network devices** should return `SUCCESS`. The **4 Linux clients will
FAIL** — this is expected and explained below.

```
n9k-ce01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
csr-pe01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
xrd01 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
xrd02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
csr-pe02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
n9k-ce02 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
linux-client1 | FAILED! => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "module_stderr": "Shared connection to 172.20.20.40 closed.\r\n",
    "module_stdout": "/bin/sh: /usr/bin/python3: not found\r\n",
    "msg": "The module interpreter '/usr/bin/python3' was not found.",
    "rc": 127
}
linux-client2 | FAILED! => { ... }
linux-client3 | FAILED! => { ... }
linux-client4 | FAILED! => { ... }
```

> **Why do the Linux clients fail?** Don't worry — this is expected. The
> `ping` module requires Python on the remote host, but our Linux containers
> are minimal Alpine images with no Python installed. That's why you see
> `"/usr/bin/python3: not found"`. This does **not** mean Ansible can't manage
> them. Our playbooks use the `raw` module for Linux tasks, which sends
> commands directly over SSH without needing Python. You'll see this in action
> in Tasks 1 and 2.

If any of the **6 network devices** show `UNREACHABLE`, let your instructor
know — a device may still be booting or SSH keys may need to be re-injected.

> **What just happened?** The `ping` module doesn't send ICMP — it verifies
> Ansible can connect to each device via SSH and execute a simple command.
> It's a connectivity health check for your automation, not a network ping.

---

## Step 7: Open the Reference Tables

Open the [Reference Tables](REFERENCE.md) in a separate browser tab (or
keep it visible in VS Code). You'll use these tables throughout the lab to
look up VLAN IDs, IP addresses, BGP AS numbers, and IS-IS NET addresses.

| Table | Used In |
|-------|---------|
| Table 1: VLAN Assignments | Task 1 |
| Table 2: IP Addressing | Tasks 2, 3, 4 |
| Table 3: BGP Peering | Tasks 3, 4 |
| Table 4: IS-IS Configuration | Task 2 |

---

## Pre-Flight Checklist

Before starting Task 1, confirm all of the following:

- [ ] Connected to the lab server — VS Code shows `SSH: 198.18.134.90` in blue and terminal prompt is `cisco@ubuntu:~$`
- [ ] Repository cloned and files are in `/home/cisco/`
- [ ] `ansible --version` shows Ansible core 2.x
- [ ] `terraform --version` shows Terraform v1.x
- [ ] `ansible.cfg` config file path is `/home/cisco/ansible.cfg`
- [ ] `ansible all -m ping` — 6 network devices return SUCCESS
- [ ] Reference tables are open and accessible
- [ ] You know how to edit files (VS Code or `nano`)

**All green? You're ready for [Task 1](TASK1.md)!**

---

## How the Lab Works

Every task follows the same pattern:

1. **Read** — Understand what you're building and why
2. **Fill in** — Open the playbook/config file and replace TODO values using the reference tables
3. **Run** — Execute the playbook or Terraform command
4. **Verify** — Check the output and confirm connectivity
5. **Understand** — Read the output walkthrough to learn what happened

The playbooks are already written — you supply the **data** (variable values),
not the **logic** (automation code). This mirrors real-world IaC practice where
templates are reusable and operators fill in site-specific values.

> **If you get stuck:** Solution files are in the `solutions/` folder. Compare
> your playbook against the solution to find the difference. You can also ask
> your instructor for help.

> **New to Ansible?** Read the [Ansible Quick Primer](Ansible-Primer.md) before
> starting Task 1. It takes about 5 minutes and covers everything you need
> to know.

---

[← Lab Access](LAB-ACCESS.md) | [Lab Guide](LAB-GUIDE.md) | [Reference Tables](REFERENCE.md) | [Task 1 →](TASK1.md)
