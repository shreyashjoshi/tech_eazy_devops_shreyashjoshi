#!/bin/bash
set -euo pipefail
STAGE=${stage}
REPO_URL="https://github.com/Trainings-TechEazy/test-repo-for-devops"
APP_USER=ubuntu
APP_DIR="/home/ubuntu/app"

echo "=== Starting cloud-init bootstrap ==="
# Install OpenJDK 21, maven
sudo apt update -y
sudo apt install -y openjdk-21-jdk maven 

# Clone repo
git clone $REPO_URL $APP_DIR
cd $APP_DIR
# send logs
LOG_FILE="build-$(date +%Y%m%d-%H%M%S).log"
mvn clean package | tee $LOG_FILE
REGION="us-east-1"  # Change if needed

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


jar_name=$(ls -t "$APP_DIR/target/" | head -n1)

Chmod +x "$APP_DIR/scripts/upload_logs.sh"
# Configure port forwarding since port 80 is used
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Create a systemd service to run the jar
SERVICE_PATH="/etc/systemd/system/techeazy-app.service"
cat > $SERVICE_PATH <<EOF
[Unit]
Description=TechEazy Java App
After=network.target

[Service]
User=ubuntu
WorkingDirectory=$APP_DIR
ExecStart=java -jar "$APP_DIR/target/$jar_name" --server.port=8080
SuccessExitStatus=143
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
systemctl daemon-reload
systemctl enable techeazy-app
systemctl start techeazy-app

#upload s3 service 
UPLOAD_SERVICE_PATH="/etc/systemd/system/s3-upload.service"
cat > $UPLOAD_SERVICE_PATH <<EOF
[Unit]
Description=Upload cloud-init log to S3 on shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
ExecStart="$APP_DIR/scripts/upload_logs.sh"
RemainAfterExit=true

[Install]
WantedBy=halt.target reboot.target shutdown.target
EOF

# Environment-specific configurations
if [ "$STAGE" = "prod" ]; then
    echo "=== Production environment setup ==="
    # Production should run indefinitely - no auto-shutdown
    echo "Production instance will run indefinitely"
    
elif [ "$STAGE" = "dev" ]; then
    echo "=== Development environment setup ==="
    # Development instances can auto-shutdown for cost optimization
    echo "Development instance will shutdown after 60 minutes for cost optimization"
    shutdown -h +60 "Shutting down the development instance after 60 minutes."
    
else
    echo "=== Test/Other environment setup ==="
    # Test or other environments - shorter shutdown time
    echo "Test instance will shutdown after 30 minutes for cost optimization"
    shutdown -h +30 "Shutting down the test instance after 30 minutes."
fi
echo "=== Bootstrap complete ==="


exit 0
