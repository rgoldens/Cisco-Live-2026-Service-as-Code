# Part 3 — Verify the Deployment

## Check running containers

```bash
docker ps --filter name=terraform --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"
```

??? success "Expected output"
    ```
    CONTAINER ID   IMAGE                             STATUS                   NAMES
    5d90d3868ae6   ghcr.io/hellt/network-multitool   Up 7 minutes             linux-terraform2
    cf2b394afde8   ghcr.io/hellt/network-multitool   Up 7 minutes             linux-terraform1
    8fdc981b800e   vrnetlab/vr-csr:16.12.05          Up 7 minutes (healthy)   csr-terraform
    ```

The CSR shows `(healthy)` — the vrnetlab healthcheck confirms the IOS XE VM is fully
booted and responding.

## Check container IP addresses

```bash
docker inspect csr-terraform --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

??? success "Expected output"
    ```
    172.20.21.10
    ```

```bash
docker inspect linux-terraform1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

??? success "Expected output"
    ```
    172.20.21.20
    ```

```bash
docker inspect linux-terraform2 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
```

??? success "Expected output"
    ```
    172.20.21.21
    ```

## Check terraform output

```bash
terraform output
```

??? success "Expected output"
    ```
    csr_hostname = "csr-terraform"
    csr_ip = "172.20.21.10"
    linux1_ip = "172.20.21.20"
    linux2_ip = "172.20.21.21"
    loopback0 = "10.99.99.1/255.255.255.255"
    ```

## Verify RESTCONF is responding on the CSR

```bash
curl -sk -u admin:admin \
  -H "Accept: application/yang-data+json" \
  https://172.20.21.10/restconf/data/Cisco-IOS-XE-native:native/hostname
```

??? success "Expected output"
    ```json
    {
      "Cisco-IOS-XE-native:hostname": "csr-terraform"
    }
    ```

## Verify Loopback0 exists on the CSR

```bash
curl -sk -u admin:admin \
  -H "Accept: application/yang-data+json" \
  "https://172.20.21.10/restconf/data/Cisco-IOS-XE-native:native/interface/Loopback=0"
```

??? success "Expected output"
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

## SSH into the CSR and verify

The CSR is an older IOS XE image that uses legacy SSH algorithms. The extra flags below
tell your SSH client to allow those older algorithms — without them the connection will
be refused.

```bash
ssh -o KexAlgorithms=+diffie-hellman-group14-sha1 \
    -o HostKeyAlgorithms=+ssh-rsa \
    admin@172.20.21.10
```

Password: `admin`

!!! tip
    If prompted with `Are you sure you want to continue connecting (yes/no)?`, type `yes`
    and press Enter.

Once logged in, you will see the IOS XE prompt (`csr-terraform#`). Run the following
commands:

```
show running-config | include hostname
```

??? success "Expected output"
    ```
    hostname csr-terraform
    ```

Now verify that Loopback0 was created with the correct IP and description:

```
show interfaces Loopback0
```

??? success "Expected output"
    ```
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

## SSH into a Linux container and verify

!!! warning "Before connecting"
    If you have connected to `172.20.21.20` before (from a previous lab run), clear the
    old host key first to avoid an SSH error:

    ```bash
    ssh-keygen -f ~/.ssh/known_hosts -R 172.20.21.20
    ```

```bash
ssh root@172.20.21.20
```

Password: `root`

!!! tip
    If prompted with `Are you sure you want to continue connecting (yes/no)?`, type `yes`
    and press Enter.

Once logged in:

```
hostname
```

??? success "Expected output"
    ```
    0591fa78ea57
    ```

!!! note
    The hostname is the short container ID, not `linux-terraform1`. This is normal — the
    Terraform config does not explicitly set a hostname inside the container, so Docker
    uses the container ID by default. Your container ID will be different.

```
ip addr show eth0
```

??? success "Expected output (interface number and MAC address will differ)"
    ```
    59: eth0@if60: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
        link/ether 02:42:ac:14:15:14 brd ff:ff:ff:ff:ff:ff link-netnsid 0
        inet 172.20.21.20/24 brd 172.20.21.255 scope global eth0
           valid_lft forever preferred_lft forever
    ```

The important line is `inet 172.20.21.20/24` — that confirms the container has the
correct IP address on the `terraform-net` network.

Type `exit` to leave the Linux container and return to the lab server.

## Inspect the state file

Everything is deployed and verified. Before moving on, take a few minutes to look at
what Terraform actually recorded — the state file is what makes every subsequent
`plan`, `apply`, and `destroy` possible.

### View the human-readable state with terraform show

```bash
terraform show
```

Terraform reads `terraform.tfstate` and formats it for humans. The output lists every
resource it manages, with all the attribute values recorded at creation time. The output
is verbose — scroll through your terminal to see all 8 resources.

??? success "Expected output (first resource — your id values will differ)"
    ```
    # module.docker_infra.docker_network.terraform_net:
    resource "docker_network" "terraform_net" {
        driver                  = "bridge"
        id                      = "d1921eb1ab7e8f3c2a4b..."
        internal                = false
        name                    = "terraform-net"

        ipam_config {
            gateway = "172.20.21.1"
            subnet  = "172.20.21.0/24"
        }
    }

    # (remaining 7 resources follow — scroll to see docker_volume, docker_container x3,
    #  null_resource, iosxe_system, and iosxe_interface_loopback)
    ```

!!! note
    Notice the `id` field — this is a real runtime value that did not exist anywhere in
    your `.tf` files. Terraform recorded it the moment Docker created the network. Every
    resource has an `id` like this that Terraform uses to track and manage it going forward.

### View the raw state file

```bash
cat terraform.tfstate
```

The state file is plain JSON. You do not need to read all of it — here is the structure
of one resource entry so you understand what Terraform is storing:

??? note "Expected output (trimmed — the docker_network resource entry)"
    ```json
    {
      "version": 4,
      "terraform_version": "1.14.7",
      "resources": [
        {
          "module": "module.docker_infra",
          "mode": "managed",
          "type": "docker_network",
          "name": "terraform_net",
          "instances": [
            {
              "attributes": {
                "driver": "bridge",
                "id": "d1921eb1ab7e8f3c2a4b...",
                "name": "terraform-net",
                "ipam_config": [
                  {
                    "gateway": "172.20.21.1",
                    "subnet": "172.20.21.0/24"
                  }
                ]
              }
            }
          ]
        },
        ...
      ]
    }
    ```

!!! info "What the state file is doing for you"
    - **Every `plan` reads it first.** Terraform compares this file against your `.tf`
      configuration to calculate exactly what needs to change. If they match — `No changes`.
      If something is missing or different — Terraform shows you what it will fix.

    - **It is how drift gets detected.** If a resource exists in this file but has been
      deleted outside of Terraform, the next `plan` will flag it for recreation. You will
      see this in action in Part 4.

    - **It is how `destroy` knows what to remove.** Terraform reads this file to get the
      complete list of everything it created — container IDs, network IDs, volume names —
      and removes exactly those resources, nothing more.

    - **Never edit it by hand.** If you manually change a value in this file, Terraform's
      view of the world will be wrong and subsequent operations will behave unpredictably.
      If you ever need to manipulate state directly, use the `terraform state` subcommands
      (`terraform state list`, `terraform state show`, `terraform state rm`).

Continue to [Part 4 — Infrastructure Drift](part4-drift.md).
