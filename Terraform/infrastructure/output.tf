
output "vpc_id" {
  value = data.aws_vpc.main.id
}

output "public_ip" {
  value = aws_instance.webapp.public_ip
}