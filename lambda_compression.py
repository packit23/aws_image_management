import boto3
from PIL import Image
import io

s3 = boto3.client('s3')

def lambda_handler(event, context):
    # Get the S3 bucket and object key from the event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    # Download the image from S3
    response = s3.get_object(Bucket=bucket_name, Key=object_key)
    image_content = response['Body'].read()
    
    # Open the image using PIL
    image = Image.open(io.BytesIO(image_content))
    
    # Compress the image
    compressed_image_io = io.BytesIO()
    image.save(compressed_image_io, format='JPEG', quality=70)  # Adjust quality as needed
    compressed_image_io.seek(0)
    
    # Save the compressed image back to S3
    compressed_object_key = f"compressed/{object_key}"
    s3.put_object(Bucket=bucket_name, Key=compressed_object_key, Body=compressed_image_io)
    
    return {
        'statusCode': 200,
        'body': f'Compressed image saved to {compressed_object_key}'
    }
