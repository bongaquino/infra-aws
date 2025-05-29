locals {
  # ARData Developers
  ardata_developers = {
    "test.dev1" = {
      username   = "test.dev1-ardata"
      department = "developers"
      team       = "ardata"
      email      = "test.dev1@ardata.com"
      role       = "test-developer"
    }
  }

  # ARData DevOps
  ardata_devops = {
    "test.devops1" = {
      username   = "test.devops1-ardata"
      department = "devops"
      team       = "ardata"
      email      = "test.devops1@ardata.com"
      role       = "test-devops"
    }
  }

  # Merge all user maps
  all_users = merge(
    local.ardata_developers,
    local.ardata_devops
  )
} 