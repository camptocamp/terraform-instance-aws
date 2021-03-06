output "this_instance_availability_zone" {
  value = aws_instance.this[*].availability_zone
}

output "this_instance_public_dns" {
  value = var.eip ? aws_eip.this[*].public_dns : var.public_ip ? aws_instance.this[*].public_dns : aws_instance.this[*].private_dns
}

output "this_instance_private_dns" {
  value = aws_instance.this[*].private_dns
}

output "this_instance_public_ip" {
  value = split(" ", (var.eip ? join(" ", aws_eip.this[*].public_ip) : (var.public_ip ? join(" ", aws_instance.this[*].public_ip) : join(" ", aws_instance.this[*].private_ip))))
}

output "this_instance_private_ip" {
  value = aws_instance.this[*].private_ip
}

output "this_role_id" {
  value = aws_iam_role.this.id
}

output "this_role_arn" {
  value = aws_iam_role.this.arn
}

######
# API

output "this_instance_public_ipv4" {
  description = "Instance's public IPv4"
  value       = split(" ", (var.eip ? join(" ", aws_eip.this[*].public_ip) : (var.public_ip ? join(" ", aws_instance.this[*].public_ip) : join(" ", aws_instance.this[*].private_ip))))
}

output "this_instance_public_ipv6" {
  description = "Instance's IPv6"
  value       = coalesce(aws_instance.this[*].ipv6_addresses)
}

output "this_instance_hostname" {
  description = "Instance's hostname"
  value       = aws_instance.this[*].private_dns
}

output "this_instance_id" {
  description = "Instance's ID"
  value       = aws_instance.this[*].id
}

output "this_provisioner_id" {
  value = null_resource.provisioner[*].id
}
