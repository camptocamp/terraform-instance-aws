Terraform-instance-aws module
================================

This module creates an AWS instance.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_ebs_volume.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) | resource |
| [aws_eip.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.eip_assoc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_volume_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) | resource |
| [template_cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_additional_user_data"></a> [additional\_user\_data](#input\_additional\_user\_data) | n/a | `string` | `"#cloud-config\n"` | no |
| <a name="input_additional_volumes"></a> [additional\_volumes](#input\_additional\_volumes) | n/a | <pre>list(object({<br/>    name        = string<br/>    size        = number<br/>    type        = string<br/>    device_name = string<br/>    mount_path  = string<br/>    fstype      = string<br/>  }))</pre> | `[]` | no |
| <a name="input_ami"></a> [ami](#input\_ami) | n/a | `string` | n/a | yes |
| <a name="input_ansible_check"></a> [ansible\_check](#input\_ansible\_check) | n/a | `bool` | `false` | no |
| <a name="input_connection"></a> [connection](#input\_connection) | n/a | `map` | `{}` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | n/a | `bool` | `true` | no |
| <a name="input_eip"></a> [eip](#input\_eip) | n/a | `bool` | `true` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | n/a | `string` | `""` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | n/a | `number` | `1` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | n/a | `string` | n/a | yes |
| <a name="input_key_pair"></a> [key\_pair](#input\_key\_pair) | n/a | `string` | n/a | yes |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | If true, the launched EC2 instance will have detailed monitoring enabled. | `bool` | `true` | no |
| <a name="input_private_ips"></a> [private\_ips](#input\_private\_ips) | n/a | `list(string)` | `[]` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | n/a | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | `""` | no |
| <a name="input_root_size"></a> [root\_size](#input\_root\_size) | n/a | `number` | `"10"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | n/a | `list(string)` | `[]` | no |
| <a name="input_source_dest_check"></a> [source\_dest\_check](#input\_source\_dest\_check) | n/a | `bool` | `true` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | n/a | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_this_instance_availability_zone"></a> [this\_instance\_availability\_zone](#output\_this\_instance\_availability\_zone) | n/a |
| <a name="output_this_instance_hostname"></a> [this\_instance\_hostname](#output\_this\_instance\_hostname) | Instance's hostname |
| <a name="output_this_instance_id"></a> [this\_instance\_id](#output\_this\_instance\_id) | Instance's ID |
| <a name="output_this_instance_private_dns"></a> [this\_instance\_private\_dns](#output\_this\_instance\_private\_dns) | n/a |
| <a name="output_this_instance_private_ip"></a> [this\_instance\_private\_ip](#output\_this\_instance\_private\_ip) | n/a |
| <a name="output_this_instance_public_dns"></a> [this\_instance\_public\_dns](#output\_this\_instance\_public\_dns) | n/a |
| <a name="output_this_instance_public_ip"></a> [this\_instance\_public\_ip](#output\_this\_instance\_public\_ip) | n/a |
| <a name="output_this_instance_public_ipv4"></a> [this\_instance\_public\_ipv4](#output\_this\_instance\_public\_ipv4) | Instance's public IPv4 |
| <a name="output_this_instance_public_ipv6"></a> [this\_instance\_public\_ipv6](#output\_this\_instance\_public\_ipv6) | Instance's IPv6 |
| <a name="output_this_role_arn"></a> [this\_role\_arn](#output\_this\_role\_arn) | n/a |
| <a name="output_this_role_id"></a> [this\_role\_id](#output\_this\_role\_id) | n/a |
<!-- END_TF_DOCS -->