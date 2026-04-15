# ============================================================================
# variables.tf — Variable definitions for Task 4: Terraform XRd Configuration
# ============================================================================
#
# These variables define connection details and configuration parameters
# for the XRd core routers. Students fill in values in terraform.tfvars.
#
# ============================================================================

# ---------------------------------------------------------------------------
# XRd connection details
# ---------------------------------------------------------------------------
variable "xrd_hosts" {
  description = "Map of XRd hostnames to their management IPs"
  type        = map(string)
}

variable "xrd_username" {
  description = "SSH username for XRd routers"
  type        = string
}

variable "xrd_ssh_key" {
  description = "Path to SSH private key for XRd authentication"
  type        = string
}

# ---------------------------------------------------------------------------
# BGP configuration
# ---------------------------------------------------------------------------
variable "bgp_asn" {
  description = "BGP AS number for the SP core (XRd routers)"
  type        = string
}

variable "customer_asn" {
  description = "BGP AS number for the customer PEs (CSR routers)"
  type        = string
}

variable "vrf_name" {
  description = "VRF name for the customer service"
  type        = string
}

variable "route_target" {
  description = "Route target for VRF import/export (format: ASN:nn)"
  type        = string
}

variable "route_distinguisher" {
  description = "Route distinguisher for the VRF (format: ASN:nn)"
  type        = string
}

# ---------------------------------------------------------------------------
# Per-router configuration
# ---------------------------------------------------------------------------
variable "xrd_config" {
  description = "Per-router configuration for each XRd device"
  type = map(object({
    remote_lo = string  # Remote XRd's Loopback0 IP (iBGP VPNv4 peer)
    gi1_ip    = string  # This XRd's Gi0/0/0/1 IP toward CSR PE
    gi1_mask  = string  # Subnet mask for the /30 link
    csr_peer  = string  # CSR PE's IP on the same /30 link (eBGP neighbor)
  }))
}
