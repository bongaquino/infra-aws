locals {
  # bongaquino Developers
  bongaquino_developers = {
    "test.dev1" = {
      username   = "test.dev1-bongaquino"
      department = "developers"
<<<<<<< HEAD
      team       = "bongaquino"
=======
      team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
      email      = "test.dev1@bongaquino.com"
      role       = "test-developer"
    }
  }

  # bongaquino DevOps
  bongaquino_devops = {
    "test.devops1" = {
      username   = "test.devops1-bongaquino"
      department = "devops"
<<<<<<< HEAD
      team       = "bongaquino"
=======
      team       = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
      email      = "test.devops1@bongaquino.com"
      role       = "test-devops"
    }
  }

  # Merge all user maps
  all_users = merge(
    local.bongaquino_developers,
    local.bongaquino_devops
  )
} 