data "template_cloudinit_config" "config" {
  count = var.instance_count

  gzip          = false
  base64_encode = false

  part {
    filename     = "default.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = <<EOF
#cloud-config
system_info:
  default_user:
    name: terraform
    uid: '1001'
EOF
  }

  part {
    filename     = "additional.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content      = var.additional_user_data
  }

  # EBS are not always available at boot time
  part {
    filename     = "mountall.cfg"
    merge_type   = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config

runcmd:
  - [ sh, -c, "sed -i '/exit 0/i mount -a' /etc/rc.local" ]
EOF
  }
}

locals {
  private_ips_length  = length(var.private_ips)
  nvme_instance_types = ["m5", "c5", "r5"]
}

resource "aws_iam_role" "this" {
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "this" {
  role = aws_iam_role.this.id
}

resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.ami
  instance_type = var.instance_type
  subnet_id     = length(var.subnet_ids) > 0 ? var.subnet_ids[count.index % length(var.subnet_ids)] : null

  # We use length(..)==0?1:var to avoid modulo: division by 0 error, because of https://github.com/hashicorp/hil/issues/50
  private_ip                           = (local.private_ips_length == 0 ? null : element(split(" ", join(" ", var.private_ips)), count.index % (local.private_ips_length == 0 ? 1 : local.private_ips_length)))
  ebs_optimized                        = var.ebs_optimized
  vpc_security_group_ids               = var.vpc ? var.security_groups : null
  security_groups                      = var.vpc ? null : var.security_groups
  key_name                             = var.key_pair
  monitoring                           = var.monitoring
  iam_instance_profile                 = coalesce(var.iam_instance_profile, aws_iam_instance_profile.this.id)
  user_data                            = data.template_cloudinit_config.config[count.index].rendered
  source_dest_check                    = var.source_dest_check
  tags                                 = var.tags
  instance_initiated_shutdown_behavior = "stop"

  associate_public_ip_address = (var.public_ip || var.eip ? true : false)

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_size
  }

  lifecycle {
    ignore_changes = [key_name, ami, user_data, root_block_device, associate_public_ip_address, volume_tags]
  }
}

######
# EIP

resource "aws_eip" "this" {
  count = (var.eip ? var.instance_count : 0)

  tags = var.vpc ? var.tags : null
}

resource "aws_eip_association" "eip_assoc" {
  count         = (var.eip ? var.instance_count : 0)
  instance_id   = aws_instance.this[count.index].id
  allocation_id = var.vpc ? aws_eip.this[count.index].id : null
  public_ip     = var.vpc ? null : aws_eip.this[count.index].id
}

##########
# Volumes

resource "aws_ebs_volume" "this" {
  count = length(var.additional_volumes) * var.instance_count

  availability_zone = aws_instance.this[count.index % var.instance_count].availability_zone
  size              = var.additional_volumes[floor(count.index / var.instance_count)].size
  type              = var.additional_volumes[floor(count.index / var.instance_count)].type

  lifecycle {
    ignore_changes = [type]
  }

  tags = merge(var.tags, { Name = "${var.additional_volumes[floor(count.index / var.instance_count)].name} - ${var.tags.Name}" })
}

resource "aws_volume_attachment" "this" {
  count = length(var.additional_volumes) * var.instance_count

  device_name  = var.additional_volumes[floor(count.index / var.instance_count)].device_name
  volume_id    = aws_ebs_volume.this[count.index].id
  instance_id  = aws_instance.this[count.index % var.instance_count].id
  skip_destroy = false # /!\
  force_detach = true

  lifecycle {
    ignore_changes = [instance_id, volume_id, skip_destroy]
  }
}

resource "null_resource" "provisioner" {
  count      = var.instance_count
  depends_on = [aws_instance.this, aws_volume_attachment.this]

  connection {
    type                = lookup(var.connection, "type", null)
    user                = lookup(var.connection, "user", "terraform")
    password            = lookup(var.connection, "password", null)
    host                = lookup(var.connection, "host", coalesce((var.eip ? aws_eip.this[count.index].public_ip : ""), aws_instance.this[count.index].public_ip, var.public_ip ? "" : aws_instance.this[count.index].private_ip))
    port                = lookup(var.connection, "port", 22)
    timeout             = lookup(var.connection, "timeout", 60)
    script_path         = lookup(var.connection, "script_path", null)
    private_key         = lookup(var.connection, "private_key", null)
    agent               = lookup(var.connection, "agent", null)
    agent_identity      = lookup(var.connection, "agent_identity", null)
    host_key            = lookup(var.connection, "host_key", null)
    https               = lookup(var.connection, "https", false)
    insecure            = lookup(var.connection, "insecure", false)
    use_ntlm            = lookup(var.connection, "use_ntlm", false)
    cacert              = lookup(var.connection, "cacert", null)
    bastion_host        = lookup(var.connection, "bastion_host", null)
    bastion_host_key    = lookup(var.connection, "bastion_host_key", null)
    bastion_port        = lookup(var.connection, "bastion_port", 22)
    bastion_user        = lookup(var.connection, "bastion_user", null)
    bastion_password    = lookup(var.connection, "bastion_password", null)
    bastion_private_key = lookup(var.connection, "bastion_private_key", null)
  }

  provisioner "ansible" {
    plays {
      playbook {
        file_path  = "${path.module}/ansible-data/playbooks/instance.yml"
        roles_path = ["${path.module}/ansible-data/roles"]
      }

      groups = ["instance"]
      become = true
      diff   = true
      check  = var.ansible_check

      extra_vars = {
        disks = jsonencode([
          for disk in var.additional_volumes :
          {
            fstype     = disk.fstype
            device     = disk.device_name == "/dev/xvdp" && contains(local.nvme_instance_types, substr(var.instance_type, 0, 2)) == true ? "/dev/nvme1n1" : disk.device_name
            mount_path = disk.mount_path
          }
        ])
      }
    }

    ansible_ssh_settings {
      connect_timeout_seconds              = 60
      insecure_no_strict_host_key_checking = true
    }
  }
}

#########
# Puppet

module "puppet-node" {
  source         = "git::https://github.com/camptocamp/terraform-puppet-node.git?ref=v1.x"
  instance_count = var.puppet == null ? 0 : var.instance_count

  instances = [
    for i in range(length(aws_instance.this)) :
    {
      hostname = aws_instance.this[i].private_dns
      connection = {
        host                = lookup(var.connection, "host", coalesce((var.eip ? aws_eip.this[i].public_ip : ""), aws_instance.this[i].public_ip, var.public_ip ? "" : aws_instance.this[i].private_ip))
        type                = lookup(var.connection, "type", null)
        user                = lookup(var.connection, "user", "terraform")
        password            = lookup(var.connection, "password", null)
        port                = lookup(var.connection, "port", 22)
        timeout             = lookup(var.connection, "timeout", 60)
        script_path         = lookup(var.connection, "script_path", null)
        private_key         = lookup(var.connection, "private_key", null)
        agent               = lookup(var.connection, "agent", null)
        agent_identity      = lookup(var.connection, "agent_identity", null)
        host_key            = lookup(var.connection, "host_key", null)
        https               = lookup(var.connection, "https", false)
        insecure            = lookup(var.connection, "insecure", false)
        use_ntlm            = lookup(var.connection, "use_ntlm", false)
        cacert              = lookup(var.connection, "cacert", null)
        bastion_host        = lookup(var.connection, "bastion_host", null)
        bastion_host_key    = lookup(var.connection, "bastion_host_key", null)
        bastion_port        = lookup(var.connection, "bastion_port", 22)
        bastion_user        = lookup(var.connection, "bastion_user", null)
        bastion_password    = lookup(var.connection, "bastion_password", null)
        bastion_private_key = lookup(var.connection, "bastion_private_key", null)
      }
    }
  ]

  server_address    = var.puppet != null ? lookup(var.puppet, "server_address", null) : ""
  server_port       = var.puppet != null ? lookup(var.puppet, "server_port", 443) : -1
  ca_server_address = var.puppet != null ? lookup(var.puppet, "ca_server_address", null) : ""
  ca_server_port    = var.puppet != null ? lookup(var.puppet, "ca_server_port", 443) : -1
  environment       = var.puppet != null ? lookup(var.puppet, "environment", null) : ""
  role              = var.puppet != null ? lookup(var.puppet, "role", null) : ""
  autosign_psk      = var.puppet != null ? lookup(var.puppet, "autosign_psk", null) : ""

  deps_on = var.puppet != null ? null_resource.provisioner[*].id : []
}

##########
# Rancher

module "rancher-host" {
  source         = "git::https://github.com/camptocamp/terraform-rancher-host.git?ref=v1.x"
  instance_count = var.rancher == null ? 0 : var.instance_count

  instances = [
    for i in range(length(aws_instance.this)) :
    {
      hostname = aws_instance.this[i].private_dns
      agent_ip = aws_instance.this[i].private_ip
      connection = {
        host                = lookup(var.connection, "host", coalesce((var.eip ? aws_eip.this[i].public_ip : ""), aws_instance.this[i].public_ip, var.public_ip ? "" : aws_instance.this[i].private_ip))
        type                = lookup(var.connection, "type", null)
        user                = lookup(var.connection, "user", "terraform")
        password            = lookup(var.connection, "password", null)
        port                = lookup(var.connection, "port", 22)
        timeout             = lookup(var.connection, "timeout", 60)
        script_path         = lookup(var.connection, "script_path", null)
        private_key         = lookup(var.connection, "private_key", null)
        agent               = lookup(var.connection, "agent", null)
        agent_identity      = lookup(var.connection, "agent_identity", null)
        host_key            = lookup(var.connection, "host_key", null)
        https               = lookup(var.connection, "https", false)
        insecure            = lookup(var.connection, "insecure", false)
        use_ntlm            = lookup(var.connection, "use_ntlm", false)
        cacert              = lookup(var.connection, "cacert", null)
        bastion_host        = lookup(var.connection, "bastion_host", null)
        bastion_host_key    = lookup(var.connection, "bastion_host_key", null)
        bastion_port        = lookup(var.connection, "bastion_port", 22)
        bastion_user        = lookup(var.connection, "bastion_user", null)
        bastion_password    = lookup(var.connection, "bastion_password", null)
        bastion_private_key = lookup(var.connection, "bastion_private_key", null)
      }
      host_labels = merge(
        var.rancher != null ? var.rancher.host_labels : {},
        {
          "io.rancher.host.os"              = "linux"
          "io.rancher.host.provider"        = "aws"
          "io.rancher.host.region"          = var.region
          "io.rancher.host.zone"            = aws_instance.this[i].availability_zone
          "io.rancher.host.external_dns_ip" = coalesce((var.eip ? aws_eip.this[i].public_ip : ""), aws_instance.this[i].public_ip, var.public_ip ? "" : aws_instance.this[i].private_ip)
        }
      )
    }
  ]

  environment_id = var.rancher != null ? var.rancher.environment_id : ""

  deps_on = var.puppet != null ? module.puppet-node.this_provisioner_id : []
}
