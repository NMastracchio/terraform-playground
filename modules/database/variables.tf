variable "db_password" {
  description = "The password for the PostgreSQL database user."
  type        = string
  sensitive   = true
}

variable "network_name" {
  description = "The name of the docker network to connect the container to."
  type        = string
}
