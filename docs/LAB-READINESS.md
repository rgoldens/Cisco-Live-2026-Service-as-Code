
---

# Lab Readiness

Complete these steps **before** starting Task 1. This sets up your
environment and verifies everything is working.

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

```text
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

```text
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
ls -l ~/inventory.yml ~/ansible.cfg
```

You should see both files listed without errors:

![ls -l output](images/lab-readiness-ls-output.png)

These are the two core files Ansible needs to run. The repo also includes playbooks for Tasks 1–5, Terraform directories, and a `solutions/` folder — you'll use those as you progress through the lab.

!!! info "What did you just clone?"

    | File / Folder             | Purpose                                                    |
    |---------------------------|-------------------------------------------------------------|
    | `ansible.cfg`             | Ansible config — tells Ansible where the inventory is      |
    | `inventory.yml`           | All 10 devices: IPs, credentials, and connection settings  |
    | `ce-access-vlan.yml`      | Task 1 playbook (VLANs)                                    |
    | `igp-pe-ce.yml`           | Task 2 playbook (IS-IS)                                    |
    | `inter-as-option-a.yml`   | Task 3 playbook (BGP VPN)                                  |
    | `task4-terraform/`        | Terraform files for Task 4 (IOS-XR via gNMI)              |
    | `task5-terraform/`        | Terraform files for Task 5 (IaC with IOS-XE)              |
    | `solutions/`              | Completed playbooks and configs — use if you get stuck     |

---

## Step 3: Verify Ansible Is Working

```bash
ansible --version
```

You should see Ansible core 2.x with Python 3.x:

![ansible --version output](images/getting-started-ansible-version-output.png)

> **Key check:** Make sure `config file` points to `/home/cisco/ansible.cfg`.
> If it says `None`, the file didn't land in the right place — re-check Step 2.

---

## Step 4: Verify Terraform Is Working

```bash
terraform --version
```

You should see Terraform v1.x.x:

![terraform --version output](images/getting-started-terraform-version-output.png)

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

![ansible all -m ping output](images/getting-started-ansible-ping-output.png)

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
- [ ] You know how to edit files (`vi` or `nano`)

**All green? You're ready for [Task 1](TASK1.md)!**
