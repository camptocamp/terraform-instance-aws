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
  private_ip             = (local.private_ips_length == 0 ? null : element(split(" ", join(" ", var.private_ips)), count.index % (local.private_ips_length == 0 ? 1 : local.private_ips_length)))
  ebs_optimized          = var.ebs_optimized
  vpc_security_group_ids = var.security_groups
  key_name               = var.key_pair
  monitoring             = var.monitoring
  iam_instance_profile   = coalesce(var.iam_instance_profile, aws_iam_instance_profile.this.id)
  user_data              = data.template_cloudinit_config.config[count.index].rendered
  source_dest_check      = var.source_dest_check
  tags                   = var.tags

  associate_public_ip_address = (var.public_ip || var.eip ? true : false)

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_size
  }

  lifecycle {
    ignore_changes = [key_name, ami, user_data, root_block_device, associate_public_ip_address]
  }
}

######
# EIP

resource "aws_eip" "this" {
  count  = (var.eip ? var.instance_count : 0)
  domain = "vpc"
  tags   = var.tags
}

resource "aws_eip_association" "eip_assoc" {
  count         = (var.eip ? var.instance_count : 0)
  instance_id   = aws_instance.this[count.index].id
  allocation_id = aws_eip.this[count.index].id
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
