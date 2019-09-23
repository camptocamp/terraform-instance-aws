###
# Variables
#
variable "key_pair" {}

###
# Datasources
#
data "pass_password" "puppet_autosign_psk" {
  path = "terraform/c2c_mgmtsrv/puppet_autosign_psk"
}

###
# Code to test
#
variable "instance_count" {
  default = 1
}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

module "instance" {
  source         = "../../"
  instance_count = var.instance_count
  key_pair       = var.key_pair

  security_groups = []
  subnet_ids      = ["subnet-0ae8b71b5b9926c31"]

  ami           = data.aws_ami.ami.id
  instance_type = "t2.micro"
  ebs_optimized = false
  eip           = false

  tags = {
    Name = "terraform-instance-aws testing"
  }

  puppet = {
    autosign_psk      = data.pass_password.puppet_autosign_psk.data["puppet_autosign_psk"]
    server_address    = "puppet.camptocamp.com"
    ca_server_address = "puppetca.camptocamp.com"
    role              = "base"
    environment       = "staging4"
  }

  rancher = {
    environment_id = "1a5"
    host_labels = {
      foo = "bar"
      bar = "baz"
    }
  }
}

###
# Acceptance test
#
resource "null_resource" "acceptance" {
  count      = var.instance_count
  depends_on = ["module.instance"]

  connection {
    host = coalesce(module.instance.this_instance_public_ipv4[count.index], (length(module.instance.this_instance_public_ipv6[count.index]) > 0 ? module.instance.this_instance_public_ipv6[count.index][0] : ""))
    type = "ssh"
    user = "root"
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "file" {
    source      = "goss.yaml"
    destination = "/root/goss.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh",
    ]
  }
}
