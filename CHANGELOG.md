# Change Log

## v1.0.0
- Rebuilt the repository around `oci_desktops_desktop_pool`
- Removed the legacy single-VM VDI design
- Added private VCN, private subnet, optional private access subnet, NAT, and Service Gateway
- Added NSGs for desktop VNICs and optional private access endpoint
- Added lifecycle guardrails for minimum pool size, schedule compatibility, and storage sizing
- Added support for Flex and fixed shapes
- Added outputs, tfvars example, README, and new-repository Git commands
