# Deployment Guide

## Scope

This guide covers the deployment of OCI Secure Desktops with Terraform in a Git-only repository model.

## Prerequisites

Before deploying, confirm the following:

- Terraform is installed
- OCI API key authentication is configured
- Your target region supports OCI Secure Desktops
- You have a desktop image prepared for OCI Secure Desktops
- You have a valid Block Volume backup policy OCID
- You have sufficient Secure Desktops limits in the target tenancy and region
- You understand that the minimum pool size is 10 desktops

## Guided deployment

The simplest path is the interactive helper:

```bash
chmod +x scripts/deploy-interactive.sh
./scripts/deploy-interactive.sh
```

The script will ask for:

- OCI provider values
- compartment OCID
- availability domain
- desktop image OCID and image name
- shape, OCPUs, and memory
- pool size
- storage backup policy
- network CIDRs
- private access options
- session lifecycle settings
- optional availability schedule

The script writes `terraform.tfvars`, then runs:

- `terraform fmt`
- `terraform init`
- `terraform validate`

It will ask whether you want to run `plan` and `apply`.

## Manual deployment

If you prefer not to use the interactive helper:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform fmt -recursive
terraform init
terraform validate
terraform plan -out tfplan
terraform apply tfplan
```

## Secure Desktops design choices in this repository

This repository intentionally uses OCI Secure Desktops and not a standalone compute instance.

Included components:

- private subnet for desktops
- optional private access subnet for endpoint placement
- NAT Gateway for egress
- NSG attached to the desktop pool
- optional NSG for the private access endpoint
- device policy controls
- inactivity and disconnect lifecycle actions

## IAM guidance

Typical administrator permissions include managing the desktop pool family and using virtual-network-family in the relevant compartment.

Typical end-user access is granted with `published-desktops` in the desktop pool compartment.

Adjust IAM to your compartment structure and security model.

## Operational notes

- Keep `terraform.tfvars` out of Git
- Keep `.terraform`, `tfplan`, and state files out of Git
- Review desktop image lifecycle and patching outside this repository
- If you enable private access, validate routing, DNS, and source CIDR reachability before user testing
- If you enable availability schedules, keep `disconnect_action = "NONE"`

## Legacy migration note

The earlier version of this repository used:

- `oci_core_instance`
- `oci_core_volume`
- `oci_core_volume_attachment`
- XRDP
- cloud-init bootstrap

Those components are no longer part of the Secure Desktops design and should stay removed.
