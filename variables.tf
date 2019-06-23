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

########
# Disks

variable "ebs_optimized" {
  type    = bool
  default = true
}

variable "root_size" {
  type    = number
  default = "10"
}

variable "additional_disks" {
  type = list(object({
    size = number
    type = string
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
