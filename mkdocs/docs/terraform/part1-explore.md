# Part 1 — Explore the Configuration

Before deploying anything, take a few minutes to understand what Terraform will build.

## Navigate to the working directory

```bash
cd ~/terraform-lab/terraform
```

## Look at the file structure

Run `ls -la` to see the full directory listing with permissions and sizes:

```bash
ls -la
```

??? note "Expected output (timestamps and sizes may differ slightly — that is normal)"
    ```
    total 100
    drwxrwxr-x 4 cisco cisco  4096 Mar 22 17:48 .
    drwxrwxr-x 3 cisco cisco  4096 Mar 19 22:32 ..
    drwxrwxr-x 4 cisco cisco  4096 Mar 19 22:32 .terraform
    -rw-r--r-- 1 cisco cisco  1513 Mar 19 22:33 .terraform.lock.hcl
    -rw-r--r-- 1 cisco cisco  2331 Mar 20 18:51 main.tf
    drwxrwxr-x 4 cisco cisco  4096 Mar 19 22:32 modules
    -rw-r--r-- 1 cisco cisco   807 Mar 19 22:32 outputs.tf
    -rw-rw-r-- 1 cisco cisco   183 Mar 22 17:48 terraform.tfstate
    -rw-rw-r-- 1 cisco cisco 28878 Mar 20 18:48 terraform.tfstate.1774032510.backup
    -rw-rw-r-- 1 cisco cisco 28804 Mar 22 17:48 terraform.tfstate.backup
    -rw-r--r-- 1 cisco cisco  3357 Mar 19 22:32 variables.tf
    ```

!!! info "Why are there state files already?"
    On a brand-new Terraform project, `terraform.tfstate` would not exist until after the
    first `terraform apply`. The state files you see here exist because this lab environment
    was pre-tested and then cleaned up with `terraform destroy` before you received it.

    - `terraform.tfstate` (183 bytes) — after `terraform destroy` completes, Terraform writes
      a near-empty state file rather than deleting it. The 183-byte size tells you it contains
      only the format header — no resources are tracked. You can confirm this with
      `terraform show`, which will print `The state file is empty`.
    - `terraform.tfstate.backup` — a copy of the full state from the last `apply`, saved
      automatically by Terraform when `destroy` ran.
    - `terraform.tfstate.1774032510.backup` — an older backup from a prior run.

    You will see this same pattern yourself at the end of Part 5 after you run
    `terraform destroy`.

Here is what each file does:

| File / Directory | Purpose |
|---|---|
| `main.tf` | Root module — ties the two sub-modules together |
| `variables.tf` | All input variables with their default values |
| `outputs.tf` | Values printed to the screen after `terraform apply` |
| `modules/` | Folder containing the two sub-modules |
| `.terraform/` | Terraform's internal directory — provider plugins live here |
| `.terraform.lock.hcl` | Records the exact provider versions in use (like a lock file) |
| `terraform.tfstate` | Terraform's memory — currently empty (post-destroy residue). Will be populated after `terraform apply` |
| `terraform.tfstate.backup` | Automatic backup of the previous state, saved when `destroy` ran |

Now run `ls modules/` to see what modules are available:

```bash
ls modules/
```

??? note "Expected output"
    ```
    docker-infra  iosxe-config
    ```
    May appear side by side or on separate lines depending on your terminal width — both are correct.

## Read the root module

```bash
cat main.tf
```

This is the entry point for the entire lab. Read through it and notice:

- The `terraform { required_providers { ... } }` block declares which providers this
  configuration needs — `kreuzwerker/docker` and `CiscoDevNet/iosxe`.
- The `provider "iosxe"` block tells the IOS XE provider where to connect: it points at
  `172.20.21.10` (the CSR container) and uses `protocol = "restconf"`.
- The two `module` blocks pull in the sub-modules from the `modules/` folder.
- `module "iosxe_config"` has `depends_on = [module.docker_infra]` — this tells Terraform
  to finish **all** docker-infra work (including waiting for the CSR to boot) before
  attempting any RESTCONF configuration. Without this, Terraform might try to configure
  the router before it has even started up.

## Read the variables

```bash
cat variables.tf
```

Each `variable` block defines an input to the configuration. All of them have `default`
values, so no manual input is required — Terraform uses the defaults automatically.

Key defaults:

| Variable | Default | What it controls |
|---|---|---|
| `csr_ip` | `172.20.21.10` | IP address assigned to the CSR container |
| `csr_username` / `csr_password` | `admin` / `admin` | Login credentials for the CSR |
| `csr_hostname` | `csr-terraform` | Hostname Terraform will configure on the CSR |
| `loopback_ip` | `10.99.99.1` | IP address for Loopback0 |
| `linux1_ip` / `linux2_ip` | `172.20.21.20` / `172.20.21.21` | IPs for the Linux containers |

!!! note
    You will also see an `authorized_keys` variable with two long SSH public keys. These
    are pre-loaded keys that allow the lab server to SSH into the Linux containers without
    a password. You do not need to modify them.

## Read the docker-infra module

```bash
cat modules/docker-infra/main.tf
```

This module creates the Docker network, the storage volume, and the three containers.
Scroll down to find the `null_resource.csr_ready` block near the bottom. This is where
Terraform waits for the CSR to boot:

- It runs a shell script (`local-exec` provisioner) that polls the CSR's RESTCONF API
  every 10 seconds.
- If RESTCONF is not responding yet, it also tries to enable it over SSH.
- Once RESTCONF responds with HTTP 200, the script exits and Terraform proceeds.
- The CSR takes approximately **7-8 minutes** to complete its cold boot from a fresh volume.

## Read the iosxe-config module

```bash
cat modules/iosxe-config/main.tf
```

This module is simple — just two resources:

- `iosxe_system.this` — sends a RESTCONF call to set the hostname to `csr-terraform`
- `iosxe_interface_loopback.lo0` — sends a RESTCONF call to create Loopback0 with IP
  `10.99.99.1/32`

These two resources only run after `module.docker_infra` is fully complete (due to the
`depends_on` in `main.tf`).

## Read the outputs

```bash
cat outputs.tf
```

After `terraform apply` finishes, these five values will be printed to the terminal so
you can see a summary of what was deployed.

## Initialize Terraform

`terraform init` prepares the working directory — it reads the provider requirements and
links them from the local filesystem mirror. Since providers are pre-installed, this is
instantaneous (no download).

```bash
terraform init
```

??? success "Expected output"
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

If you see `Terraform has been successfully initialized!` you are ready to proceed to [Part 2](part2-deploy.md).

---

!!! next "Up next"
    Continue to [Part 2 — Plan and Deploy](part2-deploy.md) to run your first `terraform plan` and `terraform apply`.
