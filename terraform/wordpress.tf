provider "docker" {}

# declare any input variables

# create docker volume resource

# create docker network resource

# create db container
resource "docker_container" "db" {
  name  = "db"
  image = "mysql:5.7"
  restart = "always"
}

# create wordpress container
resource "docker_container" "wordpress" {
  name  = "wordpress"
  image = "wordpress:latest"
  restart = "always"
  ports {
    internal = "80"
    external = "80"
  }
}
