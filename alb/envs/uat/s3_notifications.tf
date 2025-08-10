# S3 bucket notification configuration for both ALB Lambda functions
# This needs to be separate because S3 bucket notifications can only have one configuration per bucket

resource "aws_s3_bucket_notification" "alb_logs_notification" {
  bucket = "bongaquino-uat-alb-logs"

  # Main ALB Lambda function notification
  lambda_function {
    id                  = "main-alb-logs"
    lambda_function_arn = module.main_alb.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "main-alb"
  }

  # Services ALB Lambda function notification
  lambda_function {
    id                  = "services-alb-logs"
    lambda_function_arn = module.services_alb.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "services-alb"
  }

  depends_on = [
    aws_lambda_permission.main_alb_bucket_permission,
    aws_lambda_permission.services_alb_bucket_permission
  ]
}

# Lambda permissions for S3 to invoke the functions
resource "aws_lambda_permission" "main_alb_bucket_permission" {
  statement_id  = "AllowExecutionFromS3Bucket-MainALB"
  action        = "lambda:InvokeFunction"
  function_name = module.main_alb.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::bongaquino-uat-alb-logs"
}

resource "aws_lambda_permission" "services_alb_bucket_permission" {
  statement_id  = "AllowExecutionFromS3Bucket-ServicesALB"
  action        = "lambda:InvokeFunction"
  function_name = module.services_alb.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::bongaquino-uat-alb-logs"
} 