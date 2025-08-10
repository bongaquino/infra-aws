aws_region = "ap-southeast-1"

project     = "bongaquino"
name_prefix = "bongaquino"

tags = {
  Project   = "bongaquino"
  ManagedBy = "terraform"
}

users = {
  franz_egos = {
    username   = "franz.egos-bongaquino"
    department = "developers"
    team       = "bongaquino"
    email      = "franz@bongaquino.tech"
    role       = "Developer"
  }
  devops_admin = {
    username   = "bong.aquino-bongaquino"
    department = "devops"
    team       = "bongaquino"
    email      = "bong@bongaquino.tech"
    role       = "Operations"
  }
  # Add more users here following the same structure
  # example:
  # john_doe = {
  #   username   = "john.doe-bongaquino"
  #   department = "devops"
  #   team       = "bongaquino"
  #   email      = "john@bongaquino.tech"
  #   role       = "Operations"
  # }
}# 