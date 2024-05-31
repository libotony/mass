output "explore_public_zone_id" {
    description = "The ID of the public hosted zone for the explore application"
    value = aws_route53_zone.explore_public_zone.id
}

output "certificate_arn" {
    description = "The ARN of the certificate for the explore application"
    value = module.domain.certificate_arn
}