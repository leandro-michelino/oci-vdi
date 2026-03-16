variable "tenancy_ocid" {
  description = "OCI tenancy OCID."
  type        = string
}

variable "user_ocid" {
  description = "OCI user OCID used by the Terraform provider."
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the OCI API key."
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API private key on the machine running Terraform."
  type        = string
}

variable "region" {
  description = "OCI region identifier, for example eu-madrid-1."
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID where Secure Desktops resources are created."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the desktop pool, for example EU-MADRID-1-AD-1."
  type        = string
}

variable "project_name" {
  description = "Project name used as a prefix for network resources."
  type        = string
  default     = "oci-secure-desktops"
}

variable "desktop_pool_display_name" {
  description = "Display name of the Secure Desktops pool."
  type        = string
}

variable "desktop_pool_description" {
  description = "Description for the Secure Desktops pool."
  type        = string
  default     = "OCI Secure Desktops pool managed by Terraform."
}

variable "contact_details" {
  description = "Administrative contact details shown on the desktop pool. Avoid confidential data."
  type        = string
}

variable "desktop_image_id" {
  description = "OCID of the custom image prepared for OCI Secure Desktops."
  type        = string
}

variable "desktop_image_name" {
  description = "Friendly name of the desktop image."
  type        = string
}

variable "desktop_operating_system" {
  description = "Operating system name of the desktop image, for example Oracle Linux or Windows."
  type        = string
  default     = "Oracle Linux"
}

variable "desktop_shape_name" {
  description = "Shape used for each desktop in the pool."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "desktop_ocpus" {
  description = "Number of OCPUs assigned to each desktop. Used only for Flex shapes."
  type        = number
  default     = 2
}

variable "desktop_memory_gbs" {
  description = "Memory in GB assigned to each desktop. Used only for Flex shapes."
  type        = number
  default     = 16
}

variable "desktop_baseline_ocpu_utilization" {
  description = "Baseline OCPU utilization for burstable Flex shapes. Use BASELINE_1_1 for non-burstable."
  type        = string
  default     = "BASELINE_1_1"

  validation {
    condition = contains([
      "BASELINE_1_8",
      "BASELINE_1_2",
      "BASELINE_1_1"
    ], upper(var.desktop_baseline_ocpu_utilization))
    error_message = "desktop_baseline_ocpu_utilization must be BASELINE_1_8, BASELINE_1_2, or BASELINE_1_1."
  }
}

variable "maximum_size" {
  description = "Maximum number of desktops allowed in the pool. OCI Secure Desktops requires at least 10."
  type        = number
  default     = 10
}

variable "standby_size" {
  description = "Number of standby desktops kept ready in the pool."
  type        = number
  default     = 1
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB for each desktop."
  type        = number
  default     = 100
}

variable "is_storage_enabled" {
  description = "Enable dedicated user storage for each desktop."
  type        = bool
  default     = true
}

variable "storage_size_in_gbs" {
  description = "Size in GB of the dedicated storage volume when storage is enabled."
  type        = number
  default     = 50
}

variable "storage_backup_policy_id" {
  description = "OCID of the Block Volume backup policy used for desktop storage."
  type        = string
}

variable "are_privileged_users" {
  description = "Whether desktop users receive administrative privileges inside the desktop OS."
  type        = bool
  default     = false
}

variable "use_dedicated_vm_host" {
  description = "Whether the desktop pool uses dedicated VM hosts."
  type        = bool
  default     = false
}

variable "are_volumes_preserved" {
  description = "Whether volumes are preserved when the pool is deleted."
  type        = bool
  default     = true
}

variable "vcn_cidr" {
  description = "CIDR block for the Secure Desktops VCN."
  type        = string
  default     = "10.60.0.0/16"
}

variable "desktop_subnet_cidr" {
  description = "CIDR block for the private desktop subnet."
  type        = string
  default     = "10.60.10.0/24"
}

variable "private_access_enabled" {
  description = "Enable the Secure Desktops private endpoint."
  type        = bool
  default     = false
}

variable "private_access_subnet_cidr" {
  description = "CIDR block for the private access endpoint subnet when enabled."
  type        = string
  default     = "10.60.20.0/24"
}

variable "allow_private_access_cidr" {
  description = "Source CIDR allowed to reach the private access endpoint on HTTPS."
  type        = string
  default     = "10.0.0.0/8"
}

variable "private_access_endpoint_ip" {
  description = "Optional static private IP for the Secure Desktops private endpoint. Leave empty to auto-assign."
  type        = string
  default     = ""
}

variable "disconnect_action" {
  description = "Action taken after disconnect. Allowed values are NONE or STOP."
  type        = string
  default     = "STOP"

  validation {
    condition     = contains(["NONE", "STOP"], upper(var.disconnect_action))
    error_message = "disconnect_action must be NONE or STOP."
  }
}

variable "disconnect_grace_period_in_minutes" {
  description = "Minutes to wait after disconnect before the disconnect action runs."
  type        = number
  default     = 60
}

variable "inactivity_action" {
  description = "Action taken after inactivity. Allowed values are NONE or DISCONNECT."
  type        = string
  default     = "DISCONNECT"

  validation {
    condition     = contains(["NONE", "DISCONNECT"], upper(var.inactivity_action))
    error_message = "inactivity_action must be NONE or DISCONNECT."
  }
}

variable "inactivity_grace_period_in_minutes" {
  description = "Minutes of inactivity before the inactivity action runs."
  type        = number
  default     = 30
}

variable "audio_mode" {
  description = "Audio device policy. Allowed values: NONE, TODESKTOP, FROMDESKTOP, FULL."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "TODESKTOP", "FROMDESKTOP", "FULL"], upper(var.audio_mode))
    error_message = "audio_mode must be NONE, TODESKTOP, FROMDESKTOP, or FULL."
  }
}

variable "cdm_mode" {
  description = "Client drive mapping policy. Allowed values: NONE, READONLY, FULL."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "READONLY", "FULL"], upper(var.cdm_mode))
    error_message = "cdm_mode must be NONE, READONLY, or FULL."
  }
}

variable "clipboard_mode" {
  description = "Clipboard policy. Allowed values: NONE, TODESKTOP, FROMDESKTOP, FULL."
  type        = string
  default     = "NONE"

  validation {
    condition     = contains(["NONE", "TODESKTOP", "FROMDESKTOP", "FULL"], upper(var.clipboard_mode))
    error_message = "clipboard_mode must be NONE, TODESKTOP, FROMDESKTOP, or FULL."
  }
}

variable "is_display_enabled" {
  description = "Whether display output is enabled."
  type        = bool
  default     = true
}

variable "is_keyboard_enabled" {
  description = "Whether keyboard input is enabled."
  type        = bool
  default     = true
}

variable "is_pointer_enabled" {
  description = "Whether pointer input is enabled."
  type        = bool
  default     = true
}

variable "is_printing_enabled" {
  description = "Whether printing is enabled."
  type        = bool
  default     = false
}

variable "is_video_input_enabled" {
  description = "Whether webcam or video input is enabled."
  type        = bool
  default     = false
}

variable "availability_policy_enabled" {
  description = "Whether to define a desktop availability schedule."
  type        = bool
  default     = false
}

variable "availability_start_cron_expression" {
  description = "Cron expression for the desktop start schedule when availability scheduling is enabled."
  type        = string
  default     = ""
}

variable "availability_start_timezone" {
  description = "Timezone for the start schedule."
  type        = string
  default     = "Europe/Madrid"
}

variable "availability_stop_cron_expression" {
  description = "Cron expression for the desktop stop schedule when availability scheduling is enabled."
  type        = string
  default     = ""
}

variable "availability_stop_timezone" {
  description = "Timezone for the stop schedule."
  type        = string
  default     = "Europe/Madrid"
}

variable "time_start_scheduled" {
  description = "Optional RFC3339 start time for the desktop pool. Leave null to let the service decide."
  type        = string
  default     = null
  nullable    = true
}

variable "time_stop_scheduled" {
  description = "Optional RFC3339 stop time for the desktop pool. Leave null to let the service decide."
  type        = string
  default     = null
  nullable    = true
}

variable "desktop_pool_create_timeout" {
  description = "Terraform timeout for creating the desktop pool."
  type        = string
  default     = "30m"
}

variable "desktop_pool_update_timeout" {
  description = "Terraform timeout for updating the desktop pool."
  type        = string
  default     = "30m"
}

variable "desktop_pool_delete_timeout" {
  description = "Terraform timeout for deleting the desktop pool."
  type        = string
  default     = "30m"
}

variable "freeform_tags" {
  description = "Freeform tags applied to all supported resources."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to all supported resources."
  type        = map(string)
  default     = {}
}
