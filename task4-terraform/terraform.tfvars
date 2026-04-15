# ============================================================================
# terraform.tfvars — Student exercise: fill in the TODO values
# ============================================================================
#
# This file contains the values for all variables defined in variables.tf.
# Fill in each TODO below using the reference tables in the Lab Guide.
#
# ============================================================================

# ---------------------------------------------------------------------------
# XRd connection details (these are provided — do not change)
# ---------------------------------------------------------------------------
xrd_hosts = {
  xrd01 = "172.20.20.10"
  xrd02 = "172.20.20.11"
}

xrd_username = "clab"
xrd_ssh_key  = "~/.ssh/id_rsa"

# ---------------------------------------------------------------------------
# BGP configuration
# ---------------------------------------------------------------------------
# EXERCISE: Fill in the BGP AS numbers.
#
# Reference: See "Table 3: BGP Peering" in the Lab Guide.
#   - The XRd core routers share an AS number (the SP core AS)
#   - The CSR PE routers share a different AS number (the customer AS)
# ---------------------------------------------------------------------------
bgp_asn      = "___"       # TODO: SP core AS number (XRd routers)
customer_asn = "___"       # TODO: Customer PE AS number (CSR routers)

# ---------------------------------------------------------------------------
# VRF configuration
# ---------------------------------------------------------------------------
vrf_name            = "Customer-CLIVE"
route_target        = "65000:1"
route_distinguisher = "65000:1"

# ---------------------------------------------------------------------------
# Per-router configuration
# ---------------------------------------------------------------------------
# EXERCISE: Fill in the per-router values below.
#
# Reference: See "Table 2: IP Addressing" and "Table 3: BGP Peering"
# in the Lab Guide.
#
# Each XRd router needs:
#   - remote_lo: The OTHER XRd's Loopback0 IP (for iBGP VPNv4 peering)
#   - gi1_ip:    This XRd's Gi0/0/0/1 IP toward the CSR PE
#   - gi1_mask:  Subnet mask for the /30 link (hint: 255.255.255.252)
#   - csr_peer:  The CSR PE's IP on the same /30 link (eBGP neighbor)
# ---------------------------------------------------------------------------
xrd_config = {
  xrd01 = {
    remote_lo = "___"       # TODO: xrd02's Loopback0 IP
    gi1_ip    = "___"       # TODO: xrd01's Gi0/0/0/1 IP toward csr-pe01
    gi1_mask  = "___"       # TODO: Subnet mask for the /30 link
    csr_peer  = "___"       # TODO: csr-pe01's IP on the same /30 link
  }
  xrd02 = {
    remote_lo = "___"       # TODO: xrd01's Loopback0 IP
    gi1_ip    = "___"       # TODO: xrd02's Gi0/0/0/1 IP toward csr-pe02
    gi1_mask  = "___"       # TODO: Subnet mask for the /30 link
    csr_peer  = "___"       # TODO: csr-pe02's IP on the same /30 link
  }
}
