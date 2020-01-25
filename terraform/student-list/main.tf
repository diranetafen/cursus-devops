# create the docker network
resource "docker_network" "docker_network" {
  name   = var.docker_network
  driver = "bridge" 
}

# create frontend container
resource "docker_container" "frontend" {
  name     = var.frontend_container_name
  image    = var.frontend_container_image
  hostname = var.frontend_container_name
  ports {
    internal = var.frontend_container_ports["internal"]
    external = var.frontend_container_ports["external"] 
  }
  mounts {
    type   = "bind"
    source = "/home/centos/cursus-devops/terraform/student-list/student-list/website"
    target = "/var/www/html"
  }
  env = ["USERNAME=toto", "PASSWORD=python"]
  restart = "always"
  networks_advanced {
    name = var.docker_network
  } 
}

# create wordpress container
resource "docker_container" "api" {
  name  = var.api_container_name
  image = var.api_container_image
  hostname = var.api_container_name
  restart = "always"
  ports {
    internal = var.api_container_ports["internal"]
    external = var.api_container_ports["external"]
  }
  mounts {
    type   = "bind"
    source = "/home/centos/cursus-devops/terraform/student-list/student-list/simple_api/student_age.json"
    target = "/data/student_age.json"
  } 
  networks_advanced {
    name = var.docker_network
  }
}
