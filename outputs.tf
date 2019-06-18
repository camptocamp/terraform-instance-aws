output "availability_zone" {
  value = aws_instance.this[*].availability_zone
}

# The public_dns is missing in aws_eip
output "public_dns" {
  value = split(" ", var.eip ? "" : var.public_ip ? join(" ", aws_instance.this[*].public_dns) : join(" ", aws_instance.this[*].private_dns))
}

output "private_dns" {
  value = aws_instance.this[*].private_dns
}

output "ids" {
  value = aws_instance.this[*].id
}

output "public_ips" {
  value = split(" ", var.eip ? join(" ", aws_eip.this[*].public_ip) : var.public_ip ? join(" ", aws_instance.this[*].public_ip) : join(" ", aws_instance.this[*].private_ip))
}

output "private_ips" {
  value = aws_instance.this[*].private_ip
}
