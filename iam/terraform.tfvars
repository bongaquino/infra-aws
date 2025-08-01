aws_region = "ap-southeast-1"

project     = "ardata"
name_prefix = "ardata"

tags = {
  Project   = "ardata"
  ManagedBy = "terraform"
}

users = {
  franz_egos = {
    username   = "franz.egos-ardata"
    department = "developers"
    team       = "ardata"
    email      = "franz@ardata.tech"
    role       = "Developer"
  }
  devops_admin = {
    username   = "bong.aquino-ardata"
    department = "devops"
    team       = "ardata"
    email      = "bong@ardata.tech"
    role       = "Operations"
  }
  # Add more users here following the same structure
  # example:
  # john_doe = {
  #   username   = "john.doe-ardata"
  #   department = "devops"
  #   team       = "ardata"
  #   email      = "john@ardata.tech"
  #   role       = "Operations"
  # }
}# 