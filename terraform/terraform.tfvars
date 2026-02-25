# =============================================================================
# Terraform Variable Values — Service as Code Lab
#
# This file is the Terraform-side equivalent of the YAML SoT files.
# In production you'd generate this from the YAML or use a data source.
# =============================================================================

device_username = "admin"
device_password = "admin"

pe_hosts = {
  "csr-pe01" = "https://172.20.20.13"
  "csr-pe02" = "https://172.20.20.14"
}

p_hosts = {
  "xrd01" = "https://172.20.20.11"
  "xrd02" = "https://172.20.20.12"
}

bgp_as = 65000

l3vpn_services = [
  {
    customer  = "CustomerA"
    vrf       = "CUST_A"
    rd        = "65000:100"
    rt_import = "65000:100"
    rt_export = "65000:100"
    pe_bindings = [
      {
        pe_name      = "csr-pe01"
        interface    = "GigabitEthernet2"
        ip_address   = "192.168.100.1"
        subnet_mask  = "255.255.255.0"
        ce_neighbor  = "192.168.100.2"
        ce_remote_as = 65100
      },
      {
        pe_name      = "csr-pe02"
        interface    = "GigabitEthernet2"
        ip_address   = "192.168.200.1"
        subnet_mask  = "255.255.255.0"
        ce_neighbor  = "192.168.200.2"
        ce_remote_as = 65100
      }
    ]
  },
  {
    customer  = "CustomerB"
    vrf       = "CUST_B"
    rd        = "65000:200"
    rt_import = "65000:200"
    rt_export = "65000:200"
    pe_bindings = [
      {
        pe_name      = "csr-pe01"
        interface    = "GigabitEthernet2"
        ip_address   = "10.100.1.1"
        subnet_mask  = "255.255.255.0"
        ce_neighbor  = "10.100.1.2"
        ce_remote_as = 65100
      },
      {
        pe_name      = "csr-pe02"
        interface    = "GigabitEthernet2"
        ip_address   = "10.100.2.1"
        subnet_mask  = "255.255.255.0"
        ce_neighbor  = "10.100.2.2"
        ce_remote_as = 65100
      }
    ]
  }
]
