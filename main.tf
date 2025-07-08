# terraform-playground/main.tf

################################################################################
# PROVIDER CONFIGURATION
################################################################################

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

provider "docker" {
  host = "unix:///Users/nmastracchio/.docker/run/docker.sock"
}

################################################################################
# SHARED RESOURCES
# Resources used by multiple modules are defined here in the root.
################################################################################

resource "docker_network" "app_network" {
  name = "my-app-network"
}

################################################################################
# MODULES
# This is where we call our reusable modules to build the infrastructure.
################################################################################

module "database" {
  source = "./modules/database"

  network_name = docker_network.app_network.name
  db_password  = var.db_password
}

module "webserver" {
  source = "./modules/webserver"

  # Pass required variables into the webserver module
  network_name  = docker_network.app_network.name
  external_port = var.external_port

  # This explicitly tells Terraform the webserver depends on the database module
  depends_on = [
    module.database
  ]
}