resource "docker_image" "postgres_image" {
  name = "postgres:15-alpine"
}

# Create the postgres container
resource "docker_container" "postgres_db" {
  name  = "my-postgres-db"
  image = docker_image.postgres_image.name

  # Connect this container to the network we created.
  networks_advanced {
    name = var.network_name
  }

  # Set required environment variables for postgres.
  # WARNING: Never hardcode passwords in a real project! Use variables.
  env = [
    "POSTGRES_USER=admin",
    "POSTGRES_PASSWORD=${var.db_password}",
    "POSTGRES_DB=appdb"
  ]

  volumes {
    volume_name    = docker_volume.postgres_data.name
    container_path = "/var/lib/postgresql/data"
  }

  # This makes sure the network is created *before* this container.
  depends_on = [
    var.network_name
  ]
}

resource "docker_volume" "postgres_data" {
  name = "postgres-data-volume"
}
