resource "aws_secretsmanager_secret" "teste2" {
  name = format("%s-secret-exemplo2", var.service_name)

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "teste2" {
  secret_id     = aws_secretsmanager_secret.teste2.id
  secret_string = "Vim lá do secrets manager v2"
}