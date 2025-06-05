output "certificate_arn" {
  description = "The ARN of the certificate"
  value       = aws_acm_certificate.main.arn
}
 
output "certificate_validation_arn" {
  description = "The ARN of the certificate validation"
  value       = aws_acm_certificate_validation.main.certificate_arn
} 