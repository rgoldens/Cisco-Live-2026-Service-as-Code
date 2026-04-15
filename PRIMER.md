← [Reference Tables](REFERENCE.md) | [Lab Guide](LAB-GUIDE.md) | [Task 1 →](TASK1.md)

---

## Ansible Quick Primer

If you're new to Ansible, take 5 minutes to read this section. Understanding
these concepts will make the rest of the lab much more intuitive.

### What is Ansible?

![How Ansible Works](images/ansible-workflow.png)

Ansible is an open-source automation tool that manages infrastructure through
**code** instead of manual CLI sessions. Instead of SSH'ing into 10 devices
and typing commands one by one, you write a YAML file describing the desired
state, and Ansible handles the rest — connecting, authenticating, sending
commands, and verifying results.

**Key properties:**
- **Agentless** — No software needs to be installed on the managed devices.
  Ansible connects over SSH (same as you would manually).
- **Declarative** — You describe *what* the state should be, not the exact
  steps to get there. Ansible figures out what commands to send.
- **Idempotent** — Running the same playbook twice produces the same result.
  If the config is already correct, Ansible makes no changes.
- **Multi-vendor** — One tool handles NX-OS, IOS-XE, IOS-XR, Linux, and more.
  Platform-specific "collections" (plugins) handle the differences.

### Playbook Structure

![Anatomy of an Ansible Playbook](images/playbook-anatomy.png)

A **playbook** is a YAML file containing one or more **plays**. Each play
targets a group of devices and runs a series of **tasks**:

```yaml
---                              # YAML document start
- name: "My Play"               # A PLAY targets a group of devices
  hosts: nxos                    # Which devices from inventory to configure
  gather_facts: false            # Skip auto-discovery (required for network devices)

  vars:                          # VARIABLES — data that tasks reference
    my_vlan: 23

  tasks:                         # TASKS — the actual work, executed in order

    - name: "Create VLAN"        # Human-readable description
      cisco.nxos.nxos_vlans:     # MODULE — the Ansible plugin that does the work
        config:
          - vlan_id: "{{ my_vlan }}"   # {{ }} = variable substitution
        state: merged            # "merged" = add without removing existing config
```

**The flow:** Ansible reads the playbook → connects to each host in `hosts:` →
runs each task in order → reports results. If a task fails, Ansible stops on
that host (but continues on others).

### Variables: Separating Data from Logic

The most important concept in this lab is **variable separation**. Look at the
playbook structure:

```yaml
vars:                # ← DATA (what to configure — you edit this)
  vlan_config:
    n9k-ce01:
      id: 23

tasks:               # ← LOGIC (how to configure — already written for you)
  - name: "Create VLAN"
    cisco.nxos.nxos_vlans:
      config:
        - vlan_id: "{{ vlan_config[inventory_hostname].id }}"
```

The `vars` section is the **data** — the specific values for your network.
The `tasks` section is the **logic** — the Ansible modules and their structure.
In this lab, **you edit the data (vars), not the logic (tasks).** This mirrors
real-world IaC practice: engineers change variables in a data file, and the
automation logic stays the same across environments.

The expression `{{ vlan_config[inventory_hostname].id }}` means: "Look up the
current device's hostname in the `vlan_config` dictionary, then get its `id`
field." When Ansible runs on `n9k-ce01`, this resolves to `23`. When it runs
on `n9k-ce02`, it resolves to whatever you set for that switch.

> **Automation Insight:** This data/logic split is the pattern behind every scalable automation system. Think of it this way: the playbook is a template you write once. The variables are a spreadsheet your team fills in. When a new site comes online, nobody touches the automation code — they just add a row to the data.

### Key Concepts Reference

| Concept | What It Means |
|---------|--------------|
| **Play** | A block that targets a group of hosts and runs tasks on them |
| **Task** | A single action (create VLAN, push CLI config, run a command) |
| **Module** | The plugin that performs the action (`nxos_vlans`, `ios_config`, etc.) |
| **Variable** | Data referenced with `{{ }}` — keeps config values separate from logic |
| **Collection** | A package of modules for a specific platform (e.g., `cisco.nxos`) |
| **`hosts:`** | Which inventory group to target (e.g., `nxos`, `csr`, `xrd`, `linux`) |
| **`gather_facts: false`** | Must be set for network devices (they don't support default fact gathering) |
| **`state: merged`** | Add/update config without removing anything that already exists |
| **`register:`** | Save command output into a variable for later display or inspection |
| **`loop:`** | Run the same task multiple times, once per item in a list |
| **`when:`** | Only run this task if a condition is true |
| **Idempotency** | Running the same playbook twice produces the same result — no duplicate config |

### How to Edit Playbooks

Use VS Code (already connected via Remote-SSH) to open and edit the YAML
files. You can also use `nano` or `vi` from the terminal:

```bash
nano ~/ce-access-vlan.yml
```

> **YAML is whitespace-sensitive.** Use spaces (not tabs), and make sure
> your indentation matches the surrounding lines. If your playbook fails
> with a syntax error, check indentation first. A common mistake is using
> 3 spaces instead of 2, or mixing tabs and spaces.

> **Tip:** In VS Code, the bottom status bar shows "Spaces: 2" when the
> file is set to 2-space indentation. If you see "Tab Size: 4", click it
> and switch to spaces.

> **Automation Insight:** This TODO pattern mirrors how real teams work. A senior engineer writes the playbook logic and tests it. A junior engineer or even a NOC operator fills in the variables for each deployment. The automation skill ceiling is low — if you can read a table and type a number, you can deploy infrastructure. That's how automation democratizes network operations.

---

← [Reference Tables](REFERENCE.md) | [Lab Guide](LAB-GUIDE.md) | [Task 1 →](TASK1.md)
