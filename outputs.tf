output "desktop_pool_id" {
  description = "OCID of the OCI Secure Desktops pool."
  value       = oci_desktops_desktop_pool.this.id
}

output "desktop_pool_name" {
  description = "Display name of the OCI Secure Desktops pool."
  value       = oci_desktops_desktop_pool.this.display_name
}

output "desktop_pool_state" {
  description = "Lifecycle state of the OCI Secure Desktops pool."
  value       = oci_desktops_desktop_pool.this.state
}

output "desktop_pool_shape" {
  description = "Shape used by desktops in the pool."
  value       = oci_desktops_desktop_pool.this.shape_name
}

output "desktop_pool_maximum_size" {
  description = "Maximum number of desktops allowed in the pool."
  value       = oci_desktops_desktop_pool.this.maximum_size
}

output "desktop_pool_standby_size" {
  description = "Configured standby desktop count."
  value       = oci_desktops_desktop_pool.this.standby_size
}

output "desktop_pool_active_desktops" {
  description = "Current number of active desktops in the pool."
  value       = oci_desktops_desktop_pool.this.active_desktops
}

output "secure_desktops_client_url" {
  description = "Secure Desktops client URL for the selected OCI region."
  value       = "https://published.desktops.${var.region}.oci.oraclecloud.com/client"
}

output "vcn_id" {
  description = "OCID of the VCN created for Secure Desktops."
  value       = oci_core_vcn.this.id
}

output "desktop_subnet_id" {
  description = "OCID of the desktop subnet."
  value       = oci_core_subnet.desktop.id
}

output "desktop_pool_nsg_id" {
  description = "NSG associated with the Secure Desktops pool."
  value       = oci_core_network_security_group.desktop_pool.id
}

output "private_access_subnet_id" {
  description = "OCID of the private access subnet when private access is enabled."
  value       = try(oci_core_subnet.private_access[0].id, null)
}

output "private_access_nsg_id" {
  description = "NSG associated with the Secure Desktops private endpoint when enabled."
  value       = try(oci_core_network_security_group.private_access[0].id, null)
}

output "private_access_endpoint_fqdn" {
  description = "Private endpoint FQDN returned by OCI Secure Desktops when private access is enabled."
  value       = try(oci_desktops_desktop_pool.this.private_access_details[0].endpoint_fqdn, null)
}

output "private_access_endpoint_private_ip" {
  description = "Private IP of the Secure Desktops private endpoint when private access is enabled."
  value       = try(oci_desktops_desktop_pool.this.private_access_details[0].private_ip, null)
}
