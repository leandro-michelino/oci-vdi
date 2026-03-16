#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "${ROOT_DIR}/terraform.tfvars" ]]; then
  echo "[ERROR] Missing terraform.tfvars." >&2
  echo "[INFO] Run ./scripts/deploy-interactive.sh first, or copy terraform.tfvars.example to terraform.tfvars." >&2
  exit 1
fi

terraform -chdir="${ROOT_DIR}" fmt -recursive
terraform -chdir="${ROOT_DIR}" init
terraform -chdir="${ROOT_DIR}" validate
terraform -chdir="${ROOT_DIR}" plan -out tfplan
terraform -chdir="${ROOT_DIR}" apply -auto-approve tfplan
terraform -chdir="${ROOT_DIR}" output
