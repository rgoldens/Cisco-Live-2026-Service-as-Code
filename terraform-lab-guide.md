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

```bash
ls -la
```

Expected output:
```
main.tf
modules/
outputs.tf
terraform.tfstate
variables.tf
```

```bash
ls modules/
```

```
docker-infra/
iosxe-config/
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

Expected output:
```
Initializing the backend...
Initializing modules...
Initializing provider plugins...
- Reusing previous version of kreuzwerker/docker from the dependency lock file
- Reusing previous version of CiscoDevNet/iosxe from the dependency lock file
- Reusing previous version of hashicorp/null from the dependency lock file
- Using previously-installed kreuzwerker/docker v3.9.0
- Using previously-installed CiscoDevNet/iosxe v0.16.0
- Using previously-installed hashicorp/null v3.x.x

Terraform has been successfully initialized!
```

> If you see `Terraform has been successfully initialized!` you are ready to proceed.

---

## Part 2 — Plan and Deploy

### Confirm nothing is running yet

Before deploying, verify the Docker environment is clean:

```bash
docker ps --filter name=terraform
```

Expected output — no containers:
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```bash
docker network ls --filter name=terraform
```

Expected — no terraform network:
```
NETWORK ID     NAME      DRIVER    SCOPE
```

### Preview the deployment with terraform plan

`terraform plan` is a dry run. It compares your configuration against the current state
and shows you exactly what will be created, changed, or destroyed — **without touching
anything**.

```bash
terraform plan
```

Read the output carefully. You should see **8 resources to add, 0 to change, 0 to destroy**:

```
Plan: 8 to add, 0 to change, 0 to destroy.
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
terraform apply
```

Terraform will print the plan again and ask for confirmation:

```
Do you want to perform these actions?
  Terraform will perform all actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Type `yes` and press Enter.

**What happens next (in order):**

1. Docker network `terraform-net` is created
2. CSR storage volume is created
3. All three containers start simultaneously
4. The `null_resource.csr_ready` provisioner begins — it will print a message every 10
   seconds while waiting for the CSR to boot. **This takes approximately 7-8 minutes.**
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

When `terraform apply` completes, you will see:

```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

csr_hostname = "csr-terraform"
csr_ip       = "172.20.21.10"
linux1_ip    = "172.20.21.20"
linux2_ip    = "172.20.21.21"
loopback0    = "10.99.99.1/255.255.255.255"
```

---

## Part 3 — Verify the Deployment

### Check running containers

```bash
docker ps --filter name=terraform
```

Expected — all three containers running:
```
CONTAINER ID   IMAGE                              STATUS         NAMES
xxxxxxxxxxxx   vrnetlab/vr-csr:16.12.05           Up X minutes   csr-terraform
xxxxxxxxxxxx   ghcr.io/hellt/network-multitool    Up X minutes   linux-terraform1
xxxxxxxxxxxx   ghcr.io/hellt/network-multitool    Up X minutes   linux-terraform2
```

### Check the Docker network

```bash
docker network inspect terraform-net --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
```

Expected:
```
172.20.21.0/24
```

### Check container IP addresses

```bash
docker inspect csr-terraform      --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect linux-terraform1   --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
docker inspect linux-terraform2   --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

Expected:
```
172.20.21.10
172.20.21.20
172.20.21.21
```

### Verify RESTCONF is responding on the CSR

```bash
curl -sk -u admin:admin \
  https://172.20.21.10/restconf/data/Cisco-IOS-XE-native:native/hostname \
  | python3 -m json.tool
```

Expected output — the hostname Terraform configured:
```json
{
    "Cisco-IOS-XE-native:hostname": "csr-terraform"
}
```

### Verify Loopback0 exists on the CSR

```bash
curl -sk -u admin:admin \
  https://172.20.21.10/restconf/data/Cisco-IOS-XE-native:native/interface/Loopback=0 \
  | python3 -m json.tool
```

Expected output:
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
csr-terraform# show running-config | include hostname
hostname csr-terraform

csr-terraform# show interfaces Loopback0
Loopback0 is up, line protocol is up
  Description: Managed by Terraform
  Internet address is 10.99.99.1/32
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

Type `exit` to leave.

### View the Terraform state file

The state file is Terraform's source of truth — it records every resource it manages.

```bash
terraform show
```

This renders the current state in human-readable form. You will see all 8 resources with
their attributes.

```bash
terraform output
```

Re-prints the output values without running a full plan or apply.

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

### Step 2 — Confirm it is gone

```bash
docker ps --filter name=terraform
```

Expected — only two containers remain:
```
CONTAINER ID   IMAGE                              STATUS         NAMES
xxxxxxxxxxxx   vrnetlab/vr-csr:16.12.05           Up X minutes   csr-terraform
xxxxxxxxxxxx   ghcr.io/hellt/network-multitool    Up X minutes   linux-terraform1
```

`linux-terraform2` is missing. The infrastructure has **drifted** from the Terraform
configuration.

### Step 3 — Detect drift with terraform plan

Run `terraform plan` to let Terraform compare the real world against its state:

```bash
terraform plan
```

Terraform will detect that `linux-terraform2` is missing and report it must be re-created:

```
module.docker_infra.docker_container.linux2: Refreshing state...
  ...
  # module.docker_infra.docker_container.linux2 must be replaced
  ...

Plan: 2 to add, 0 to change, 0 to destroy.
```

> **Terraform found the drift.** It knows `linux-terraform2` should exist (it's in the
> state file) but doesn't (it's not running). It will also re-run the `null_resource`
> that depends on the container, but the CSR is already up so the readiness loop will
> exit immediately (RESTCONF is already responding with HTTP 200).

### Step 4 — Remediate drift with terraform apply

```bash
terraform apply
```

Type `yes` when prompted.

Because RESTCONF is already active on the CSR, `null_resource.csr_ready` will complete
in seconds (the first poll returns HTTP 200). The missing container will be recreated.

Expected output:
```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### Step 5 — Confirm all three containers are running again

```bash
docker ps --filter name=terraform
```

All three should be back:
```
CONTAINER ID   IMAGE                              STATUS         NAMES
xxxxxxxxxxxx   vrnetlab/vr-csr:16.12.05           Up X minutes   csr-terraform
xxxxxxxxxxxx   ghcr.io/hellt/network-multitool    Up X minutes   linux-terraform1
xxxxxxxxxxxx   ghcr.io/hellt/network-multitool    Up X minutes   linux-terraform2
```

### Step 6 — Verify terraform plan now shows no changes

```bash
terraform plan
```

Expected:
```
No changes. Your infrastructure matches the configuration.
```

This is the Terraform "all clear" — the real world matches the desired state exactly.

---

## Part 5 — Tear Down

At the end of this section, **tear down the Terraform environment completely** before
moving on to the ContainerLab section. The CSR uses significant RAM (~3.5 GiB) that the
ContainerLab topology needs.

### Destroy all resources

```bash
terraform destroy
```

Terraform will print the full destruction plan and ask for confirmation:

```
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value:
```

Type `yes` and press Enter.

Expected output:
```
Destroy complete! Resources: 5 destroyed.
```

> Note: the two iosxe resources (`iosxe_system.this` and `iosxe_interface_loopback.lo0`)
> are also removed from state, but since the CSR container itself is being destroyed,
> Terraform skips the RESTCONF DELETE calls — the config disappears with the container.

### Verify everything is cleaned up

```bash
docker ps --filter name=terraform
```

Expected — no containers:
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

```bash
docker network ls --filter name=terraform
```

Expected — no terraform network:
```
NETWORK ID     NAME      DRIVER    SCOPE
```

```bash
docker volume ls --filter name=terraform
```

Expected — no terraform volume:
```
DRIVER    VOLUME NAME
```

### Confirm Terraform state is empty

```bash
terraform show
```

Expected:
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
| `terraform apply` | Deploy or update infrastructure to match config |
| `terraform destroy` | Remove all Terraform-managed resources |
| `terraform show` | Display current state in human-readable form |
| `terraform output` | Print output values |
| `docker ps --filter name=terraform` | Check which terraform containers are running |
| `docker logs -f csr-terraform` | Follow CSR boot log |
| `curl -sk -u admin:admin https://172.20.21.10/restconf/...` | Query CSR via RESTCONF |

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
6. Used `terraform plan` to detect the drift and `terraform apply` to remediate it
7. Performed a clean teardown with `terraform destroy` and verified all resources were removed

The key takeaway: with IaC, your infrastructure is **defined, versioned, and repeatable**.
Drift is detectable and correctable. The same configuration file that built this lab today
will build the exact same lab tomorrow, next week, or on a completely different server.
