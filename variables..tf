variable "region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  default     = "my-image-processing-bucket"
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  default     = "ImageMetadata"
}

variable "lambda_role_name" {
  description = "Name of the IAM role for Lambda functions"
  default     = "lambda_image_processing_role"
}

variable "lambda_timeout" {
  description = "Lambda function timeout"
  default     = 60
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  default     = 128
}
