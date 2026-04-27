# =============================================================================
# Terraform Providers — Service as Code Lab
# Cisco Live 2026
#
# This is a FULL ALTERNATIVE to the Ansible path.
# Both paths consume the same service definitions (YAML SoT) but Terraform
# manages the resources declaratively via Cisco providers.
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    iosxe = {
      source  = "CiscoDevNet/iosxe"
      version = ">= 0.5.0"
    }
    iosxr = {
      source  = "CiscoDevNet/iosxr"
      version = ">= 0.2.0"
    }
    # NX-OS provider — uncomment when available / stable
    # nxos = {
    #   source  = "CiscoDevNet/nxos"
    #   version = ">= 0.5.0"
    # }
  }
}

# -----------------------------------------------------------------------------
# IOS-XE Provider instances (one per PE router)
# -----------------------------------------------------------------------------
provider "iosxe" {
  alias    = "pe01"
  host     = var.pe_hosts["csr-pe01"]
  username = var.device_username_iosxe
  password = var.device_password_iosxe
  insecure = true
}

provider "iosxe" {
  alias    = "pe02"
  host     = var.pe_hosts["csr-pe02"]
  username = var.device_username_iosxe
  password = var.device_password_iosxe
  insecure = true
}

# -----------------------------------------------------------------------------
# IOS-XR Provider instances (one per P-router / RR)
# -----------------------------------------------------------------------------
provider "iosxr" {
  alias    = "p01"
  host     = var.p_hosts["xrd01"]
  username = var.device_username_iosxr
  password = var.device_password_iosxr
  insecure = true
}

provider "iosxr" {
  alias    = "p02"
  host     = var.p_hosts["xrd02"]
  username = var.device_username_iosxr
  password = var.device_password_iosxr
  insecure = true
}
