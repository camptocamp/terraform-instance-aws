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

data "pass_password" "ssh_key" {
  path = "terraform/ssh/terraform"
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

data "aws_subnet" "default" {
  id = "subnet-0ae8b71b5b9926c31"
}

resource "aws_security_group" "tf_testing" {
  name   = "tf_testing_without_eip"
  vpc_id = data.aws_subnet.default.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-instance-aws testing"
  }
}

module "instance" {
  source         = "../../"
  instance_count = var.instance_count
  key_pair       = "terraform"

  security_groups = [aws_security_group.tf_testing.id]
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

  connection = {
    private_key = data.pass_password.ssh_key.data["id_rsa"]
  }
}

###
# Acceptance test
#
resource "null_resource" "acceptance" {
  count      = var.instance_count
  depends_on = ["module.instance"]

  connection {
    host        = coalesce(module.instance.this_instance_public_ipv4[count.index], (length(module.instance.this_instance_public_ipv6[count.index]) > 0 ? module.instance.this_instance_public_ipv6[count.index][0] : ""))
    type        = "ssh"
    user        = "terraform"
    private_key = data.pass_password.ssh_key.data["id_rsa"]
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "file" {
    source      = "goss.yaml"
    destination = "/home/terraform/goss.yaml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh",
    ]
  }
}
