# Part 5 — Tear Down

At the end of this section, **tear down the Terraform environment completely** before
moving on to the ContainerLab section. The CSR uses significant RAM (~3.5 GiB) that the
ContainerLab topology needs.

## Destroy all resources

!!! warning "Production note"
    In the lab, use `-auto-approve` to skip the confirmation prompt. In production,
    always omit this flag and review the destruction plan carefully before confirming.

Terraform destroys resources in the correct dependency order — IOS XE config first, then
containers, then the network and volume.

!!! tip "Heads up"
    Just like `plan` and `apply`, the `destroy` output is verbose — it lists every
    attribute being removed. Scroll to the bottom to see the final summary.

```bash
terraform destroy -auto-approve
```

??? success "Expected output (key lines)"
    ```
    module.iosxe_config.iosxe_interface_loopback.lo0: Destroying...
    module.iosxe_config.iosxe_system.this: Destroying...
    module.iosxe_config.iosxe_interface_loopback.lo0: Destruction complete after 3s
    module.iosxe_config.iosxe_system.this: Destruction complete after 6s
    module.docker_infra.null_resource.csr_ready: Destroying...
    module.docker_infra.null_resource.csr_ready: Destruction complete after 0s
    module.docker_infra.docker_container.linux1: Destroying...
    module.docker_infra.docker_container.linux2: Destroying...
    module.docker_infra.docker_container.csr: Destroying...
    module.docker_infra.docker_container.linux2: Destruction complete after 1s
    module.docker_infra.docker_container.linux1: Destruction complete after 1s
    module.docker_infra.docker_container.csr: Destruction complete after 1s
    module.docker_infra.docker_volume.csr_storage: Destroying...
    module.docker_infra.docker_network.terraform_net: Destroying...
    module.docker_infra.docker_volume.csr_storage: Destruction complete after 2s
    module.docker_infra.docker_network.terraform_net: Destruction complete after 2s

    Destroy complete! Resources: 8 destroyed.
    ```

## Verify everything is cleaned up

```bash
docker ps --filter name=terraform --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

??? success "Expected output"
    ```
    CONTAINER ID   IMAGE     STATUS    NAMES
    ```

```bash
docker network ls --filter name=terraform
```

??? success "Expected output"
    ```
    NETWORK ID   NAME      DRIVER    SCOPE
    ```

```bash
docker volume ls --filter name=terraform
```

??? success "Expected output"
    ```
    DRIVER    VOLUME NAME
    ```

## Confirm Terraform state is empty

```bash
terraform show
```

??? success "Expected output"
    ```
    The state file is empty. No resources are represented.
    ```

Everything is clean. You are ready to move on to the ContainerLab section.

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

!!! success "Key takeaway"
    With IaC, your infrastructure is **defined, versioned, and repeatable**.
    Drift is detectable and correctable. The same configuration file that built this lab
    today will build the exact same lab tomorrow, next week, or on a completely different
    server.

---

!!! next "Up next"
    Head to the [Quick Reference](quick-reference.md) for a handy command cheat sheet, or return to the [Home](../index.md) page.
