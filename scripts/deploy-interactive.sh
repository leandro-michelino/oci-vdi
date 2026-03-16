#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TFVARS_FILE="${ROOT_DIR}/terraform.tfvars"

info() { printf "\n[INFO] %s\n" "$1"; }
warn() { printf "\n[WARN] %s\n" "$1"; }
error() { printf "\n[ERROR] %s\n" "$1" >&2; }

require_command() {
  local cmd="$1"
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    error "Required command not found: ${cmd}"
    exit 1
  fi
}

ask() {
  local prompt="$1"
  local default_value="${2:-}"
  local answer
  if [[ -n "${default_value}" ]]; then
    read -r -p "${prompt} [${default_value}]: " answer
    printf '%s' "${answer:-$default_value}"
  else
    read -r -p "${prompt}: " answer
    printf '%s' "${answer}"
  fi
}

ask_required() {
  local prompt="$1"
  local default_value="${2:-}"
  local answer=""
  while [[ -z "${answer}" ]]; do
    answer="$(ask "${prompt}" "${default_value}")"
    if [[ -z "${answer}" ]]; then
      warn "This value is required."
    fi
  done
  printf '%s' "${answer}"
}

ask_bool() {
  local prompt="$1"
  local default_value="${2:-false}"
  local answer
  while true; do
    answer="$(ask "${prompt} (true/false)" "${default_value}")"
    case "${answer,,}" in
      true|false)
        printf '%s' "${answer,,}"
        return 0
        ;;
      *)
        warn "Please answer true or false."
        ;;
    esac
  done
}

ask_number() {
  local prompt="$1"
  local default_value="${2:-}"
  local answer
  while true; do
    answer="$(ask "${prompt}" "${default_value}")"
    if [[ "${answer}" =~ ^[0-9]+$ ]]; then
      printf '%s' "${answer}"
      return 0
    fi
    warn "Please enter a whole number."
  done
}

confirm() {
  local prompt="$1"
  local answer
  while true; do
    read -r -p "${prompt} [y/N]: " answer
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no|"") return 1 ;;
      *) warn "Please answer y or n." ;;
    esac
  done
}

write_tfvars() {
  cat > "${TFVARS_FILE}" <<EOF
tenancy_ocid     = "${TENANCY_OCID}"
user_ocid        = "${USER_OCID}"
fingerprint      = "${FINGERPRINT}"
private_key_path = "${PRIVATE_KEY_PATH}"
region           = "${REGION}"
compartment_ocid = "${COMPARTMENT_OCID}"

availability_domain = "${AVAILABILITY_DOMAIN}"

project_name              = "${PROJECT_NAME}"
desktop_pool_display_name = "${DESKTOP_POOL_DISPLAY_NAME}"
desktop_pool_description  = "${DESKTOP_POOL_DESCRIPTION}"
contact_details           = "${CONTACT_DETAILS}"

desktop_image_id         = "${DESKTOP_IMAGE_ID}"
desktop_image_name       = "${DESKTOP_IMAGE_NAME}"
desktop_operating_system = "${DESKTOP_OPERATING_SYSTEM}"

desktop_shape_name                = "${DESKTOP_SHAPE_NAME}"
desktop_ocpus                     = ${DESKTOP_OCPUS}
desktop_memory_gbs                = ${DESKTOP_MEMORY_GBS}
desktop_baseline_ocpu_utilization = "${DESKTOP_BASELINE_OCPU_UTILIZATION}"

maximum_size            = ${MAXIMUM_SIZE}
standby_size            = ${STANDBY_SIZE}
boot_volume_size_in_gbs = ${BOOT_VOLUME_SIZE_IN_GBS}

is_storage_enabled       = ${IS_STORAGE_ENABLED}
storage_size_in_gbs      = ${STORAGE_SIZE_IN_GBS}
storage_backup_policy_id = "${STORAGE_BACKUP_POLICY_ID}"

are_privileged_users  = ${ARE_PRIVILEGED_USERS}
use_dedicated_vm_host = ${USE_DEDICATED_VM_HOST}
are_volumes_preserved = ${ARE_VOLUMES_PRESERVED}

vcn_cidr            = "${VCN_CIDR}"
desktop_subnet_cidr = "${DESKTOP_SUBNET_CIDR}"

private_access_enabled     = ${PRIVATE_ACCESS_ENABLED}
private_access_subnet_cidr = "${PRIVATE_ACCESS_SUBNET_CIDR}"
allow_private_access_cidr  = "${ALLOW_PRIVATE_ACCESS_CIDR}"
private_access_endpoint_ip = "${PRIVATE_ACCESS_ENDPOINT_IP}"

disconnect_action                  = "${DISCONNECT_ACTION}"
disconnect_grace_period_in_minutes = ${DISCONNECT_GRACE_MINUTES}
inactivity_action                  = "${INACTIVITY_ACTION}"
inactivity_grace_period_in_minutes = ${INACTIVITY_GRACE_MINUTES}

audio_mode             = "${AUDIO_MODE}"
cdm_mode               = "${CDM_MODE}"
clipboard_mode         = "${CLIPBOARD_MODE}"
is_display_enabled     = ${IS_DISPLAY_ENABLED}
is_keyboard_enabled    = ${IS_KEYBOARD_ENABLED}
is_pointer_enabled     = ${IS_POINTER_ENABLED}
is_printing_enabled    = ${IS_PRINTING_ENABLED}
is_video_input_enabled = ${IS_VIDEO_INPUT_ENABLED}

availability_policy_enabled        = ${AVAILABILITY_POLICY_ENABLED}
availability_start_cron_expression = "${AVAILABILITY_START_CRON_EXPRESSION}"
availability_start_timezone        = "${AVAILABILITY_START_TIMEZONE}"
availability_stop_cron_expression  = "${AVAILABILITY_STOP_CRON_EXPRESSION}"
availability_stop_timezone         = "${AVAILABILITY_STOP_TIMEZONE}"

freeform_tags = {
  Environment = "${TAG_ENVIRONMENT}"
  Owner       = "${TAG_OWNER}"
}
EOF
}

require_command terraform

info "This script creates terraform.tfvars interactively and can optionally run terraform plan/apply."
info "It does not depend on GitHub Actions and is intended for local use, Cloud Shell, or OCI Resource Manager source packaging."

TENANCY_OCID="$(ask_required 'OCI tenancy OCID')"
USER_OCID="$(ask_required 'OCI user OCID')"
FINGERPRINT="$(ask_required 'OCI API fingerprint')"
PRIVATE_KEY_PATH="$(ask_required 'Path to OCI API private key' "${HOME}/.oci/oci_api_key.pem")"
REGION="$(ask_required 'OCI region' 'eu-madrid-1')"
COMPARTMENT_OCID="$(ask_required 'Compartment OCID for Secure Desktops')"
AVAILABILITY_DOMAIN="$(ask_required 'Availability Domain' 'EU-MADRID-1-AD-1')"

info "Desktop pool metadata"
PROJECT_NAME="$(ask_required 'Project name prefix' 'oci-secure-desktops')"
DESKTOP_POOL_DISPLAY_NAME="$(ask_required 'Desktop pool display name' 'oci-secure-desktops-pool')"
DESKTOP_POOL_DESCRIPTION="$(ask_required 'Desktop pool description' 'OCI Secure Desktops pool deployed with Terraform.')"
CONTACT_DETAILS="$(ask_required 'Administrator contact details' 'Leandro Michelino - Cloud Engineering')"

info "Desktop image configuration"
DESKTOP_IMAGE_ID="$(ask_required 'Desktop image OCID')"
DESKTOP_IMAGE_NAME="$(ask_required 'Desktop image name')"
DESKTOP_OPERATING_SYSTEM="$(ask_required 'Desktop operating system' 'Oracle Linux')"

info "Desktop compute shape"
DESKTOP_SHAPE_NAME="$(ask_required 'Desktop shape name' 'VM.Standard.E4.Flex')"
DESKTOP_OCPUS="$(ask_number 'Desktop OCPUs' '2')"
DESKTOP_MEMORY_GBS="$(ask_number 'Desktop memory in GB' '16')"
DESKTOP_BASELINE_OCPU_UTILIZATION="$(ask_required 'Baseline OCPU utilization' 'BASELINE_1_1')"

info "Pool sizing"
MAXIMUM_SIZE="$(ask_number 'Maximum pool size (minimum 10)' '10')"
if (( MAXIMUM_SIZE < 10 )); then
  error "OCI Secure Desktops minimum pool size is 10."
  exit 1
fi
STANDBY_SIZE="$(ask_number 'Standby size' '1')"
if (( STANDBY_SIZE > MAXIMUM_SIZE )); then
  error "standby_size cannot be greater than maximum_size."
  exit 1
fi
BOOT_VOLUME_SIZE_IN_GBS="$(ask_number 'Boot volume size in GB' '100')"

info "Desktop storage"
IS_STORAGE_ENABLED="$(ask_bool 'Enable dedicated desktop storage' 'true')"
STORAGE_SIZE_IN_GBS="$(ask_number 'Storage size in GB' '50')"
STORAGE_BACKUP_POLICY_ID="$(ask_required 'Storage backup policy OCID')"
ARE_VOLUMES_PRESERVED="$(ask_bool 'Preserve volumes on delete' 'true')"

info "Security and privileges"
ARE_PRIVILEGED_USERS="$(ask_bool 'Should desktop users have admin privileges' 'false')"
USE_DEDICATED_VM_HOST="$(ask_bool 'Use dedicated VM host' 'false')"

info "Network settings"
VCN_CIDR="$(ask_required 'VCN CIDR' '10.60.0.0/16')"
DESKTOP_SUBNET_CIDR="$(ask_required 'Desktop subnet CIDR' '10.60.10.0/24')"
PRIVATE_ACCESS_ENABLED="$(ask_bool 'Enable private access endpoint' 'false')"
PRIVATE_ACCESS_SUBNET_CIDR="$(ask_required 'Private access subnet CIDR' '10.60.20.0/24')"
ALLOW_PRIVATE_ACCESS_CIDR="$(ask_required 'CIDR allowed to reach the private access endpoint over HTTPS' '10.0.0.0/8')"
PRIVATE_ACCESS_ENDPOINT_IP="$(ask 'Optional fixed private IP for the private access endpoint' '')"

info "Session lifecycle"
AVAILABILITY_POLICY_ENABLED="$(ask_bool 'Enable desktop availability schedule' 'false')"
AVAILABILITY_START_CRON_EXPRESSION=""
AVAILABILITY_START_TIMEZONE="Europe/Madrid"
AVAILABILITY_STOP_CRON_EXPRESSION=""
AVAILABILITY_STOP_TIMEZONE="Europe/Madrid"

if [[ "${AVAILABILITY_POLICY_ENABLED}" == "true" ]]; then
  DISCONNECT_ACTION="NONE"
  warn "disconnect_action must be NONE when an availability schedule is enabled."
  AVAILABILITY_START_CRON_EXPRESSION="$(ask_required 'Start schedule cron expression' '0 0 8 ? * MON-FRI')"
  AVAILABILITY_START_TIMEZONE="$(ask_required 'Start schedule timezone' 'Europe/Madrid')"
  AVAILABILITY_STOP_CRON_EXPRESSION="$(ask_required 'Stop schedule cron expression' '0 0 19 ? * MON-FRI')"
  AVAILABILITY_STOP_TIMEZONE="$(ask_required 'Stop schedule timezone' 'Europe/Madrid')"
else
  DISCONNECT_ACTION="$(ask_required 'Disconnect action (NONE or STOP)' 'STOP')"
fi

DISCONNECT_GRACE_MINUTES="$(ask_number 'Disconnect grace period in minutes' '60')"
INACTIVITY_ACTION="$(ask_required 'Inactivity action (NONE or DISCONNECT)' 'DISCONNECT')"
INACTIVITY_GRACE_MINUTES="$(ask_number 'Inactivity grace period in minutes' '30')"

info "Device policy"
AUDIO_MODE="$(ask_required 'Audio mode' 'NONE')"
CDM_MODE="$(ask_required 'Client drive mapping mode' 'NONE')"
CLIPBOARD_MODE="$(ask_required 'Clipboard mode' 'NONE')"
IS_DISPLAY_ENABLED="$(ask_bool 'Enable display' 'true')"
IS_KEYBOARD_ENABLED="$(ask_bool 'Enable keyboard' 'true')"
IS_POINTER_ENABLED="$(ask_bool 'Enable pointer' 'true')"
IS_PRINTING_ENABLED="$(ask_bool 'Enable printing' 'false')"
IS_VIDEO_INPUT_ENABLED="$(ask_bool 'Enable video input' 'false')"

info "Tags"
TAG_ENVIRONMENT="$(ask_required 'Tag Environment' 'lab')"
TAG_OWNER="$(ask_required 'Tag Owner' 'Leandro')"

write_tfvars
info "terraform.tfvars written to ${TFVARS_FILE}"

if confirm "Show the generated terraform.tfvars"; then
  printf '\n'
  cat "${TFVARS_FILE}"
  printf '\n'
fi

info "Running terraform fmt, init and validate"
terraform -chdir="${ROOT_DIR}" fmt -recursive
terraform -chdir="${ROOT_DIR}" init
terraform -chdir="${ROOT_DIR}" validate

if confirm "Run terraform plan now"; then
  terraform -chdir="${ROOT_DIR}" plan -out tfplan
fi

if confirm "Run terraform apply now"; then
  terraform -chdir="${ROOT_DIR}" apply -auto-approve tfplan
  terraform -chdir="${ROOT_DIR}" output
else
  info "No apply executed. Repository remains Git-only unless you run Terraform yourself."
fi
