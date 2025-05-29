# IAM Module

This module manages IAM users, groups, and policies for the Koneksi and ARData team.

## Features

- Creates IAM groups for different team roles (Developers, DevOps)
- Manages IAM users with appropriate permissions
- Creates and manages access keys for users
- Applies least privilege principle through role-based access control

## Groups and Permissions

### Developers Group
- Read-only access to EC2 instances
- Basic DynamoDB operations (CRUD)
- Read-only access to ElastiCache
- Basic S3 operations

### DevOps Group
- Full access to EC2, DynamoDB, ElastiCache, and S3
- Read-only access to IAM information
- Ability to view and list IAM resources

## Usage

1. Define your users in the `terraform.tfvars` file:
```hcl
users = {
  "developer1" = {
    username   = "developer1"
    department = "developers"
  }
  "devops1" = {
    username   = "devops1"
    department = "devops"
  }
}
```

2. Initialize and apply the configuration:
```bash
terraform init
terraform plan
terraform apply
```

3. Retrieve access keys (they will be marked as sensitive):
```bash
terraform output user_access_keys
```

## Security Considerations

1. Access keys are created for each user and should be securely distributed
2. Users are automatically added to appropriate groups based on their department
3. Policies follow the principle of least privilege
4. All resources are tagged for better management

## Outputs

- `user_access_keys`: Map of usernames to their access keys (sensitive)
- `user_arns`: Map of usernames to their ARNs
- `group_arns`: Map of group names to their ARNs

## Best Practices

1. Rotate access keys regularly
2. Review and update permissions as needed
3. Use IAM roles for EC2 instances when possible
4. Monitor IAM activity through CloudTrail
5. Regularly audit user permissions 