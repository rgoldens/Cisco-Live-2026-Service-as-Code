[Lab Guide](LAB-GUIDE.md) | [Getting Started →](GETTING-STARTED.md)

---

# Lab Access Guide — Windows PC

This guide walks you through connecting to your dCloud lab environment from
the Windows PC at your desk. You will:

1. Connect to the lab network using **Cisco AnyConnect VPN**
2. Open **VS Code** and SSH into your **Ubuntu lab server**

> **Both AnyConnect and VS Code are already installed on your PC.** You do not
> need to download or install anything.

---

## What You Need Before Starting

You should have received a **lab credential sheet** (printed or emailed) with
the following information. Confirm you have all four values before proceeding:

| Item | Example | Your Value |
|------|---------|------------|
| **VPN Address** | `dcloud-sjc-anyconnect.cisco.com` | _______________ |
| **VPN Username** | `v123user1` | _______________ |
| **VPN Password** | `a1b2c3` | _______________ |
| **Lab Server IP** | `198.18.134.100` | _______________ |

> **Do not have your credentials?** Raise your hand and a proctor will bring
> them to you. Do not proceed without them.

---

## Part 1: Connect to the Lab Network with Cisco AnyConnect

### Step 1 — Open Cisco AnyConnect

1. Click the **Windows Start menu** (bottom-left corner of the screen, or
   press the **Windows key** on your keyboard).
2. Type **`AnyConnect`** in the search bar.
3. Click **Cisco AnyConnect Secure Mobility Client** when it appears in the
   search results.

A small AnyConnect window will open with an empty text field and a
**Connect** button.

> **If you see a "VPN Ready to connect" icon in the system tray** (bottom-right
> corner, near the clock), you can also double-click that icon to open
> AnyConnect.

---

### Step 2 — Enter the VPN Address

1. In the AnyConnect window, you will see a text field labeled
   **"VPN: Ready to connect"** (or simply an empty connection box).
2. **Type or paste** your **VPN Address** into this field.
   - Example: `dcloud-sjc-anyconnect.cisco.com`
3. Click the **Connect** button.

> **If a previous address is shown,** clear it completely before typing yours.
> Use `Ctrl + A` to select all text, then type your address to replace it.

---

### Step 3 — Accept the Security Warning (if prompted)

AnyConnect may display a security warning that says something like:

> *"Untrusted VPN Server Certificate!"*

This is expected for dCloud lab environments.

1. Click **Connect Anyway** or **Change Setting...** followed by accepting the
   certificate.
2. Some PCs may also prompt with a Windows Security Alert — click **Yes** or
   **Allow** to continue.

---

### Step 4 — Enter Your VPN Credentials

An authentication dialog will appear with two fields:

1. **Username** — Type your **VPN Username** from your credential sheet.
2. **Password** — Type your **VPN Password** from your credential sheet.
3. Click **OK**.

> **Credentials are case-sensitive.** Type them exactly as printed on your
> credential sheet. If copy-pasting, make sure no trailing spaces were
> included.

---

### Step 5 — Verify the VPN Connection

Once authenticated, AnyConnect will minimize to the system tray. You will
know you are connected when:

- A **lock icon** or **AnyConnect shield icon** appears in the system tray
  (bottom-right corner, near the clock).
- If you hover over or click the icon, the status will read **"Connected to
  <your VPN address>"**.

> **Trouble connecting?** Common fixes:
>
> 1. **"Connection attempt has failed"** — Double-check the VPN address for
>    typos. It should match your credential sheet exactly.
> 2. **"Login failed"** — Re-enter your username and password carefully. They
>    are case-sensitive.
> 3. **Still stuck?** Raise your hand for a proctor.

---

## Part 2: Connect to Your Lab Server with VS Code

Now that your VPN is active, you can reach your Ubuntu lab server. You will
use VS Code's **Remote - SSH** extension to work directly on that server.

### Step 6 — Open VS Code

1. Click the **Windows Start menu** (or press the **Windows key**).
2. Type **`Visual Studio Code`** or **`VS Code`** in the search bar.
3. Click **Visual Studio Code** when it appears.

VS Code will open. If this is the first time opening it, you may see a
Welcome tab — you can close it.

---

### Step 7 — Open the Remote-SSH Connection Dialog

1. Press **`Ctrl + Shift + P`** to open the **Command Palette** (a text
   field at the top of the VS Code window).
2. Type **`Remote-SSH: Connect to Host`** in the Command Palette.
3. Click **Remote-SSH: Connect to Host...** from the dropdown list.

> **Don't see it?** The Remote - SSH extension should already be installed. If
> the command does not appear, check that the extension is installed:
> press `Ctrl + Shift + X` to open Extensions, search for **Remote - SSH**,
> and install it if missing. Then try `Ctrl + Shift + P` again.

---

### Step 8 — Enter the SSH Connection String

After selecting **Remote-SSH: Connect to Host...**, you will see a text field
asking for the SSH host.

1. Type the following, replacing `<LAB-SERVER-IP>` with the IP address from
   your credential sheet:

   ```
   cisco@<LAB-SERVER-IP>
   ```

   For example, if your lab server IP is `198.18.134.100`:

   ```
   cisco@198.18.134.100
   ```

2. Press **Enter**.

> **If VS Code asks you to select a platform,** choose **Linux**.

---

### Step 9 — Accept the SSH Fingerprint (First Connection Only)

The first time you connect, VS Code will show a prompt:

> *"Are you sure you want to continue connecting?"*

or

> *"The authenticity of host '...' can't be established."*

1. Click **Continue** (or type `yes` if prompted in a terminal).

This only happens the first time. Future connections will skip this step.

---

### Step 10 — Enter the SSH Password

VS Code will prompt for a password at the top of the window:

1. Type the password: **`C1sco12345`**
2. Press **Enter**.

> **The password will not show characters as you type.** This is normal
> security behavior — just type the full password and press Enter.

> **If the password is rejected,** make sure you typed `C1sco12345` exactly
> (capital C, number 1, lowercase sco, numbers 12345). Try again — VS Code
> will re-prompt.

---

### Step 11 — Wait for VS Code to Set Up the Remote Session

After entering the password, VS Code will:

1. Install a small VS Code server component on the Ubuntu machine (first
   connection only — this may take 30–60 seconds).
2. Open a new VS Code window connected to the remote server.

You will know you are connected when:

- The **bottom-left corner** of VS Code shows a green bar that reads
  **`SSH: <LAB-SERVER-IP>`** (e.g., `SSH: 198.18.134.100`).
- The Explorer panel shows the remote file system (not your local PC).

---

### Step 12 — Open a Terminal on the Lab Server

1. In the VS Code menu bar, click **Terminal** → **New Terminal**
   (or press **`` Ctrl + ` ``** — that's Ctrl plus the backtick key, located
   above the Tab key).
2. A terminal panel will open at the bottom of VS Code.
3. You should see a prompt like:

   ```
   cisco@ubuntu:~$
   ```

**This terminal is running on your lab server, not your local PC.** Any
commands you type here will execute on the Ubuntu server.

---

## Part 3: Using the ContainerLab Extension in VS Code

Your lab topology runs on **ContainerLab** — a tool that spins up network
devices as containers on the Ubuntu server. The **ContainerLab VS Code
extension** is already installed and gives you a visual way to see your lab
nodes, check their status, and connect to them directly from VS Code.

### Step 13 — Open the ContainerLab Sidebar

1. Look at the **Activity Bar** on the far-left side of VS Code (the vertical
   strip of icons).
2. Click the **ContainerLab icon** — it looks like a network/container symbol.
   - If you don't spot it immediately, hover over each icon in the Activity
     Bar until you see the tooltip **"ContainerLab"**.
3. The **ContainerLab sidebar panel** will open, showing your lab topology.

> **Don't see the icon?** Press `Ctrl + Shift + P`, type
> **`ContainerLab: Focus on Topology View`**, and press Enter. This will open
> the panel and add the icon to your Activity Bar.

---

### Step 14 — View Your Lab Topology

In the ContainerLab sidebar, you will see a **tree view** of your deployed
topology:

```
▼ LTRATO-1001
  ├── xrd01          (running)
  ├── xrd02          (running)
  ├── csr-pe01       (running)
  ├── csr-pe02       (running)
  ├── n9k-ce01       (running)
  ├── n9k-ce02       (running)
  ├── client1         (running)
  ├── client2         (running)
  ├── client3         (running)
  └── client4         (running)
```

Each node shows its **status** (running, stopped, etc.).

- **Green / "running"** — The node is healthy and reachable.
- **Red / "stopped"** — The node is down. Raise your hand for a proctor if
  you see this at the start of the lab.

> **All 10 nodes should show as running.** If any node shows a different
> status, do not proceed — notify a proctor.

---

### Step 15 — Connect to a Lab Node

The ContainerLab extension lets you open a terminal session directly to any
lab device — no need to manually SSH or remember IP addresses.

1. In the ContainerLab sidebar, **right-click** on any node
   (e.g., `n9k-ce01`).
2. From the context menu, click **"Connect"** (or **"Attach Shell"** /
   **"SSH"**, depending on the node type).
3. A new terminal tab will open at the bottom of VS Code, connected directly
   to that device.

You can also **single-click** a node to see its details (container name,
image, management IP, interfaces) in the panel.

> **Tip:** You can have multiple device terminals open at once. Each one
> appears as a separate tab in the VS Code terminal panel. Use the dropdown
> arrow on the right side of the terminal panel to switch between them.

---

### Step 16 — Inspect Node Details

To see detailed information about a specific node:

1. **Click on a node** in the ContainerLab sidebar.
2. A details view will show information such as:
   - **Container name** (e.g., `clab-LTRATO-1001-n9k-ce01`)
   - **Image** — the container image running the node
   - **Management IP** — the out-of-band management address
   - **Interfaces** — the links connecting this node to other devices
   - **Status** — current state of the container

> **When is this useful?** If you need to troubleshoot connectivity or verify
> which interfaces connect to which neighbors, the node details view gives
> you that information at a glance without running CLI commands.

---

### Step 17 — View the Topology Graph (Optional)

The extension can display an interactive **graphical view** of your topology:

1. In the ContainerLab sidebar, look for a **graph icon** at the top of the
   panel (or right-click the topology name `LTRATO-1001`).
2. Click **"Show Graph"** or the graph icon.
3. A new VS Code tab will open with a visual diagram of all nodes and their
   links.

You can:
- **Drag nodes** to rearrange the layout.
- **Hover** over a link to see the interface names on each end.
- **Click a node** to highlight its connections.

> This is a read-only visualization — it does not change your lab. Use it to
> orient yourself when the text topology diagram isn't enough.

---

## Part 4: Clone the Lab Repository

> **New to Git?** Read the [Git Primer](Git-Primer.md) for a quick overview of
> what Git is and why we use it in this lab.

The lab files (playbooks, Terraform configs, reference docs) are stored in a GitHub
repository. You need to clone them onto your lab server so you can edit and run them.

### Step 18 — Clone the Repo into Your Home Directory

The Ansible configuration expects lab files to live directly in your home directory
(`/home/cisco/`). Run these commands in your VS Code terminal:

```bash
cd ~
git clone https://github.com/rgoldens/Cisco-Live-2026-Service-as-Code.git .lab-tmp
mv .lab-tmp/* .lab-tmp/.* . 2>/dev/null
rm -rf .lab-tmp
```

> **Why the temp directory?** Git cannot clone into a non-empty directory. Your
> home directory already has files (`.bashrc`, `.ssh/`, etc.), so we clone into
> a temporary folder and move everything out. The `2>/dev/null` suppresses
> harmless warnings about `.` and `..`.

### Step 19 — Verify the Files Are in Place

```bash
ls ~/inventory.yml ~/ansible.cfg ~/ce-access-vlan.yml
```

You should see all three files listed without errors. If you see
`No such file or directory`, re-run the clone commands from Step 18.

### Step 20 — Set Up Git for Your Student Branch

Configure your git identity and create your personal branch. Replace `XX` with
your assigned pod/seat number (e.g., `01`, `12`):

```bash
git config user.name "Student XX"
git config user.email "student@ciscolive.com"
git checkout -b student-XX
```

> **Your branch name is your seat number.** Check your credential sheet or ask
> a proctor if you're unsure which number to use. This branch keeps your work
> separate from other students — you'll push it to GitHub in the final task.

---

## You're In!

Your environment is ready. You are now:

- **VPN connected** to the dCloud lab network via AnyConnect
- **SSH connected** to your Ubuntu lab server via VS Code
- **Working in a terminal** on the lab server
- **ContainerLab extension** available to view, inspect, and connect to your
  lab devices
- **Lab repo cloned** and on your own student branch

**Next step:** Proceed to [Task 1](TASK1.md) to start the lab.

---

## Quick Reference

| What | How |
|------|-----|
| **Reconnect VPN** | Open AnyConnect → type VPN address → Connect → enter credentials |
| **Reconnect VS Code SSH** | `Ctrl + Shift + P` → `Remote-SSH: Connect to Host` → `cisco@<LAB-SERVER-IP>` |
| **SSH password** | `C1sco12345` |
| **Open a terminal** | `Ctrl + `` ` `` (backtick) or Terminal → New Terminal |
| **Check VPN status** | Look for AnyConnect shield icon in system tray (bottom-right) |
| **Disconnect VPN** | Click AnyConnect tray icon → Disconnect (only when done with the lab) |
| **Open ContainerLab panel** | Click the ContainerLab icon in the Activity Bar (far-left) |
| **Connect to a lab node** | Right-click the node in the ContainerLab sidebar → Connect |
| **View topology graph** | Right-click topology name → Show Graph |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| AnyConnect says "Connection attempt has failed" | Verify the VPN address matches your credential sheet exactly. Check for typos or extra spaces. |
| AnyConnect says "Login failed" | Re-type your VPN username and password. They are case-sensitive. |
| VS Code cannot reach the server | Confirm AnyConnect shows "Connected." If not, reconnect the VPN first. |
| VS Code asks for password repeatedly | Make sure you are typing `C1sco12345` exactly — capital C, number 1. |
| VS Code SSH connection times out | The VPN may have disconnected. Check the AnyConnect tray icon and reconnect if needed. |
| "Remote host key has changed" error | Ask a proctor — this can happen if the lab was rebuilt. |
| Terminal shows your local PC, not the server | Check the green SSH indicator in the bottom-left of VS Code. If it's missing, you're not connected remotely — redo Step 7. |
| ContainerLab sidebar is empty | The topology may not be deployed yet. Ask a proctor to verify the lab is running. |
| A node shows "stopped" in ContainerLab | Do not try to restart it yourself. Raise your hand for a proctor. |
| ContainerLab icon not visible in Activity Bar | Press `Ctrl + Shift + P` → type `ContainerLab: Focus on Topology View` → Enter. |
| "Connect" to a node opens but immediately closes | The container may be unhealthy. Try again after 10 seconds. If it persists, ask a proctor. |

> **For any issue not listed here, raise your hand and a proctor will assist
> you.**
