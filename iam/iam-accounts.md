# IAM Accounts Registry

This document maintains a record of all IAM accounts created in the bongaquino AWS environment.

## Naming Conventions

1. **Usernames**
   - Format: `firstname.lastname-bongaquino` (lowercase)
   - Example: `franz.egos-bongaquino`, `john.doe-bongaquino`

2. **Roles**
   - Developer (capital D)
   - Operations (capital O)
   - Management (capital M)

3. **Departments**
   - developers (lowercase)
   - devops (lowercase)
   - management (lowercase)

4. **Teams**
   - bongaquino (lowercase)
   - devops (lowercase)
   - qa (lowercase)

5. **Email**
   - Format: `firstname@bongaquino.tech`
   - Example: `franz@bongaquino.tech`, `john@bongaquino.tech`

## Active Accounts

| Username | Department | Team | Email | Role | Created Date | Status |
|----------|------------|------|-------|------|--------------|--------|
| franz.egos-bongaquino | developers | bongaquino | franz@bongaquino.tech | Developer | 2024-03-19 | Active |
| bong.aquino-bongaquino | devops | bongaquino | bong@bongaquino.tech | Operations | 2024-12-19 | Active |

## Account History

| Username | Department | Team | Email | Role | Created Date | Deactivated Date | Reason |
|----------|------------|------|-------|------|--------------|------------------|--------|
| test.dev1-bongaquino | developers | bongaquino | test.dev1@bongaquino.tech | test-developer | 2024-03-19 | 2024-03-19 | Test account |
| test.devops1-bongaquino | devops | bongaquino | test.devops1@bongaquino.tech | test-devops | 2024-03-19 | 2024-03-19 | Test account |

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