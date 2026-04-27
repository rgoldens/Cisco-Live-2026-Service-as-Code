# =============================================================================
# Terraform Variables — Service as Code Lab
# =============================================================================

# --- Device connectivity ---
variable "device_username_iosxe" {
  description = "SSH/RESTCONF username for IOS-XE devices"
  type        = string
  default     = "admin"
}

variable "device_password_iosxe" {
  description = "SSH/RESTCONF password for IOS-XE devices"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "device_username_iosxr" {
  description = "SSH/RESTCONF username for IOS-XR devices"
  type        = string
  default     = "clab"
}

variable "device_password_iosxr" {
  description = "SSH/RESTCONF password for IOS-XR devices"
  type        = string
  sensitive   = true
  default     = "clab@123"
}

variable "pe_hosts" {
  description = "Map of PE router names to management IPs (LTRATO-1001)"
  type        = map(string)
  default = {
    "csr-pe01" = "https://172.20.20.20"
    "csr-pe02" = "https://172.20.20.21"
  }
}

variable "p_hosts" {
  description = "Map of P-router names to management IPs (LTRATO-1001)"
  type        = map(string)
  default = {
    "xrd01" = "https://172.20.20.10"
    "xrd02" = "https://172.20.20.11"
  }
}

# --- BGP ---
variable "bgp_as" {
  description = "BGP AS number for the SP core"
  type        = number
  default     = 65000
}

# --- L3VPN Service Definitions ---
# These mirror the YAML SoT files in services/l3vpn/vars/
variable "l3vpn_services" {
  description = "List of L3VPN service definitions"
  type = list(object({
    customer  = string
    vrf       = string
    rd        = string
    rt_import = string
    rt_export = string
    pe_bindings = list(object({
      pe_name      = string
      interface    = string
      ip_address   = string
      subnet_mask  = string
      ce_neighbor  = string
      ce_remote_as = number
    }))
  }))
}
