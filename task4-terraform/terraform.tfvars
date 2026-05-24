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
bgp_asn      = "65000"
customer_asn = "65001"

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
    remote_lo = "192.168.0.2"
    gi1_ip    = "10.1.0.5"
    gi1_mask  = "255.255.255.252"
    csr_peer  = "10.1.0.6"
  }
  xrd02 = {
    remote_lo = "192.168.0.1"
    gi1_ip    = "10.1.0.9"
    gi1_mask  = "255.255.255.252"
    csr_peer  = "10.1.0.10"
  }
}
