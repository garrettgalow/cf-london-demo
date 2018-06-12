variable "client_id" {}
variable "client_secret" {}

variable "agent_count" {
  default = 2
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "dns_prefix" {
  default = "k8smm"
}

variable cluster_name {
  default = "k8smm"
}

variable resource_group_name {
  default = "cf-k8smm"
}

variable location {
  default = "West Europe"
}
