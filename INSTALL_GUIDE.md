# =============================================================================
# INSTALL GUIDE — Start Here
# Service as Code Lab — Cisco Live 2026
#
# This guide walks you through setting up one lab instance from scratch.
# No prior Linux or networking experience required.
# Follow each step in order. Do not skip steps.
# =============================================================================

---

## What You Need Before You Start

### A Linux server (virtual or physical)

You need a Linux machine. This can be:
- A virtual machine (VM) from AWS, Azure, GCP, or your company's internal cloud
- A bare-metal server
- **Not your Mac or Windows laptop** — the lab requires Linux

**Recommended:** Ubuntu 22.04 LTS or Ubuntu 24.04 LTS (this guide assumes Ubuntu)

### Minimum specs for the server

| What | How much | Why |
|------|----------|-----|
| CPUs | 16 | Runs 7 virtual network devices + GitLab |
| Memory (RAM) | 32 GB | The network devices are memory-hungry |
| Disk space | 60 GB free | Stores the device images and GitLab data |

If your server has less than this, the lab will not work properly.

### You need SSH access to the server

You should be able to connect to your server from your laptop using a terminal:

- **Mac:** Open the built-in Terminal app (search "Terminal" in Spotlight)
- **Windows:** Use PowerShell, Windows Terminal, or download [PuTTY](https://www.putty.org/)

You'll need:
- The server's **IP address** (something like `10.1.2.3` or `54.200.100.50`)
- A **username** (usually `ubuntu` or `root`)
- Either a **password** or an **SSH key file** (your IT team will provide this)

### Cisco device images (required)

You need three Cisco virtual device images. These are **not included** in the
lab files because they require a Cisco license. Ask your Cisco account team or
check your CML (Cisco Modeling Labs) instance for:

1. **XRd** — filename looks like: `xrd-control-plane-container-x64.25.1.1.tgz`
2. **CSR1000v** — filename looks like: `csr1000v-universalk9.17.03.06-serial.qcow2`
3. **N9Kv** — filename looks like: `nexus9500v64.10.4.3.F.qcow2`

You'll load these onto the server in Step 5.

---

## Step 1: Connect to Your Server

Open your terminal and type:

```
ssh ubuntu@YOUR-SERVER-IP
```

Replace `YOUR-SERVER-IP` with the actual IP address. For example:

```
ssh ubuntu@54.200.100.50
```

If asked "Are you sure you want to continue connecting?", type `yes` and press Enter.

If asked for a password, type it (you won't see the characters as you type — that's normal).

**You should now see a command prompt** that looks something like:

```
ubuntu@ip-10-0-1-5:~$
```

If you can't connect, check with your IT team that:
- The server is running
- Port 22 (SSH) is open in the firewall
- You have the right IP address and credentials

---

## Step 2: Install Docker

Docker runs the virtual network devices and GitLab. Copy and paste these
commands **one at a time**, pressing Enter after each one:

```
sudo apt-get update
```

This updates the list of available software. Wait for it to finish.

```
sudo apt-get install -y ca-certificates curl gnupg
```

This installs some tools needed for the next steps.

```
sudo install -m 0755 -d /etc/apt/keyrings
```

```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

```
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

```
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```
sudo apt-get update
```

```
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

This installs Docker. It may take 1-2 minutes.

**Verify it worked:**

```
docker --version
```

You should see something like `Docker version 27.x.x`. If you see "command not
found", something went wrong — re-read the steps above.

Now let your user run Docker without typing `sudo` every time:

```
sudo usermod -aG docker $USER
```

**Important:** Log out and log back in for this to take effect:

```
exit
```

Then reconnect:

```
ssh ubuntu@YOUR-SERVER-IP
```

Verify you can run Docker without sudo:

```
docker ps
```

You should see an empty table (no containers running yet). If you get a
"permission denied" error, make sure you logged out and back in.

---

## Step 3: Install the Other Required Tools

### Install Python

```
sudo apt-get install -y python3 python3-pip python3-venv
```

Verify:

```
python3 --version
```

You should see `Python 3.10` or higher.

### Install containerlab

containerlab is the tool that creates the virtual network topology.

```
sudo bash -c "$(curl -sL https://get.containerlab.dev)"
```

Verify:

```
containerlab version
```

You should see version `0.55` or higher.

### Install Terraform

```
sudo apt-get install -y software-properties-common gnupg
```

```
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

```
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

```
sudo apt-get update && sudo apt-get install -y terraform
```

Verify:

```
terraform --version
```

You should see `Terraform v1.5` or higher.

### Install Git

Git is probably already installed, but just in case:

```
sudo apt-get install -y git
```

---

## Step 4: Apply Kernel Settings

The XRd (IOS-XR) devices need special Linux kernel settings. Run these two
commands:

```
sudo sysctl -w fs.inotify.max_user_instances=64000
sudo sysctl -w fs.inotify.max_user_watches=64000
```

Make the settings survive reboots:

```
echo -e "fs.inotify.max_user_instances=64000\nfs.inotify.max_user_watches=64000" | sudo tee -a /etc/sysctl.conf
```

Verify:

```
sysctl fs.inotify.max_user_instances
```

You should see `fs.inotify.max_user_instances = 64000`.

---

## Step 5: Load the Cisco Device Images

This is the most involved step. You need to get the three Cisco images onto
your server and load them into Docker.

### 5a: Transfer image files to the server

If the image files are on your laptop, use `scp` to copy them to the server.
Open a **new terminal window on your laptop** (not the server) and run:

```
scp /path/to/xrd-control-plane-container-x64.25.1.1.tgz ubuntu@YOUR-SERVER-IP:~/
scp /path/to/csr1000v-universalk9.17.03.06-serial.qcow2 ubuntu@YOUR-SERVER-IP:~/
scp /path/to/nexus9500v64.10.4.3.F.qcow2 ubuntu@YOUR-SERVER-IP:~/
```

Replace `/path/to/` with the actual location of the files on your laptop.
This may take several minutes depending on file size and network speed.

### 5b: Load the XRd image

Go back to your **server terminal** and run:

```
docker load -i ~/xrd-control-plane-container-x64.25.1.1.tgz
```

Wait for it to finish. Then verify:

```
docker images | grep xrd
```

You should see `ios-xr/xrd-control-plane` with tag `25.1.1`.

### 5c: Build the CSR1000v and N9Kv images using vrnetlab

The CSR and N9Kv images are `.qcow2` disk images that need to be converted into
Docker images using a tool called [vrnetlab](https://github.com/hellt/vrnetlab).

```
git clone https://github.com/hellt/vrnetlab.git ~/vrnetlab
```

**Build the CSR1000v image:**

```
cd ~/vrnetlab/csr
cp ~/csr1000v-universalk9.17.03.06-serial.qcow2 .
make docker-image
```

This takes 5-10 minutes. When done, verify:

```
docker images | grep csr
```

You should see an image like `vrnetlab/cisco_csr1000v`.

**Build the N9Kv image:**

```
cd ~/vrnetlab/n9kv
cp ~/nexus9500v64.10.4.3.F.qcow2 .
make docker-image
```

This also takes 5-10 minutes. Verify:

```
docker images | grep n9kv
```

You should see an image like `vrnetlab/cisco_n9kv`.

### 5d: Pull the remaining images

```
docker pull alpine:latest
docker pull gitlab/gitlab-ce:latest
docker pull gitlab/gitlab-runner:latest
```

### 5e: Write down your image names

Run this command to see all loaded images:

```
docker images
```

**Write down the exact image names and tags** for XRd, CSR, and N9Kv. You'll
need them in the next step to make sure the lab topology file matches.

---

## Step 6: Download the Lab Files

```
cd ~
git clone https://github.com/rgoldens/Cisco-Live-2026-Service-as-Code.git sac-lab
cd sac-lab
```

Verify you see the lab files:

```
ls
```

You should see: `ansible/`, `configs/`, `gitlab/`, `Makefile`, `README.md`,
`services/`, `terraform/`, `topology/`, and other files.

### Update the topology file with your image names

The topology file needs to match the exact Docker image names on your server.
Open the file:

```
nano topology/sac-lab.yml
```

Look for lines that say `image:` and make sure they match what you saw in
Step 5e. For example:

```yaml
image: ios-xr/xrd-control-plane:25.1.1
image: vrnetlab/cisco_csr1000v:17.03.06
image: vrnetlab/cisco_n9kv:10.4.3.F
```

Update the tags if yours are different.

To save and exit nano: press `Ctrl+O`, then `Enter`, then `Ctrl+X`.

---

## Step 7: Install Lab Dependencies

```
cd ~/sac-lab
```

Install Python packages:

```
make pip-install
```

Install Ansible network modules:

```
make ansible-install
```

Initialize Terraform:

```
make tf-init
```

Each command should finish without errors. If you see red error messages,
something from the earlier steps may be missing.

---

## Step 8: Start the Lab

This is the moment of truth. Deploy the virtual network:

```
make deploy
```

This starts all 7 virtual network devices. **Wait 10 minutes** for everything
to boot. The N9Kv devices are the slowest — they can take up to 8 minutes.

After waiting, check that everything is running:

```
make inspect
```

You should see a table with **7 nodes**, all showing status **"running"** and
each with an IP address in the `172.20.20.x` range.

**If you see fewer than 7 nodes running**, wait a few more minutes and run
`make inspect` again. Some devices are slow to start.

---

## Step 9: Start GitLab

GitLab provides the web-based CI/CD pipeline for the lab exercises.

```
make gitlab-up
```

**Wait 3-5 minutes** for GitLab to fully start. Check if it's ready:

```
docker inspect --format='{{.State.Health.Status}}' gitlab-ce
```

Keep running this command every 30 seconds until it says `healthy`.
When it says `healthy`, run the setup:

```
make gitlab-setup
```

This creates the student account, project, and CI/CD runner. It should end
with a message saying "GitLab setup complete!"

---

## Step 10: Verify Everything Works

### Check the network devices

Try connecting to one of the routers:

```
ssh clab@172.20.20.2
```

(Use the actual IP from `make inspect` — it may be different.)

Password: `clab@123`

If you see a router prompt, type `exit` to disconnect. The lab is working.

### Check GitLab

Open a web browser and go to:

```
http://YOUR-SERVER-IP:8080
```

You should see a GitLab login page. Log in with:
- Username: `student`
- Password: `CiscoLive2026!`

You should see a project called `sac-lab`.

---

## You're Done

The lab is fully set up. Here's a summary of what's running:

| What | Where | How to access |
|------|-------|---------------|
| 7 network devices | Docker containers | `ssh` to their IPs (see `make inspect`) |
| GitLab web UI | Docker container | `http://YOUR-SERVER-IP:8080` |
| Lab files | `~/sac-lab/` | `cd ~/sac-lab` on the server |

### Quick reference — useful commands

| What you want to do | Command |
|---------------------|---------|
| See all running devices | `make inspect` |
| See all available commands | `make help` |
| Deploy L3VPN services | `make provision-l3vpn` |
| Deploy EVPN services | `make provision-evpn` |
| Run validation checks | `make validate` |
| Restart GitLab | `make gitlab-down` then `make gitlab-up` |

### If something goes wrong

| Problem | What to do |
|---------|------------|
| Can't SSH to a device | Wait a few more minutes — some devices take 8-10 min to boot |
| `make deploy` failed | Run `make destroy` then `make deploy` again |
| GitLab won't load | Run `docker logs gitlab-ce` and wait — first boot is slow |
| Everything is broken | Run `make destroy && make deploy` to start fresh (wait 10 min) |
| Need more help | See `INSTRUCTOR_CHECKLIST.md` for detailed troubleshooting |

### To shut everything down when you're done

```
cd ~/sac-lab
make gitlab-purge
make destroy
make clean
```

This stops all containers and removes temporary files. Your lab files in
`~/sac-lab/` are kept — only the running devices are removed.
