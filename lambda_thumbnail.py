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
    
    # Create a thumbnail (e.g., 128x128)
    thumbnail_size = (128, 128)
    image.thumbnail(thumbnail_size)
    
    # Save the thumbnail to an in-memory file
    thumbnail_io = io.BytesIO()
    image.save(thumbnail_io, format='JPEG')
    thumbnail_io.seek(0)
    
    # Save the thumbnail back to S3
    thumbnail_object_key = f"thumbnails/{object_key}"
    s3.put_object(Bucket=bucket_name, Key=thumbnail_object_key, Body=thumbnail_io)
    
    return {
        'statusCode': 200,
        'body': f'Thumbnail saved to {thumbnail_object_key}'
    }
