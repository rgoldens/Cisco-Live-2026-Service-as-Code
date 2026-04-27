# =============================================================================
# Terraform Outputs — Service as Code Lab
# =============================================================================

output "pe01_vrfs" {
  description = "VRFs provisioned on csr-pe01"
  value       = { for k, v in iosxe_vrf.pe01_vrf : k => v.name }
}

output "pe02_vrfs" {
  description = "VRFs provisioned on csr-pe02"
  value       = { for k, v in iosxe_vrf.pe02_vrf : k => v.name }
}

output "service_summary" {
  description = "Summary of deployed L3VPN services"
  value = [
    for svc in var.l3vpn_services : {
      customer = svc.customer
      vrf      = svc.vrf
      rd       = svc.rd
      pe_count = length(svc.pe_bindings)
    }
  ]
}
