import boto3

rekognition = boto3.client('rekognition')
dynamodb = boto3.client('dynamodb')

def lambda_handler(event, context):
    # Get the S3 bucket and object key from the event
    bucket_name = event['Records'][0]['s3']['bucket']['name']
    object_key = event['Records'][0]['s3']['object']['key']
    
    # Call Rekognition to detect labels
    response = rekognition.detect_labels(
        Image={
            'S3Object': {
                'Bucket': bucket_name,
                'Name': object_key,
            }
        },
        MaxLabels=10  # Limit the number of labels
    )
    
    # Extract labels from the response
    labels = [label['Name'] for label in response['Labels']]
    
    # Store the labels in DynamoDB
    dynamodb.put_item(
        TableName='ImageMetadata',
        Item={
            'ImageKey': {'S': object_key},
            'Labels': {'SS': labels}
        }
    )
    
    return {
        'statusCode': 200,
        'body': f'Image categorized with labels: {labels}'
    }
