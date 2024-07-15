resource "aws_ssm_parameter" "secret" {
  name  = "/${local.env.environment}/explorer/captcha_secret"
  type  = "SecureString"
  value = "placeholder_value"
  lifecycle {
    ignore_changes = [value]
  }
}
