variable "external_port" {
    description = "The port on the host machine to map to the Nginx container."
    type        = number
    default     = 8080
}

variable "network_name" {
  description = "The name of the Docker network."
  type        = string
}