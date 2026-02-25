# =============================================================================
# L3VPN Resources — Terraform (Full Alternative to Ansible)
# Service as Code Lab — Cisco Live 2026
#
# This file declaratively manages L3VPN service resources on IOS-XE PEs.
# It uses the CiscoDevNet/iosxe provider via RESTCONF.
# =============================================================================

# -----------------------------------------------------------------------------
# Flatten PE bindings so we can iterate over individual PE+service combinations
# -----------------------------------------------------------------------------
locals {
  # Build a flat list: one entry per (service, pe_binding) pair
  pe01_bindings = flatten([
    for svc in var.l3vpn_services : [
      for binding in svc.pe_bindings : {
        customer     = svc.customer
        vrf          = svc.vrf
        rd           = svc.rd
        rt_import    = svc.rt_import
        rt_export    = svc.rt_export
        interface    = binding.interface
        ip_address   = binding.ip_address
        subnet_mask  = binding.subnet_mask
        ce_neighbor  = binding.ce_neighbor
        ce_remote_as = binding.ce_remote_as
      } if binding.pe_name == "csr-pe01"
    ]
  ])

  pe02_bindings = flatten([
    for svc in var.l3vpn_services : [
      for binding in svc.pe_bindings : {
        customer     = svc.customer
        vrf          = svc.vrf
        rd           = svc.rd
        rt_import    = svc.rt_import
        rt_export    = svc.rt_export
        interface    = binding.interface
        ip_address   = binding.ip_address
        subnet_mask  = binding.subnet_mask
        ce_neighbor  = binding.ce_neighbor
        ce_remote_as = binding.ce_remote_as
      } if binding.pe_name == "csr-pe02"
    ]
  ])
}

# =============================================================================
# CSR-PE01 — VRF Definitions
# =============================================================================
resource "iosxe_vrf" "pe01_vrf" {
  provider = iosxe.pe01
  for_each = { for b in local.pe01_bindings : b.vrf => b... }

  name              = each.key
  rd                = each.value[0].rd
  route_target_export = [
    {
      value = each.value[0].rt_export
    }
  ]
  route_target_import = [
    {
      value = each.value[0].rt_import
    }
  ]
  ipv4_unicast = true
}

# =============================================================================
# CSR-PE02 — VRF Definitions
# =============================================================================
resource "iosxe_vrf" "pe02_vrf" {
  provider = iosxe.pe02
  for_each = { for b in local.pe02_bindings : b.vrf => b... }

  name              = each.key
  rd                = each.value[0].rd
  route_target_export = [
    {
      value = each.value[0].rt_export
    }
  ]
  route_target_import = [
    {
      value = each.value[0].rt_import
    }
  ]
  ipv4_unicast = true
}

# =============================================================================
# CSR-PE01 — BGP Neighbor (VPNv4 toward RR)
# =============================================================================
resource "iosxe_bgp_neighbor" "pe01_rr1" {
  provider         = iosxe.pe01
  asn              = var.bgp_as
  ip               = "10.0.0.1"
  remote_as        = var.bgp_as
  description      = "xrd01-RR"
  update_source    = "Loopback0"
}

resource "iosxe_bgp_neighbor" "pe01_rr2" {
  provider         = iosxe.pe01
  asn              = var.bgp_as
  ip               = "10.0.0.2"
  remote_as        = var.bgp_as
  description      = "xrd02-RR"
  update_source    = "Loopback0"
}

# =============================================================================
# CSR-PE02 — BGP Neighbor (VPNv4 toward RR)
# =============================================================================
resource "iosxe_bgp_neighbor" "pe02_rr1" {
  provider         = iosxe.pe02
  asn              = var.bgp_as
  ip               = "10.0.0.1"
  remote_as        = var.bgp_as
  description      = "xrd01-RR"
  update_source    = "Loopback0"
}

resource "iosxe_bgp_neighbor" "pe02_rr2" {
  provider         = iosxe.pe02
  asn              = var.bgp_as
  ip               = "10.0.0.2"
  remote_as        = var.bgp_as
  description      = "xrd02-RR"
  update_source    = "Loopback0"
}

# =============================================================================
# CSR-PE01 — BGP VRF Address Families + CE Neighbors
# =============================================================================
resource "iosxe_bgp_address_family_ipv4_vrf" "pe01_vrf_af" {
  provider = iosxe.pe01
  for_each = { for b in local.pe01_bindings : b.vrf => b }

  asn = var.bgp_as
  af_name = "unicast"
  vrf     = each.key

  depends_on = [iosxe_vrf.pe01_vrf]
}

resource "iosxe_bgp_address_family_ipv4_vrf" "pe02_vrf_af" {
  provider = iosxe.pe02
  for_each = { for b in local.pe02_bindings : b.vrf => b }

  asn = var.bgp_as
  af_name = "unicast"
  vrf     = each.key

  depends_on = [iosxe_vrf.pe02_vrf]
}
