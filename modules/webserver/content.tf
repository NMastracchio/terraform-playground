resource "local_file" "homepage" {
  content  = "<h1>Welcome to My Terraform Project!</h1><p>This page is managed by Terraform.</p>"
  filename = "${path.cwd}/index.html"
}
