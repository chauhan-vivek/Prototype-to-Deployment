import boto3
import os

sns_topic_arn = os.environ.get('notification_topic_arn')
s3_bucket = os.environ.get('s3_bucket_name')
service_role_arn = os.environ.get('service_role_arn')


def lambda_handler(event, context):
    ssm = boto3.client('ssm')
    response = ssm.send_command(
        InstanceIds=[
            os.environ.get('cloud9_id'),
        ],
        DocumentName='AWS-RunRemoteScript',
        Parameters={
            'sourceType': ['S3'],
            'sourceInfo': ['{\"path\": \"https://hm-iot-infra-bucket.s3.amazonaws.com/virtual_device_creator/virtual_device_creator.sh\"}'],
            'commandLine': ['bash virtual_device_creator.sh {0}'.format(s3_bucket)]
        },
        OutputS3Region='us-east-1',
        OutputS3BucketName=s3_bucket,
        TimeoutSeconds=7200,
        OutputS3KeyPrefix='SSMOutputs',
        ServiceRoleArn=service_role_arn,
        NotificationConfig={
            'NotificationArn': sns_topic_arn,
            'NotificationEvents': ['Success', 'Failed'],
            'NotificationType': 'Invocation'
        }
    )
