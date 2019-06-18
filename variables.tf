variable "instance_count" {
  default = 1
}

variable "key_pair" {}

variable "security_groups" {
  default = []
}

variable "instance_type" {}
variable "instance_image" {}

variable "additional_user_data" {
  default = "#cloud-config\n"
}

variable "eip" {
  default = true
}

variable "ebs_optimized" {
  default = true
}

variable "instance_subnet_ids" {
  default = []
}

variable "instance_private_ips" {
  default = []
}

variable "tags" {
  default = {}
}

variable "root_size" {
  default = "10"
}

variable "iam_instance_profile" {
  default = ""
}

variable "source_dest_check" {
  default = "true"
}

variable "public_ip" {
  default = true
}
