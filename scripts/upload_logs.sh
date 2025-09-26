#!/bin/bash

# Set the AWS region
REGION="us-east-1"  # Change if needed

# Log file path
LOG_FILE="/var/log/cloud-init.log"

# Get the S3 bucket name from SSM
BUCKET_NAME=$(aws ssm get-parameter \
  --name "s3_bucket_name" \
  --with-decryption \
  --region "$REGION" \
  --query "Parameter.Value" \
  --output text)

# Check for empty bucket name
if [ -z "$BUCKET_NAME" ]; then
  echo "Failed to get S3 bucket name from SSM" >> /var/log/shutdown-upload.log
  exit 1
fi

# Build the S3 object key
S3_KEY="cloud-init-$(hostname)-$(date +%Y%m%d-%H%M%S).log"

# Upload the log file to S3
aws s3 cp "$LOG_FILE" "s3://${BUCKET_NAME}/${S3_KEY}" --region "$REGION" >> /var/log/shutdown-upload.log 2>&1
