output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.image_processing.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  value       = aws_dynamodb_table.image_metadata.name
}

output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
}
