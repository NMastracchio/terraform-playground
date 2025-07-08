resource "docker_image" "nginx_image" {
  name = "nginx:latest"
}

# Create the nginx container
resource "docker_container" "nginx_web" {
  name  = "my-nginx-web"
  image = docker_image.nginx_image.image_id

  # Connect this container to the network.
  networks_advanced {
    name = var.network_name
  }

  # Map port 8080 on your local machine to port 80 inside the container.
  ports {
    internal = 80
    external = var.external_port
  }
  volumes {
    # Reference the local_file resource directly
    host_path      = local_file.homepage.filename 

    container_path = "/usr/share/nginx/html/index.html"
    read_only      = true
  }
}
