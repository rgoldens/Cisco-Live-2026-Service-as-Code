# Part 2 — Plan and Deploy

## Confirm nothing is running yet

Before deploying, verify the Docker environment is clean:

```bash
docker ps --filter name=terraform
```

??? note "Expected output"
    ```
    CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
    ```

```bash
docker network ls --filter name=terraform
```

??? note "Expected output"
    ```
    NETWORK ID   NAME      DRIVER    SCOPE
    ```

## Preview the deployment with terraform plan

`terraform plan` is a dry run. It compares your configuration against the current state
and shows you exactly what will be created, changed, or destroyed — **without touching
anything**.

```bash
terraform plan
```

!!! tip "Heads up"
    The full output is verbose — Terraform lists every single attribute of every resource
    it plans to create, most of which say `(known after apply)` because the values won't
    exist until the resource is actually created. **Scroll past the details and focus on
    the summary lines at the very bottom.**

    `(known after apply)` simply means "Terraform will fill this in once the resource
    exists." For example, a container's ID is not known until Docker creates it.

The summary at the bottom of your output should look like this:

??? success "Expected output (bottom of the plan)"
    ```
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

The `Plan: 8 to add` means Terraform is planning to create 8 resources:

1. `module.docker_infra.docker_network.terraform_net` — the bridge network
2. `module.docker_infra.docker_volume.csr_storage` — CSR persistent storage volume
3. `module.docker_infra.docker_container.csr` — the CSR container
4. `module.docker_infra.docker_container.linux1` — linux-terraform1
5. `module.docker_infra.docker_container.linux2` — linux-terraform2
6. `module.docker_infra.null_resource.csr_ready` — the readiness + RESTCONF provisioner
7. `module.iosxe_config.iosxe_system.this` — CSR hostname via RESTCONF
8. `module.iosxe_config.iosxe_interface_loopback.lo0` — Loopback0 via RESTCONF

!!! info "Nothing has been deployed yet"
    `plan` is always safe to run.

## Deploy with terraform apply

```bash
terraform apply -auto-approve
```

!!! note
    The `-auto-approve` flag skips the interactive confirmation prompt. In the lab we use
    it to save time. In a production environment, always omit this flag — Terraform will
    print the plan and ask you to type `yes` before making any changes.

**What happens next (in order):**

1. Docker network `terraform-net` is created (~2s)
2. CSR storage volume is created (~0s)
3. All three containers start simultaneously (~1s each)
4. The `null_resource.csr_ready` provisioner begins — it polls RESTCONF every 10 seconds
   while waiting for the CSR to boot. **This takes approximately 7-8 minutes.**
   You will see `Still creating...` messages ticking by — this is normal. Do not interrupt it.
5. Once the CSR is ready, Terraform applies the hostname and Loopback0 via RESTCONF
   (~1 second each).

While waiting, open a second terminal and watch the CSR boot progress:

```bash
docker logs -f csr-terraform
```

Look for this line to confirm the CSR has finished booting:

```
Startup complete in: 0:07:XX
```

Press `Ctrl+C` to stop following the logs.

!!! info "Why is the provisioner output suppressed?"
    The `csr_password` variable is marked `sensitive = true` in `variables.tf`. Terraform
    automatically suppresses the output of any provisioner that uses a sensitive variable
    to avoid accidentally printing passwords to the screen. That is why you see
    `(output suppressed due to sensitive value in config)` instead of the polling loop
    messages.

??? success "Expected output (key lines)"
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

!!! note
    The hex IDs (like `[id=cf2b394afde8...]`) will be different on your run — they are
    Docker container IDs generated at creation time.

Continue to [Part 3 — Verify the Deployment](part3-verify.md).
