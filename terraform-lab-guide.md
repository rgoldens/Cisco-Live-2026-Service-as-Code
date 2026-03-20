# Terraform Lab Guide — LTRATO-1001

## Infrastructure as Code with Terraform and Cisco IOS XE

---

## What Is Terraform?

Terraform is an open-source Infrastructure as Code (IaC) tool created by HashiCorp. It
lets you define your infrastructure — servers, networks, routers, firewalls, cloud
resources — in plain text configuration files, and then deploy, modify, or destroy that
infrastructure with a single command.

### Why use Terraform instead of doing it manually?

| Problem with manual configuration | How Terraform solves it |
|---|---|
| Hard to reproduce — "works on my machine" | The config file **is** the environment. Anyone with the file gets the same result |
| Easy to forget what you changed | Every change is tracked in code and version-controlled in git |
| Risky to modify — hard to know what will change | `terraform plan` shows you exactly what will change **before** you apply anything |
| Hard to clean up — did I delete everything? | `terraform destroy` removes every resource Terraform created, nothing more, nothing less |
| Snowflake servers — each one slightly different | Idempotent — run `apply` 10 times, you always end up with the same state |

In a network engineering context, Terraform is increasingly used to:

- Provision virtual routers and network infrastructure (exactly what this lab does)
- Configure network devices via RESTCONF, NETCONF, or APIs
- Manage cloud networking (VPCs, subnets, security groups)
- Orchestrate lab environments for testing and CI/CD pipelines

### The Terraform workflow

```
Write config  →  terraform init  →  terraform plan  →  terraform apply  →  terraform destroy
(define what      (download          (preview what      (make it real)      (clean it all up)
 you want)         providers)         will change)
```

### Key concepts

**Provider** — a plugin that knows how to talk to a specific platform. This lab uses two:
- `kreuzwerker/docker` — creates Docker containers and networks
- `CiscoDevNet/iosxe` — configures Cisco IOS XE devices via RESTCONF

**Resource** — a single piece of infrastructure managed by Terraform (a container, a
network, a router interface, a hostname).

**State file** (`terraform.tfstate`) — Terraform's memory. It records what it has
deployed so it knows what to add, change, or remove on the next run.

**Module** — a reusable group of resources. This lab uses two modules:
- `docker-infra` — handles the Docker network, storage volume, and containers
- `iosxe-config` — handles IOS XE device configuration via RESTCONF

---

## Lab Topology

This Terraform lab runs **independently** of the main ContainerLab topology. It uses a
separate Docker bridge network and does not interfere with the LTRATO-1001 nodes.

```
  ┌─────────────────────────────────────────────────────────┐
  │  Docker bridge: terraform-net  (172.20.21.0/24)         │
  │                                                         │
  │  ┌──────────────────┐   ┌────────────┐  ┌────────────┐  │
  │  │  csr-terraform   │   │  linux-    │  │  linux-    │  │
  │  │  IOS XE 16.12    │   │ terraform1 │  │ terraform2 │  │
  │  │  172.20.21.10    │   │ 172.20.21.20│ │ 172.20.21.21│  │
  │  └──────────────────┘   └────────────┘  └────────────┘  │
  └─────────────────────────────────────────────────────────┘
```

| Container | Image | IP | Role |
|---|---|---|---|
| `csr-terraform` | `vrnetlab/vr-csr:16.12.05` | `172.20.21.10` | Cisco IOS XE router — Terraform target |
| `linux-terraform1` | `ghcr.io/hellt/network-multitool` | `172.20.21.20` | Linux client |
| `linux-terraform2` | `ghcr.io/hellt/network-multitool` | `172.20.21.21` | Linux client |

**Terraform also configures the CSR via RESTCONF:**
- Hostname → `csr-terraform`
- Loopback0 → `10.99.99.1/32` (description: "Managed by Terraform")

---

## Prerequisites

The lab server already has everything pre-installed and initialized:

| Tool | Version | Location |
|---|---|---|
| Terraform | v1.14.7 | `/usr/bin/terraform` |
| Docker | 27.5.1 | `/usr/bin/docker` |
| `sshpass` | — | `/usr/bin/sshpass` |
| `kreuzwerker/docker` provider | 3.9.0 | `~/.terraform.d/plugins/` |
| `CiscoDevNet/iosxe` provider | 0.16.0 | `~/.terraform.d/plugins/` |

> **Note:** The server has no internet access to the Terraform registry. Providers are
> pre-installed in a local filesystem mirror. `terraform init` reads from there — no
> download needed.

All Terraform files are in: **`~/terraform-lab/terraform/`**

---

## Part 1 — Explore the Configuration

Before deploying anything, take a few minutes to understand what Terraform will build.

### Navigate to the working directory

```bash
cd ~/terraform-lab/terraform
```

### Look at the file structure

Run `ls -la` to see the full directory listing with permissions and sizes:

```bash
ls -la
```

```
total 100
drwxrwxr-x 4 cisco cisco  4096 Mar 20 18:50 .
drwxrwxr-x 3 cisco cisco  4096 Mar 19 22:32 ..
drwxrwxr-x 4 cisco cisco  4096 Mar 19 22:32 .terraform
-rw-r--r-- 1 cisco cisco  1513 Mar 19 22:33 .terraform.lock.hcl
-rw-r--r-- 1 cisco cisco  2331 Mar 20 18:51 main.tf
drwxrwxr-x 4 cisco cisco  4096 Mar 19 22:32 modules
-rw-r--r-- 1 cisco cisco   807 Mar 19 22:32 outputs.tf
-rw-rw-r-- 1 cisco cisco   182 Mar 20 19:15 terraform.tfstate
-rw-rw-r-- 1 cisco cisco 28878 Mar 20 18:48 terraform.tfstate.1774032510.backup
-rw-rw-r-- 1 cisco cisco 28803 Mar 20 19:15 terraform.tfstate.backup
-rw-r--r-- 1 cisco cisco  3357 Mar 19 22:32 variables.tf
```

Now run `ls modules/` to see what modules are available:

```bash
ls modules/
```

```
docker-infra
iosxe-config
```

### Read the root module

```bash
cat main.tf
```

This file ties the two modules together. Notice:
- The `provider "iosxe"` block points at the CSR IP (`172.20.21.10`) and uses `protocol = "restconf"`
- `module "iosxe_config"` has `depends_on = [module.docker_infra]` — Terraform will not
  attempt any RESTCONF calls until the Docker infrastructure (and CSR readiness) is complete

### Read the variables

```bash
cat variables.tf
```

All values have defaults — no user input required. Key defaults:

| Variable | Default |
|---|---|
| `csr_ip` | `172.20.21.10` |
| `csr_username` / `csr_password` | `admin` / `admin` |
| `csr_hostname` | `csr-terraform` |
| `loopback_ip` | `10.99.99.1` |
| `linux1_ip` / `linux2_ip` | `172.20.21.20` / `172.20.21.21` |

### Read the docker-infra module

```bash
cat modules/docker-infra/main.tf
```

Find the `null_resource.csr_ready` block. This is the most interesting part — a
provisioner that polls RESTCONF every 10 seconds (up to 15 minutes) until the CSR has
fully booted, then enables RESTCONF via SSH. The CSR takes approximately 7-8 minutes to
complete its cold boot from a fresh volume.

### Read the iosxe-config module

```bash
cat modules/iosxe-config/main.tf
```

Two resources:
- `iosxe_system.this` — sets the hostname via RESTCONF
- `iosxe_interface_loopback.lo0` — creates Loopback0 via RESTCONF

### Read the outputs

```bash
cat outputs.tf
```

After `terraform apply`, these values will be printed to the terminal.

### Initialize Terraform

`terraform init` prepares the working directory — it reads the provider requirements and
links them from the local filesystem mirror. Since providers are pre-installed, this is
instantaneous (no download).

```bash
terraform init
```

Output:
```
Initializing the backend...
Initializing modules...
Initializing provider plugins...
- Reusing previous version of kreuzwerker/docker from the dependency lock file
- Reusing previous version of ciscodevnet/iosxe from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed ciscodevnet/iosxe v0.16.0
- Using previously-installed hashicorp/null v3.2.4
- Using previously-installed kreuzwerker/docker v3.9.0

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

> If you see `Terraform has been successfully initialized!` you are ready to proceed.

---

## Part 2 — Plan and Deploy

### Confirm nothing is running yet

Before deploying, verify the Docker environment is clean:

```bash
docker ps --filter name=terraform
```

Output — no containers:
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```bash
docker network ls --filter name=terraform
```

Output — no terraform network:
```
NETWORK ID   NAME      DRIVER    SCOPE
```

### Preview the deployment with terraform plan

`terraform plan` is a dry run. It compares your configuration against the current state
and shows you exactly what will be created, changed, or destroyed — **without touching
anything**.

```bash
terraform plan
```

Output:
```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.docker_infra.docker_container.csr will be created
  + resource "docker_container" "csr" {
      + image                                       = "vrnetlab/vr-csr:16.12.05"
      + name                                        = "csr-terraform"
      + privileged                                  = true
      + restart                                     = "no"
      ...
      + networks_advanced {
          + ipv4_address = "172.20.21.10"
          + name         = "terraform-net"
        }
      + volumes {
          + container_path = "/mnt/flash"
          + volume_name    = "csr-terraform-storage"
        }
    }

  # module.docker_infra.docker_container.linux1 will be created
  + resource "docker_container" "linux1" {
      + image = "ghcr.io/hellt/network-multitool"
      + name  = "linux-terraform1"
      ...
      + networks_advanced {
          + ipv4_address = "172.20.21.20"
          + name         = "terraform-net"
        }
    }

  # module.docker_infra.docker_container.linux2 will be created
  + resource "docker_container" "linux2" {
      + image = "ghcr.io/hellt/network-multitool"
      + name  = "linux-terraform2"
      ...
      + networks_advanced {
          + ipv4_address = "172.20.21.21"
          + name         = "terraform-net"
        }
    }

  # module.docker_infra.docker_network.terraform_net will be created
  + resource "docker_network" "terraform_net" {
      + driver = "bridge"
      + name   = "terraform-net"
      + ipam_config {
          + subnet = "172.20.21.0/24"
        }
    }

  # module.docker_infra.docker_volume.csr_storage will be created
  + resource "docker_volume" "csr_storage" {
      + name = "csr-terraform-storage"
    }

  # module.docker_infra.null_resource.csr_ready will be created
  + resource "null_resource" "csr_ready" {
      + triggers = {
          + "csr_container_id" = (known after apply)
        }
    }

  # module.iosxe_config.iosxe_interface_loopback.lo0 will be created
  + resource "iosxe_interface_loopback" "lo0" {
      + description       = "Managed by Terraform"
      + ipv4_address      = "10.99.99.1"
      + ipv4_address_mask = "255.255.255.255"
      + name              = 0
    }

  # module.iosxe_config.iosxe_system.this will be created
  + resource "iosxe_system" "this" {
      + hostname = "csr-terraform"
    }

Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + csr_hostname = "csr-terraform"
  + csr_ip       = "172.20.21.10"
  + linux1_ip    = "172.20.21.20"
  + linux2_ip    = "172.20.21.21"
  + loopback0    = "10.99.99.1/255.255.255.255"

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

The 8 resources are:
1. `module.docker_infra.docker_network.terraform_net` — the bridge network
2. `module.docker_infra.docker_volume.csr_storage` — CSR persistent storage volume
3. `module.docker_infra.docker_container.csr` — the CSR container
4. `module.docker_infra.docker_container.linux1` — linux-terraform1
5. `module.docker_infra.docker_container.linux2` — linux-terraform2
6. `module.docker_infra.null_resource.csr_ready` — the readiness + RESTCONF provisioner
7. `module.iosxe_config.iosxe_system.this` — CSR hostname via RESTCONF
8. `module.iosxe_config.iosxe_interface_loopback.lo0` — Loopback0 via RESTCONF

> **Nothing has been deployed yet.** `plan` is always safe to run.

### Deploy with terraform apply

```bash
terraform apply -auto-approve
```

> In the lab, use `-auto-approve` to skip the confirmation prompt. In production
> environments, always omit this flag and review the plan before typing `yes`.

**What happens next (in order):**

1. Docker network `terraform-net` is created (2s)
2. CSR storage volume is created (0s)
3. All three containers start simultaneously (1s each)
4. The `null_resource.csr_ready` provisioner begins — it polls RESTCONF every 10 seconds
   while waiting for the CSR to boot. **This takes approximately 7-8 minutes.**
   Do not interrupt it.
5. Once the CSR is ready and RESTCONF is enabled, the iosxe provider connects and
   applies the hostname and Loopback0 in about 1 second each.

While waiting, open a second terminal and watch the CSR boot progress:

```bash
docker logs -f csr-terraform
```

Look for this line to confirm the CSR has finished booting:
```
Startup complete in: 0:07:XX
```

Press `Ctrl+C` to stop following the logs.

Output (key lines — the `null_resource.csr_ready` loop output is suppressed because
the provisioner uses a sensitive variable for the CSR password):

```
module.docker_infra.docker_volume.csr_storage: Creating...
module.docker_infra.docker_network.terraform_net: Creating...
module.docker_infra.docker_volume.csr_storage: Creation complete after 0s [id=csr-terraform-storage]
module.docker_infra.docker_network.terraform_net: Creation complete after 2s [id=d1921eb1ab7e...]
module.docker_infra.docker_container.linux1: Creating...
module.docker_infra.docker_container.csr: Creating...
module.docker_infra.docker_container.linux2: Creating...
module.docker_infra.docker_container.linux1: Creation complete after 1s [id=cf2b394afde8...]
module.docker_infra.docker_container.linux2: Creation complete after 1s [id=5d90d3868ae6...]
module.docker_infra.docker_container.csr: Creation complete after 1s [id=8fdc981b800e...]
module.docker_infra.null_resource.csr_ready: Creating...
module.docker_infra.null_resource.csr_ready: Provisioning with 'local-exec'...
module.docker_infra.null_resource.csr_ready (local-exec): (output suppressed due to sensitive value in config)
module.docker_infra.null_resource.csr_ready: Still creating... [00m10s elapsed]
module.docker_infra.null_resource.csr_ready: Still creating... [00m20s elapsed]
...
module.docker_infra.null_resource.csr_ready: Still creating... [07m30s elapsed]
module.docker_infra.null_resource.csr_ready: Creation complete after 7m39s [id=8057386960410116714]
module.iosxe_config.iosxe_interface_loopback.lo0: Creating...
module.iosxe_config.iosxe_system.this: Creating...
module.iosxe_config.iosxe_interface_loopback.lo0: Creation complete after 0s [id=Cisco-IOS-XE-native:native/interface/Loopback=0]
module.iosxe_config.iosxe_system.this: Creation complete after 1s [id=Cisco-IOS-XE-native:native]

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

csr_hostname = "csr-terraform"
csr_ip = "172.20.21.10"
linux1_ip = "172.20.21.20"
linux2_ip = "172.20.21.21"
loopback0 = "10.99.99.1/255.255.255.255"
```

---

## Part 3 — Verify the Deployment

### Check running containers

```bash
docker ps --filter name=terraform --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

Output — all three containers running:
```
CONTAINER ID   IMAGE                             STATUS                   NAMES
5d90d3868ae6   ghcr.io/hellt/network-multitool   Up 7 minutes             linux-terraform2
cf2b394afde8   ghcr.io/hellt/network-multitool   Up 7 minutes             linux-terraform1
8fdc981b800e   vrnetlab/vr-csr:16.12.05          Up 7 minutes (healthy)   csr-terraform
```

The CSR shows `(healthy)` — the vrnetlab healthcheck confirms the IOS XE VM is fully
booted and responding.

### Check container IP addresses

```bash
docker inspect csr-terraform      --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect linux-terraform1   --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect linux-terraform2   --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Output:
```
172.20.21.10
172.20.21.20
172.20.21.21
```

### Check terraform output

```bash
terraform output
```

Output:
```
csr_hostname = "csr-terraform"
csr_ip = "172.20.21.10"
linux1_ip = "172.20.21.20"
linux2_ip = "172.20.21.21"
loopback0 = "10.99.99.1/255.255.255.255"
```

### Verify RESTCONF is responding on the CSR

```bash
curl -sk -u admin:admin \
  -H "Accept: application/yang-data+json" \
  https://172.20.21.10/restconf/data/Cisco-IOS-XE-native:native/hostname
```

Output — the hostname Terraform configured:
```json
{
  "Cisco-IOS-XE-native:hostname": "csr-terraform"
}
```

### Verify Loopback0 exists on the CSR

```bash
curl -sk -u admin:admin \
  -H "Accept: application/yang-data+json" \
  "https://172.20.21.10/restconf/data/Cisco-IOS-XE-native:native/interface/Loopback=0"
```

Output:
```json
{
  "Cisco-IOS-XE-native:Loopback": {
    "name": 0,
    "description": "Managed by Terraform",
    "ip": {
      "address": {
        "primary": {
          "address": "10.99.99.1",
          "mask": "255.255.255.255"
        }
      }
    }
  }
}
```

### SSH into the CSR and verify

```bash
ssh -o KexAlgorithms=+diffie-hellman-group14-sha1 \
    -o HostKeyAlgorithms=+ssh-rsa \
    admin@172.20.21.10
```

Password: `admin`

Once logged in:

```
csr-terraform#show running-config | include hostname
hostname csr-terraform

csr-terraform#show interfaces Loopback0
Loopback0 is up, line protocol is up
  Hardware is Loopback
  Description: Managed by Terraform
  Internet address is 10.99.99.1/32
  MTU 1514 bytes, BW 8000000 Kbit/sec, DLY 5000 usec,
     reliability 255/255, txload 1/255, rxload 1/255
  Encapsulation LOOPBACK, loopback not set
  Keepalive set (10 sec)
  Last input 00:00:08, output never, output hang never
  Last clearing of "show interface" counters never
  Input queue: 0/75/0/0 (size/max/drops/flushes); Total output drops: 0
  Queueing strategy: fifo
  Output queue: 0/0 (size/max)
  5 minute input rate 0 bits/sec, 0 packets/sec
  5 minute output rate 0 bits/sec, 0 packets/sec
     0 packets input, 0 bytes, 0 no buffer
     Received 0 broadcasts (0 IP multicasts)
     0 runts, 0 giants, 0 throttles
     0 input errors, 0 CRC, 0 frame, 0 overrun, 0 ignored, 0 abort
     4 packets output, 330 bytes, 0 underruns
```

Type `exit` to leave the CSR.

### SSH into a Linux container and verify

```bash
ssh root@172.20.21.20
```

Password: `root`

```bash
hostname
ip addr show eth0
```

Output:
```
cf2b394afde8

59: eth0@if60: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:14:15:14 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.20.21.20/24 brd 172.20.21.255 scope global eth0
       valid_lft forever preferred_lft forever
```

> The hostname shown is the container ID — this is normal for Docker containers that
> have not had their hostname explicitly set in the Terraform config.

Type `exit` to leave.

---

## Part 4 — Infrastructure Drift

**Infrastructure drift** is what happens when the real state of your infrastructure no
longer matches the state Terraform expects. This can happen when:

- Someone manually deletes or modifies a resource outside of Terraform
- A container crashes and is removed by Docker
- An engineer makes a "quick fix" directly on a device instead of through the IaC pipeline

Terraform's ability to detect and correct drift is one of its most powerful features.

### Step 1 — Simulate drift: manually delete a container

Without touching Terraform, directly remove `linux-terraform2` using Docker:

```bash
docker rm -f linux-terraform2
```

Output:
```
linux-terraform2
```

### Step 2 — Confirm it is gone

```bash
docker ps --filter name=terraform --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

Output — only two containers remain:
```
CONTAINER ID   IMAGE                             STATUS                   NAMES
cf2b394afde8   ghcr.io/hellt/network-multitool   Up 8 minutes             linux-terraform1
8fdc981b800e   vrnetlab/vr-csr:16.12.05          Up 8 minutes (healthy)   csr-terraform
```

`linux-terraform2` is missing. The infrastructure has **drifted** from the Terraform
configuration.

### Step 3 — Detect drift with terraform plan

Run `terraform plan` to let Terraform compare the real world against its state:

```bash
terraform plan
```

Output:
```
module.docker_infra.docker_volume.csr_storage: Refreshing state... [id=csr-terraform-storage]
module.docker_infra.docker_network.terraform_net: Refreshing state... [id=d1921eb1ab7e...]
module.docker_infra.docker_container.linux1: Refreshing state... [id=cf2b394afde8...]
module.docker_infra.docker_container.linux2: Refreshing state... [id=5d90d3868ae6...]
module.docker_infra.docker_container.csr: Refreshing state... [id=8fdc981b800e...]
module.docker_infra.null_resource.csr_ready: Refreshing state... [id=8057386960410116714]
module.iosxe_config.iosxe_interface_loopback.lo0: Refreshing state... [id=Cisco-IOS-XE-native:native/interface/Loopback=0]
module.iosxe_config.iosxe_system.this: Refreshing state... [id=Cisco-IOS-XE-native:native]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # module.docker_infra.docker_container.linux2 will be created
  + resource "docker_container" "linux2" {
      + image = "ghcr.io/hellt/network-multitool"
      + name  = "linux-terraform2"
      ...
      + networks_advanced {
          + ipv4_address = "172.20.21.21"
          + name         = "terraform-net"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

> **Terraform found the drift.** It knows `linux-terraform2` should exist (it's in the
> state file) but doesn't (it's not running). Only the missing container needs to be
> re-created — everything else matches.

### Step 4 — Remediate drift with terraform apply

```bash
terraform apply -auto-approve
```

Because RESTCONF is already active on the CSR, only the missing container is re-created.
The entire remediation completes in under 1 second:

```
module.docker_infra.docker_container.linux2: Creating...
module.docker_infra.docker_container.linux2: Creation complete after 0s [id=a3d3c8160a11...]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

csr_hostname = "csr-terraform"
csr_ip = "172.20.21.10"
linux1_ip = "172.20.21.20"
linux2_ip = "172.20.21.21"
loopback0 = "10.99.99.1/255.255.255.255"
```

### Step 5 — Confirm all three containers are running again

```bash
docker ps --filter name=terraform --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

Output — all three back:
```
CONTAINER ID   IMAGE                             STATUS                   NAMES
a3d3c8160a11   ghcr.io/hellt/network-multitool   Up 8 seconds             linux-terraform2
cf2b394afde8   ghcr.io/hellt/network-multitool   Up 8 minutes             linux-terraform1
8fdc981b800e   vrnetlab/vr-csr:16.12.05          Up 8 minutes (healthy)   csr-terraform
```

Note that `linux-terraform2` shows a fresh uptime (8 seconds) while the others are still
at their original age — it was just recreated.

### Step 6 — Verify terraform plan now shows no changes

```bash
terraform plan
```

Output:
```
module.docker_infra.docker_volume.csr_storage: Refreshing state... [id=csr-terraform-storage]
module.docker_infra.docker_network.terraform_net: Refreshing state... [id=d1921eb1ab7e...]
module.docker_infra.docker_container.linux1: Refreshing state... [id=cf2b394afde8...]
module.docker_infra.docker_container.csr: Refreshing state... [id=8fdc981b800e...]
module.docker_infra.docker_container.linux2: Refreshing state... [id=a3d3c8160a11...]
module.docker_infra.null_resource.csr_ready: Refreshing state... [id=8057386960410116714]
module.iosxe_config.iosxe_interface_loopback.lo0: Refreshing state... [id=Cisco-IOS-XE-native:native/interface/Loopback=0]
module.iosxe_config.iosxe_system.this: Refreshing state... [id=Cisco-IOS-XE-native:native]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

This is the Terraform "all clear" — the real world matches the desired state exactly.

---

## Part 5 — Tear Down

At the end of this section, **tear down the Terraform environment completely** before
moving on to the ContainerLab section. The CSR uses significant RAM (~3.5 GiB) that the
ContainerLab topology needs.

### Destroy all resources

```bash
terraform destroy -auto-approve
```

> In the lab, use `-auto-approve` to skip the confirmation prompt. In production,
> always omit this flag and review the destruction plan carefully before confirming.

Terraform destroys resources in the correct dependency order — IOS XE config first, then
containers, then the network and volume:

```
module.iosxe_config.iosxe_interface_loopback.lo0: Destroying... [id=Cisco-IOS-XE-native:native/interface/Loopback=0]
module.iosxe_config.iosxe_system.this: Destroying... [id=Cisco-IOS-XE-native:native]
module.iosxe_config.iosxe_interface_loopback.lo0: Destruction complete after 3s
module.iosxe_config.iosxe_system.this: Destruction complete after 8s
module.docker_infra.null_resource.csr_ready: Destroying... [id=8057386960410116714]
module.docker_infra.null_resource.csr_ready: Destruction complete after 0s
module.docker_infra.docker_container.linux2: Destroying... [id=a3d3c8160a11...]
module.docker_infra.docker_container.linux1: Destroying... [id=cf2b394afde8...]
module.docker_infra.docker_container.csr: Destroying... [id=8fdc981b800e...]
module.docker_infra.docker_container.linux1: Destruction complete after 1s
module.docker_infra.docker_container.linux2: Destruction complete after 1s
module.docker_infra.docker_container.csr: Destruction complete after 1s
module.docker_infra.docker_volume.csr_storage: Destroying... [id=csr-terraform-storage]
module.docker_infra.docker_network.terraform_net: Destroying... [id=d1921eb1ab7e...]
module.docker_infra.docker_volume.csr_storage: Destruction complete after 2s
module.docker_infra.docker_network.terraform_net: Destruction complete after 2s

Destroy complete! Resources: 8 destroyed.
```

### Verify everything is cleaned up

```bash
docker ps --filter name=terraform --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

Output — no containers:
```
CONTAINER ID   IMAGE     STATUS    NAMES
```

```bash
docker network ls --filter name=terraform
```

Output — no terraform network:
```
NETWORK ID   NAME      DRIVER    SCOPE
```

```bash
docker volume ls --filter name=terraform
```

Output — no terraform volume:
```
DRIVER    VOLUME NAME
```

### Confirm Terraform state is empty

```bash
terraform show
```

Output:
```
The state file is empty. No resources are represented.
```

Everything is clean. You are ready to move on to the ContainerLab section.

---

## Quick Reference

| Command | What it does |
|---|---|
| `terraform init` | Initialize working directory, link providers |
| `terraform plan` | Preview changes — safe, makes no modifications |
| `terraform apply -auto-approve` | Deploy or update infrastructure to match config |
| `terraform destroy -auto-approve` | Remove all Terraform-managed resources |
| `terraform show` | Display current state in human-readable form |
| `terraform output` | Print output values |
| `docker ps --filter name=terraform` | Check which terraform containers are running |
| `docker logs -f csr-terraform` | Follow CSR boot log |
| `curl -sk -u admin:admin -H "Accept: application/yang-data+json" https://172.20.21.10/restconf/...` | Query CSR via RESTCONF |

---

## Summary

In this lab you:

1. Explored a modular Terraform configuration managing both Docker infrastructure and
   Cisco IOS XE device configuration from a single `terraform apply`
2. Used `terraform plan` to safely preview changes before applying them
3. Deployed a three-container network lab including a Cisco CSR1000v router configured
   entirely via Terraform and RESTCONF
4. Verified the deployment through Docker, RESTCONF API queries, and direct SSH
5. Simulated infrastructure drift by manually deleting a container outside of Terraform
6. Used `terraform plan` to detect the drift and `terraform apply` to remediate it in
   under 1 second
7. Performed a clean teardown with `terraform destroy` and verified all resources were removed

The key takeaway: with IaC, your infrastructure is **defined, versioned, and repeatable**.
Drift is detectable and correctable. The same configuration file that built this lab today
will build the exact same lab tomorrow, next week, or on a completely different server.
