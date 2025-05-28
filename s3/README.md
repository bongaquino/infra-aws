# S3 State Bucket Module

This module provisions a secure, versioned S3 bucket for storing Terraform state files for the Koneksi project.

## Usage

1. Edit `terraform.tfvars` and set a globally unique bucket name:
   ```hcl
   bucket_name = "koneksi-terraform-state-uniqueid"
   project     = "koneksi"
   environment = "shared"
   ```

2. Initialize and apply the module:
   ```sh
   terraform init
   terraform apply
   ```

3. Use the created bucket name in your environment's `backend.tf` files for remote state.

## Features
- Versioning enabled
- Public access blocked
- Standard project and environment tags

## Notes
- The bucket name must be globally unique across all AWS accounts.
- You may want to enable server-side encryption or add lifecycle rules for production use. 