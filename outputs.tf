output "cards_instance_ip" {
  value = aws_instance.cards_service_r1.public_ip
}

output "curl_test_cards" {
  value = "curl -i http://${aws_instance.cards_service_r1.public_ip}:8085/api/cards"
}

output "ssh_command" {
  value = "ssh -i ./umoh2.pem ubuntu@${aws_instance.cards_service_r1.public_ip}"
}
