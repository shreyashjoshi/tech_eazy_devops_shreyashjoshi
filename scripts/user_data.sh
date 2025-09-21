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
mvn clean package
jar_name=$(ls -t "$APP_DIR/target/" | head -n1)

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
