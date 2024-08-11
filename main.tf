provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "image_processing" {
  bucket = var.s3_bucket_name

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "log"
    enabled = true

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  tags = {
    Name = "Image Processing Bucket"
  }
}

resource "aws_dynamodb_table" "image_metadata" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ImageKey"
  attribute {
    name = "ImageKey"
    type = "S"
  }

  tags = {
    Name = "Image Metadata Table"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.lambda_role_name}_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:*",
          "dynamodb:*",
          "rekognition:DetectLabels",
          "logs:*",
          "cloudwatch:*"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "compress_image" {
  function_name = "CompressImageFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "compress_image.lambda_handler"
  runtime       = "python3.8"
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = "lambda/compress_image.zip"
  source_code_hash = filebase64sha256("lambda/compress_image.zip")

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.image_processing.bucket
    }
  }
}

resource "aws_lambda_function" "categorize_image" {
  function_name = "CategorizeImageFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "categorize_image.lambda_handler"
  runtime       = "python3.8"
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = "lambda/categorize_image.zip"
  source_code_hash = filebase64sha256("lambda/categorize_image.zip")

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.image_metadata.name
    }
  }
}

resource "aws_lambda_function" "generate_thumbnail" {
  function_name = "GenerateThumbnailFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "generate_thumbnail.lambda_handler"
  runtime       = "python3.8"
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  filename         = "lambda/generate_thumbnail.zip"
  source_code_hash = filebase64sha256("lambda/generate_thumbnail.zip")

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.image_processing.bucket
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.compress_image.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.image_processing.arn
}

resource "aws_s3_bucket_notification" "s3_trigger" {
  bucket = aws_s3_bucket.image_processing.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.compress_image.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "ImageProcessingAPI"
  description = "API Gateway for Image Processing"

  tags = {
    Name = "Image Processing API"
  }
}

resource "aws_api_gateway_resource" "image" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "image"
}

resource "aws_api_gateway_method" "post_image" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.image.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.image.id
  http_method = aws_api_gateway_method.post_image.http_method
  integration_http_method = "POST"
  type        = "AWS_PROXY"
  uri         = aws_lambda_function.compress_image.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "v1"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.image_processing.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.image_metadata.name
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}
