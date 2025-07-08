output "nginx_url" {
  description = "The full URL for the Nginx webserver."
  value       = "http://localhost:${docker_container.nginx_web.ports[0].external}"
}
