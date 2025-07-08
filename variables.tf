variable "external_port" {
    description = "The port on the host machine to map to the Nginx container."
    type        = number
    default     = 8080
}

variable "db_password" {
  description = "The password for the PostgreSQL database user."
  type        = string
  sensitive   = true
}