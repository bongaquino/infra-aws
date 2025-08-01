# IAM Accounts Registry

This document maintains a record of all IAM accounts created in the Ardata AWS environment.

## Naming Conventions

1. **Usernames**
   - Format: `firstname.lastname-ardata` (lowercase)
   - Example: `franz.egos-ardata`, `john.doe-ardata`

2. **Roles**
   - Developer (capital D)
   - Operations (capital O)
   - Management (capital M)

3. **Departments**
   - developers (lowercase)
   - devops (lowercase)
   - management (lowercase)

4. **Teams**
   - ardata (lowercase)
   - devops (lowercase)
   - qa (lowercase)

5. **Email**
   - Format: `firstname@ardata.tech`
   - Example: `franz@ardata.tech`, `john@ardata.tech`

## Active Accounts

| Username | Department | Team | Email | Role | Created Date | Status |
|----------|------------|------|-------|------|--------------|--------|
| franz.egos-ardata | developers | ardata | franz@ardata.tech | Developer | 2024-03-19 | Active |
| bong.aquino-ardata | devops | ardata | bong@ardata.tech | Operations | 2024-12-19 | Active |

## Account History

| Username | Department | Team | Email | Role | Created Date | Deactivated Date | Reason |
|----------|------------|------|-------|------|--------------|------------------|--------|
| test.dev1-ardata | developers | ardata | test.dev1@ardata.tech | test-developer | 2024-03-19 | 2024-03-19 | Test account |
| test.devops1-ardata | devops | ardata | test.devops1@ardata.tech | test-devops | 2024-03-19 | 2024-03-19 | Test account |

## Account Management Guidelines

1. **Creating New Accounts**
   - Add the new user to `terraform.tfvars`
   - Add the user to this registry under "Active Accounts"
   - Apply changes using Terraform

2. **Deactivating Accounts**
   - Remove the user from `terraform.tfvars`
   - Move the user from "Active Accounts" to "Account History" in this registry
   - Add deactivation date and reason
   - Apply changes using Terraform

3. **Updating Account Details**
   - Update the user details in `terraform.tfvars`
   - Update the user details in this registry
   - Apply changes using Terraform

## Access Levels

1. **Developer Role**
   - Group: developers
   - Policy: PowerUserAccess
   - Permissions: 
     - Full access to all AWS services
     - Can create and manage resources
     - Can view billing information
     - Cannot manage IAM users/groups
   - Suitable for: Software developers, QA engineers

2. **Operations Role**
   - Group: operations
   - Policy: AdministratorAccess
   - Permissions: Full access to all AWS services
   - Suitable for: DevOps engineers, System administrators

3. **Management Role**
   - Group: management
   - Policy: AdministratorAccess
   - Permissions: Full access to all AWS services
   - Suitable for: Team leads, Project managers

## Security Notes

- All accounts are monitored for:
  - Failed login attempts (alarm threshold: 3 attempts)
  - Access key usage (alarm threshold: 100 uses)
- Access keys are automatically created for all users
- Users are automatically added to appropriate groups based on their role 