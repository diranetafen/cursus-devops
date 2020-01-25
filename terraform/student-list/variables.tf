# Env to deploy student-list app using docker

#variable "credentials" {
#    type = map
#    default = {
#        "login"    = "toto"
#        "password" = "python"
#    }
#}

variable "frontend_container_ports" {
    type = map
    default = {
        "internal"    = 80
        "external"    = 80
    }
}

variable "api_container_ports" {
    type = map
    default = {
        "internal"  = 5000
        "external"  = 5000
    }
}

variable "frontend_container_name" {
  type        = string
  description = "the name of the container frontend"
  default     = "frontend"
}

variable "api_container_name" {
  type        = string
  description = "the name of the container api"
  default     = "pozos-api"
}

variable "frontend_container_image" {
  type        = string
  description = "the name of the container frontend"
  default     = "php:apache"
}

variable "api_container_image" {
  type        = string
  description = "the name of the container api"
  default     = "dirane/student-list-api:v1"
}


variable "docker_network" {
  type        = string
  description = "the name of the docker network"
  default     = "student-list_network"
}
