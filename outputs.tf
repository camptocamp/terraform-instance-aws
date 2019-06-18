output "this_instance_availability_zone" {
  value = aws_instance.this[*].availability_zone
}

# The public_dns is missing in aws_eip
output "this_instance_public_dns" {
  value = split(" ", var.eip ? "" : var.public_ip ? join(" ", aws_instance.this[*].public_dns) : join(" ", aws_instance.this[*].private_dns))
}

output "this_instance_private_dns" {
  value = aws_instance.this[*].private_dns
}

output "this_instance_id" {
  value = aws_instance.this[*].id
}

output "this_instance_public_ip" {
  value = split(" ", (var.eip ? join(" ", aws_eip.this[*].public_ip) : (var.public_ip ? join(" ", aws_instance.this[*].public_ip) : join(" ", aws_instance.this[*].private_ip))))
}

output "this_instance_private_ip" {
  value = aws_instance.this[*].private_ip
}

output "this_instance_hostname" {
  description = "Instances' hostname"
  value       = aws_instance.this[*].private_dns
}
