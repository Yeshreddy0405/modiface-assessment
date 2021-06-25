output "ssh_private_key" {
  value = "${tls_private_key.private_key.private_key_pem}"
}

output "ip_address" {
  value = "${aws_instance.webapp.public_ip}"
}
