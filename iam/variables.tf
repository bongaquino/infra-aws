variable "project" {
  description = "Project name for naming convention and tagging"
  type        = string
  default     = "ardata"
}

variable "users" {
  description = "Map of users to create with their configurations"
  type = map(object({
    username   = string
    department = string
    team       = string
    email      = string
    role       = string
  }))
  default = {}
} 