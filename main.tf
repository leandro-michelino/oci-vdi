# Discover the Oracle Services Network labels used by the Service Gateway.
data "oci_core_services" "all" {}

locals {
  # Normalize the project name to keep OCI resource names predictable.
  prefix = lower(replace(var.project_name, "_", "-"))

  # OCI exposes service gateway destinations as service CIDR labels. Prefer the aggregated
  # "all regional services in Oracle Services Network" entry when it exists, and fall back
  # to the first returned service only as a last resort.
  osn_service_candidates = [
    for svc in data.oci_core_services.all.services : svc
    if can(regex("^all-.*-services-in-oracle-services-network$", lower(try(svc.cidr_block, ""))))
    || (
      can(regex("services in oracle services network", lower(try(svc.name, ""))))
      && can(regex("^all", lower(try(svc.name, ""))))
    )
  ]

  osn_service = length(local.osn_service_candidates) > 0 ? local.osn_service_candidates[0] : data.oci_core_services.all.services[0]

  # Flex shapes require shape_config. Fixed shapes should not receive that block.
  is_flex_shape = can(regex("flex$", lower(var.desktop_shape_name)))

  # Attach a dedicated NSG to all desktop VNICs and, when enabled, to the private endpoint.
  desktop_pool_nsg_ids   = [oci_core_network_security_group.desktop_pool.id]
  private_access_nsg_ids = var.private_access_enabled ? [oci_core_network_security_group.private_access[0].id] : []
}

resource "oci_core_vcn" "this" {
  # Private VCN for OCI Secure Desktops.
  compartment_id = var.compartment_ocid
  cidr_block     = var.vcn_cidr
  display_name   = "${local.prefix}-vcn"
  dns_label      = substr(replace(local.prefix, "-", ""), 0, 15)

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_nat_gateway" "this" {
  # NAT lets private desktops reach outbound destinations without assigning public IPs.
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.prefix}-nat"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_service_gateway" "this" {
  # Service Gateway keeps Oracle service traffic on the Oracle backbone.
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.prefix}-sgw"

  services {
    service_id = local.osn_service.id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_route_table" "private" {
  # Shared route table for the desktop subnet and the optional private endpoint subnet.
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.prefix}-private-rt"

  # General outbound traffic leaves through NAT.
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.this.id
  }

  # OCI service traffic stays on the Oracle network through the Service Gateway.
  route_rules {
    destination       = local.osn_service.cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.this.id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_subnet" "desktop" {
  # Private subnet where Secure Desktops creates the desktop VNICs.
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.desktop_subnet_cidr
  display_name               = "${local.prefix}-desktop-subnet"
  dns_label                  = "desktop"
  route_table_id             = oci_core_route_table.private.id
  prohibit_public_ip_on_vnic = true

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_subnet" "private_access" {
  # Optional subnet for the Secure Desktops private access endpoint.
  count = var.private_access_enabled ? 1 : 0

  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.this.id
  cidr_block                 = var.private_access_subnet_cidr
  display_name               = "${local.prefix}-private-access-subnet"
  dns_label                  = "privacc"
  route_table_id             = oci_core_route_table.private.id
  prohibit_public_ip_on_vnic = true

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group" "desktop_pool" {
  # Dedicated NSG for the desktop VNICs.
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.prefix}-desktop-pool-nsg"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "desktop_pool_egress_all" {
  # Allow outbound connectivity for updates, repositories, OCI services, and application dependencies.
  network_security_group_id = oci_core_network_security_group.desktop_pool.id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_core_network_security_group" "private_access" {
  # Dedicated NSG for the optional private access endpoint.
  count = var.private_access_enabled ? 1 : 0

  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.this.id
  display_name   = "${local.prefix}-private-access-nsg"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "private_access_ingress_https" {
  # Allow HTTPS from the approved source CIDR to the private endpoint.
  count = var.private_access_enabled ? 1 : 0

  network_security_group_id = oci_core_network_security_group.private_access[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = var.allow_private_access_cidr
  source_type               = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_network_security_group_security_rule" "private_access_egress_all" {
  # Allow outbound traffic required by the private endpoint.
  count = var.private_access_enabled ? 1 : 0

  network_security_group_id = oci_core_network_security_group.private_access[0].id
  direction                 = "EGRESS"
  protocol                  = "all"
  destination               = "0.0.0.0/0"
  destination_type          = "CIDR_BLOCK"
}

resource "oci_desktops_desktop_pool" "this" {
  # Core OCI Secure Desktops resource.
  compartment_id      = var.compartment_ocid
  display_name        = var.desktop_pool_display_name
  description         = var.desktop_pool_description
  contact_details     = var.contact_details
  availability_domain = var.availability_domain

  # Desktop image configuration.
  image {
    image_id         = var.desktop_image_id
    image_name       = var.desktop_image_name
    operating_system = var.desktop_operating_system
  }

  # Compute shape for each desktop.
  shape_name = var.desktop_shape_name

  dynamic "shape_config" {
    for_each = local.is_flex_shape ? [1] : []

    content {
      ocpus                     = var.desktop_ocpus
      memory_in_gbs             = var.desktop_memory_gbs
      baseline_ocpu_utilization = var.desktop_baseline_ocpu_utilization
    }
  }

  # Pool sizing and storage settings.
  maximum_size             = var.maximum_size
  standby_size             = var.standby_size
  boot_volume_size_in_gbs  = var.boot_volume_size_in_gbs
  is_storage_enabled       = var.is_storage_enabled
  storage_size_in_gbs      = var.storage_size_in_gbs
  storage_backup_policy_id = var.storage_backup_policy_id
  are_privileged_users     = var.are_privileged_users
  use_dedicated_vm_host    = var.use_dedicated_vm_host
  are_volumes_preserved    = var.are_volumes_preserved

  # Optional one-off administrative schedule values exposed by the provider.
  time_start_scheduled = var.time_start_scheduled
  time_stop_scheduled  = var.time_stop_scheduled

  # Place desktop VNICs in the private subnet.
  network_configuration {
    subnet_id = oci_core_subnet.desktop.id
    vcn_id    = oci_core_vcn.this.id
  }

  # NSGs are chosen at pool creation time, so configure them carefully up front.
  nsg_ids = local.desktop_pool_nsg_ids

  # OCI requires this block even when no recurring schedule is configured.
  availability_policy {
    dynamic "start_schedule" {
      for_each = var.availability_policy_enabled ? [1] : []

      content {
        cron_expression = var.availability_start_cron_expression
        timezone        = var.availability_start_timezone
      }
    }

    dynamic "stop_schedule" {
      for_each = var.availability_policy_enabled ? [1] : []

      content {
        cron_expression = var.availability_stop_cron_expression
        timezone        = var.availability_stop_timezone
      }
    }
  }

  # Session lifecycle actions control cost and user experience for idle or disconnected sessions.
  session_lifecycle_actions {
    disconnect {
      action                  = upper(var.disconnect_action)
      grace_period_in_minutes = var.disconnect_grace_period_in_minutes
    }

    inactivity {
      action                  = upper(var.inactivity_action)
      grace_period_in_minutes = var.inactivity_grace_period_in_minutes
    }
  }

  # Device controls for clipboard, audio, client drives, printing, keyboard, pointer, and video input.
  device_policy {
    audio_mode             = upper(var.audio_mode)
    cdm_mode               = upper(var.cdm_mode)
    clipboard_mode         = upper(var.clipboard_mode)
    is_display_enabled     = var.is_display_enabled
    is_keyboard_enabled    = var.is_keyboard_enabled
    is_pointer_enabled     = var.is_pointer_enabled
    is_printing_enabled    = var.is_printing_enabled
    is_video_input_enabled = var.is_video_input_enabled
  }

  # Private access can only be chosen when the pool is created.
  dynamic "private_access_details" {
    for_each = var.private_access_enabled ? [1] : []

    content {
      subnet_id  = oci_core_subnet.private_access[0].id
      nsg_ids    = local.private_access_nsg_ids
      private_ip = trimspace(var.private_access_endpoint_ip) != "" ? var.private_access_endpoint_ip : null
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  timeouts {
    create = var.desktop_pool_create_timeout
    update = var.desktop_pool_update_timeout
    delete = var.desktop_pool_delete_timeout
  }

  lifecycle {
    precondition {
      condition     = var.maximum_size >= 10
      error_message = "OCI Secure Desktops requires maximum_size to be at least 10 desktops."
    }

    precondition {
      condition     = var.standby_size >= 0 && var.standby_size <= var.maximum_size
      error_message = "standby_size must be zero or greater and cannot be greater than maximum_size."
    }

    precondition {
      condition     = var.availability_policy_enabled ? upper(var.disconnect_action) == "NONE" : true
      error_message = "disconnect_action must be NONE when availability_policy_enabled is true."
    }

    precondition {
      condition     = var.is_storage_enabled ? var.storage_size_in_gbs > 0 : true
      error_message = "storage_size_in_gbs must be greater than zero when is_storage_enabled is true."
    }

    precondition {
      condition = var.availability_policy_enabled ? (
        trimspace(var.availability_start_cron_expression) != "" && trimspace(var.availability_stop_cron_expression) != ""
      ) : true
      error_message = "Both availability_start_cron_expression and availability_stop_cron_expression must be set when availability_policy_enabled is true."
    }
  }
}
