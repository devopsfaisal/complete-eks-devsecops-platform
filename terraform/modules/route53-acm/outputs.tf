output "certificate_arn" {
  value = aws_acm_certificate_validation.cert.certificate_arn
}

output "zone_id" {
  value = data.aws_route53_zone.primary.zone_id
}

output "subdomain" {
  value = var.subdomain
}
