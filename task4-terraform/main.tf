# ============================================================================
# main.tf — Task 4: Configure XRd Core Routers with Terraform
# ============================================================================
#
# WHAT THIS CONFIG DOES:
#   Configures the same VRF, BGP, and route-policy on the XRd core routers
#   that you previously configured with Ansible in Task 3. Same outcome,
#   different tool — now you can compare the two approaches.
#
# KEY DIFFERENCES FROM ANSIBLE:
#   - Terraform is declarative: you describe WHAT should exist, not HOW
#   - "terraform plan" shows you exactly what will change BEFORE applying
#   - A state file tracks what Terraform manages — drift is detected by
#     comparing the state file against the actual device configuration
#   - "terraform destroy" cleanly removes everything Terraform created
#
# USAGE:
#   terraform init      # Download the IOS-XR provider
#   terraform plan      # Preview what will be created (read this carefully!)
#   terraform apply     # Push the configuration
#   terraform plan      # Run again — should show "No changes" (no drift)
#
# ============================================================================

# ---------------------------------------------------------------------------
# Terraform and provider configuration
# ---------------------------------------------------------------------------
# The "required_providers" block tells Terraform which provider plugin to
# download. This is similar to Ansible's "collections" — it's the bridge
# between Terraform and the IOS-XR devices.
#
# The provider uses gNMI (gRPC Network Management Interface) to communicate
# with the XRd routers. gNMI is the model-driven alternative to CLI — it
# speaks YANG models natively, which is why Terraform resources map so
# cleanly to device configuration.
# ---------------------------------------------------------------------------
terraform {
  required_providers {
    iosxr = {
      source  = "CiscoDevNet/iosxr"
      version = ">= 0.5.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Provider — connect to both XRd routers via gNMI
# ---------------------------------------------------------------------------
# The "devices" block lets us manage multiple XRd routers from a single
# provider instance. Each resource below uses the "device" attribute to
# target a specific router — similar to Ansible's "inventory_hostname".
#
# gNMI runs on port 9339 with TLS disabled in this lab environment.
# In production, you would always enable TLS.
# ---------------------------------------------------------------------------
provider "iosxr" {
  username = var.xrd_username
  password = "clab@123"

  # Default device (xrd01)
  host = "${var.xrd_hosts["xrd01"]}:9339"
  tls  = false

  devices = [
    {
      name = "xrd01"
      host = "${var.xrd_hosts["xrd01"]}:9339"
    },
    {
      name = "xrd02"
      host = "${var.xrd_hosts["xrd02"]}:9339"
    }
  ]
}

# ============================================================================
# RESOURCES — Each block below declares a piece of configuration that
# Terraform will create, manage, and track in its state file.
#
# Compare this to the Ansible playbook (inter-as-option-a.yml):
#   - Ansible: sequential tasks, each pushing CLI commands
#   - Terraform: declarative resources, order determined automatically
#
# Terraform figures out the dependency order for you. If Resource B
# depends on Resource A, Terraform creates A first — you don't need
# to worry about task ordering like in Ansible.
# ============================================================================

# ---------------------------------------------------------------------------
# Step 1: Route-policy PASS-ALL
# ---------------------------------------------------------------------------
# IOS-XR requires a route-policy for BGP neighbors. This simple policy
# permits all routes — in production, you'd filter more carefully.
#
# Notice: this is the FULL policy text, not individual CLI commands.
# Terraform sends it as a single object via the YANG model.
# ---------------------------------------------------------------------------
resource "iosxr_route_policy" "pass_all_xrd01" {
  device            = "xrd01"
  route_policy_name = "PASS-ALL"
  rpl               = "route-policy PASS-ALL\n  pass\nend-policy\n"
}

resource "iosxr_route_policy" "pass_all_xrd02" {
  device            = "xrd02"
  route_policy_name = "PASS-ALL"
  rpl               = "route-policy PASS-ALL\n  pass\nend-policy\n"
}

# ---------------------------------------------------------------------------
# Step 2: VRF Customer-CLIVE
# ---------------------------------------------------------------------------
# The VRF keeps customer traffic separate from the SP infrastructure.
# Route-targets control which VRF routes are imported/exported across
# the MPLS core.
#
# Compare to Ansible: in the playbook, this was raw CLI commands
# ("vrf Customer-CLIVE / address-family ipv4 unicast / import route-target").
# In Terraform, it's a structured resource with typed attributes.
# ---------------------------------------------------------------------------
resource "iosxr_vrf" "customer_clive_xrd01" {
  device   = "xrd01"
  vrf_name = var.vrf_name

  ipv4_unicast = true

  ipv4_unicast_import_route_target_two_byte_as_format = [
    {
      two_byte_as_number = tonumber(split(":", var.route_target)[0])
      asn2_index         = tonumber(split(":", var.route_target)[1])
      stitching          = "disable"
    }
  ]
  ipv4_unicast_export_route_target_two_byte_as_format = [
    {
      two_byte_as_number = tonumber(split(":", var.route_target)[0])
      asn2_index         = tonumber(split(":", var.route_target)[1])
      stitching          = "disable"
    }
  ]
}

resource "iosxr_vrf" "customer_clive_xrd02" {
  device   = "xrd02"
  vrf_name = var.vrf_name

  ipv4_unicast = true

  ipv4_unicast_import_route_target_two_byte_as_format = [
    {
      two_byte_as_number = tonumber(split(":", var.route_target)[0])
      asn2_index         = tonumber(split(":", var.route_target)[1])
      stitching          = "disable"
    }
  ]
  ipv4_unicast_export_route_target_two_byte_as_format = [
    {
      two_byte_as_number = tonumber(split(":", var.route_target)[0])
      asn2_index         = tonumber(split(":", var.route_target)[1])
      stitching          = "disable"
    }
  ]
}

# ---------------------------------------------------------------------------
# Step 3: Assign Gi0/0/0/1 to VRF and configure IP
# ---------------------------------------------------------------------------
# When an interface is placed into a VRF, its existing IP is removed.
# We must re-apply the IP address after the VRF assignment — Terraform
# handles both in a single resource because it's declarative.
#
# The iosxr_interface_ethernet resource manages the full interface state:
# VRF, IP address, and admin status in one shot.
# ---------------------------------------------------------------------------
resource "iosxr_interface_ethernet" "gi1_xrd01" {
  device       = "xrd01"
  type         = "GigabitEthernet"
  name         = "0/0/0/1"
  vrf          = var.vrf_name
  ipv4_address = var.xrd_config["xrd01"].gi1_ip
  ipv4_netmask = var.xrd_config["xrd01"].gi1_mask
  shutdown     = false

  depends_on = [iosxr_vrf.customer_clive_xrd01]
}

resource "iosxr_interface_ethernet" "gi1_xrd02" {
  device       = "xrd02"
  type         = "GigabitEthernet"
  name         = "0/0/0/1"
  vrf          = var.vrf_name
  ipv4_address = var.xrd_config["xrd02"].gi1_ip
  ipv4_netmask = var.xrd_config["xrd02"].gi1_mask
  shutdown     = false

  depends_on = [iosxr_vrf.customer_clive_xrd02]
}

# ---------------------------------------------------------------------------
# Step 4: BGP process and iBGP VPNv4 neighbor
# ---------------------------------------------------------------------------
# The BGP process carries VRF routes across the SP core via VPNv4.
# The iBGP neighbor is the OTHER XRd router (peering via Loopback0).
#
# Compare to Ansible: in the playbook, this was multiple sequential tasks
# pushing CLI blocks. Here, it's a single resource with nested attributes.
# Terraform resolves the order automatically.
# ---------------------------------------------------------------------------
resource "iosxr_router_bgp" "bgp_xrd01" {
  device    = "xrd01"
  as_number = var.bgp_asn

  neighbors = [
    {
      address       = var.xrd_config["xrd01"].remote_lo
      remote_as     = var.bgp_asn
      update_source = "Loopback0"
    }
  ]
}

resource "iosxr_router_bgp" "bgp_xrd02" {
  device    = "xrd02"
  as_number = var.bgp_asn

  neighbors = [
    {
      address       = var.xrd_config["xrd02"].remote_lo
      remote_as     = var.bgp_asn
      update_source = "Loopback0"
    }
  ]
}

# ---------------------------------------------------------------------------
# Step 4b: Enable VPNv4 address-family
# ---------------------------------------------------------------------------
resource "iosxr_router_bgp_address_family" "vpnv4_xrd01" {
  device    = "xrd01"
  as_number = var.bgp_asn
  af_name   = "vpnv4-unicast"

  depends_on = [iosxr_router_bgp.bgp_xrd01]
}

resource "iosxr_router_bgp_address_family" "vpnv4_xrd02" {
  device    = "xrd02"
  as_number = var.bgp_asn
  af_name   = "vpnv4-unicast"

  depends_on = [iosxr_router_bgp.bgp_xrd02]
}

# ---------------------------------------------------------------------------
# Step 4c: Activate VPNv4 on the iBGP neighbor
# ---------------------------------------------------------------------------
# The iBGP neighbor must be activated under the VPNv4 address-family.
# Without this, BGP shows "No address-family configured" and the session
# stays Idle — no VPN routes are exchanged across the core.
# ---------------------------------------------------------------------------
resource "iosxr_router_bgp_neighbor_address_family" "vpnv4_nbr_xrd01" {
  device    = "xrd01"
  as_number = var.bgp_asn
  address   = var.xrd_config["xrd01"].remote_lo
  af_name   = "vpnv4-unicast"

  depends_on = [
    iosxr_router_bgp.bgp_xrd01,
    iosxr_router_bgp_address_family.vpnv4_xrd01
  ]
}

resource "iosxr_router_bgp_neighbor_address_family" "vpnv4_nbr_xrd02" {
  device    = "xrd02"
  as_number = var.bgp_asn
  address   = var.xrd_config["xrd02"].remote_lo
  af_name   = "vpnv4-unicast"

  depends_on = [
    iosxr_router_bgp.bgp_xrd02,
    iosxr_router_bgp_address_family.vpnv4_xrd02
  ]
}

# ---------------------------------------------------------------------------
# Step 5: BGP VRF with eBGP neighbor toward CSR PE
# ---------------------------------------------------------------------------
# This is where the SP core connects to the customer edge. The eBGP
# neighbor in the VRF peers with the CSR PE across the /30 link.
#
# "as_override" is critical — both CSR PEs use the same AS (65001).
# Without it, BGP loop prevention rejects routes with AS 65001 in the path.
#
# Notice the "depends_on" — Terraform must create the BGP process and
# VRF before it can configure the VRF under BGP. In Ansible, you managed
# this by task ordering. In Terraform, explicit dependencies handle it.
# ---------------------------------------------------------------------------
resource "iosxr_router_bgp_vrf" "vrf_bgp_xrd01" {
  device    = "xrd01"
  as_number = var.bgp_asn
  vrf_name  = var.vrf_name

  rd_two_byte_as_number = split(":", var.route_distinguisher)[0]
  rd_two_byte_as_index  = tonumber(split(":", var.route_distinguisher)[1])

  neighbors = [
    {
      address     = var.xrd_config["xrd01"].csr_peer
      remote_as   = var.customer_asn
      as_override = "enable"
    }
  ]

  depends_on = [
    iosxr_router_bgp.bgp_xrd01,
    iosxr_vrf.customer_clive_xrd01
  ]
}

resource "iosxr_router_bgp_vrf" "vrf_bgp_xrd02" {
  device    = "xrd02"
  as_number = var.bgp_asn
  vrf_name  = var.vrf_name

  rd_two_byte_as_number = split(":", var.route_distinguisher)[0]
  rd_two_byte_as_index  = tonumber(split(":", var.route_distinguisher)[1])

  neighbors = [
    {
      address     = var.xrd_config["xrd02"].csr_peer
      remote_as   = var.customer_asn
      as_override = "enable"
    }
  ]

  depends_on = [
    iosxr_router_bgp.bgp_xrd02,
    iosxr_vrf.customer_clive_xrd02
  ]
}

# ---------------------------------------------------------------------------
# Step 5b: BGP VRF address-family with route redistribution and policies
# ---------------------------------------------------------------------------
resource "iosxr_router_bgp_vrf_address_family" "vrf_af_xrd01" {
  device    = "xrd01"
  as_number = var.bgp_asn
  vrf_name  = var.vrf_name
  af_name   = "ipv4-unicast"

  redistribute_connected = true

  depends_on = [iosxr_router_bgp_vrf.vrf_bgp_xrd01]
}

resource "iosxr_router_bgp_vrf_address_family" "vrf_af_xrd02" {
  device    = "xrd02"
  as_number = var.bgp_asn
  vrf_name  = var.vrf_name
  af_name   = "ipv4-unicast"

  redistribute_connected = true

  depends_on = [iosxr_router_bgp_vrf.vrf_bgp_xrd02]
}

# ---------------------------------------------------------------------------
# Step 5c: BGP VRF neighbor address-family with route-policies
# ---------------------------------------------------------------------------
# IOS-XR requires an explicit route-policy on every eBGP neighbor.
# Without it, the neighbor session comes up but no routes are exchanged.
# We apply the PASS-ALL policy we created in Step 1.
# ---------------------------------------------------------------------------
resource "iosxr_router_bgp_vrf_neighbor_address_family" "vrf_nbr_af_xrd01" {
  device           = "xrd01"
  as_number        = var.bgp_asn
  vrf_name         = var.vrf_name
  address          = var.xrd_config["xrd01"].csr_peer
  af_name          = "ipv4-unicast"
  route_policy_in  = "PASS-ALL"
  route_policy_out = "PASS-ALL"

  depends_on = [
    iosxr_router_bgp_vrf.vrf_bgp_xrd01,
    iosxr_route_policy.pass_all_xrd01
  ]
}

resource "iosxr_router_bgp_vrf_neighbor_address_family" "vrf_nbr_af_xrd02" {
  device           = "xrd02"
  as_number        = var.bgp_asn
  vrf_name         = var.vrf_name
  address          = var.xrd_config["xrd02"].csr_peer
  af_name          = "ipv4-unicast"
  route_policy_in  = "PASS-ALL"
  route_policy_out = "PASS-ALL"

  depends_on = [
    iosxr_router_bgp_vrf.vrf_bgp_xrd02,
    iosxr_route_policy.pass_all_xrd02
  ]
}
