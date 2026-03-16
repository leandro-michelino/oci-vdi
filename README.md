# oci-secure-desktops

Terraform repository for OCI Secure Desktops.

## What this repository creates

- Private VCN
- Private desktop subnet
- Optional private access subnet
- NAT Gateway
- Service Gateway
- NSGs for desktop VNICs and optional private access endpoint
- OCI Secure Desktops desktop pool

## What this repository does not create

- Legacy XRDP host VM
- Bastion host
- VPN, FastConnect, or DRG
- Desktop image build process itself

## Important service behaviors

- OCI Secure Desktops requires at least 10 desktops per pool.
- `availability_policy {}` is required even if you do not define a recurring schedule.
- `disconnect_action = STOP` cannot be used together with a recurring availability schedule.
- Private access is chosen when the pool is created and should be treated as a creation-time design choice.
- Desktop pool NSGs should be considered creation-time sensitive and planned carefully before apply.

## Prerequisites

- Terraform 1.5 or newer
- OCI provider 8.5.x
- Custom image already prepared for Secure Desktops
- OCI API key configured locally
- Block Volume backup policy OCID available for desktop storage
- Required IAM policies for network, block volume, and secure-desktops resources

## Quick start

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## New repository workflow

If you want to publish this as a brand new Git repository named `oci-secure-desktops`, use the commands in `git-init-commands.txt`.
