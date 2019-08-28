variable "instance_count" {
  type    = number
  default = 1
}

variable "key_pair" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "connection" {
  default = {}
}

variable "region" {
  type    = string
  default = ""
}

variable "ansible_check" {
  type    = bool
  default = false
}

variable "vpc" {
  type    = bool
  default = true
}

######
# EC2

variable "instance_type" {
  type = string
}

variable "ami" {
  type = string
}

variable "additional_user_data" {
  default = "#cloud-config\n"
}

variable "iam_instance_profile" {
  type    = string
  default = ""
}

variable "source_dest_check" {
  type    = bool
  default = true
}

variable "monitoring" {
  description = "If true, the launched EC2 instance will have detailed monitoring enabled."
  type        = bool
  default     = true
}

##########
# Volumes

variable "ebs_optimized" {
  type    = bool
  default = true
}

variable "root_size" {
  type    = number
  default = "10"
}

variable "additional_volumes" {
  type = list(object({
    name        = string
    size        = number
    type        = string
    device_name = string
    mount_path  = string
    fstype      = string
  }))
  default = []
}

##########
# Network

variable "public_ip" {
  type    = bool
  default = true
}

variable "eip" {
  type    = bool
  default = true
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "private_ips" {
  type    = list(string)
  default = []
}

variable "security_groups" {
  type    = list(string)
  default = []
}

##########
# Rancher

variable "rancher" {
  type = object({
    environment_id = string
    host_labels    = map(string)
  })
  default = null
}

#########
# Puppet

variable "puppet" {
  type    = map(string)
  default = null
}
