output "database_container_name" {
  description = "The name of the Postgres container."
  value       = docker_container.postgres_db.name
}