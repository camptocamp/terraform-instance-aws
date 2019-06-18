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
EOF
  }

  part {
    filename = "additional.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"
    content = "${var.additional_user_data}"
  }

  # EBS are not always available at boot time
  part {
    filename = "mountall.cfg"
    merge_type = "list(append)+dict(recurse_array)+str()"
    content_type = "text/cloud-config"

    content = <<EOF
#cloud-config

runcmd:
  - [ sh, -c, "sed -i '/exit 0/i mount -a' /etc/rc.local" ]
EOF
  }
}

locals {
  private_ips_length = length(var.instance_private_ips)
}

resource "aws_instance" "this" {
  count         = var.instance_count
  ami           = var.instance_image
  instance_type = var.instance_type
  subnet_id     = var.instance_subnet_ids[count.index % length(var.instance_subnet_ids)]

  # We use length(..)==0?1:var to avoid modulo: division by 0 error, because of https://github.com/hashicorp/hil/issues/50
  private_ip             = (local.private_ips_length == 0 ? "" : element(split(" ", join(" ", var.instance_private_ips)), count.index % (local.private_ips_length == 0 ? 1 : local.private_ips_length)))
  ebs_optimized          = var.ebs_optimized
  vpc_security_group_ids = var.security_groups
  key_name               = var.key_pair
  monitoring             = true
  iam_instance_profile   = var.iam_instance_profile
  user_data              = data.template_cloudinit_config.config[count.index].rendered
  source_dest_check      = var.source_dest_check
  tags                   = var.tags

  associate_public_ip_address = (var.public_ip || var.eip ? true : false)

  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_size
  }

  lifecycle {
    ignore_changes = ["key_name", "ami", "user_data", "root_block_device", "associate_public_ip_address"]
  }
}

# EIP
resource "aws_eip" "this" {
  count = (var.eip ? var.instance_count : 0)
  vpc   = true
}

resource "aws_eip_association" "eip_assoc" {
  count         = (var.eip ? var.instance_count : 0)
  instance_id   = aws_instance.this[count.index].id
  allocation_id = aws_eip.this[count.index].id
}
