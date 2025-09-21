# TechEazy DevOps Project

A complete DevOps infrastructure setup using Terraform and AWS to deploy a Java Spring Boot application with automated environment-specific configurations.

## 🏗️ Project Overview

This project demonstrates a production-ready DevOps pipeline that:
- Automatically provisions AWS infrastructure using Terraform
- Deploys a Java Spring Boot application with environment-specific configurations
- Implements cost optimization strategies for different environments
- Uses Infrastructure as Code (IaC) best practices

## 🚀 Features

### Infrastructure Components
- **VPC**: Custom Virtual Private Cloud with public subnet
- **EC2 Instance**: Ubuntu 22.04 LTS with auto-scaling capabilities
- **Security Groups**: HTTP (port 80) access with proper egress rules
- **Internet Gateway**: Public internet access
- **Route Tables**: Proper routing configuration

### Application Features
- **Java 21**: Latest OpenJDK runtime
- **Maven**: Build automation tool
- **Spring Boot**: Microservice framework
- **Systemd Service**: Automatic service management
- **Port Forwarding**: HTTP traffic redirection (80 → 8080)

### Environment Management
- **Production**: Runs indefinitely with enhanced monitoring
- **Development**: Auto-shutdown after 60 minutes for cost optimization
- **Test/Other**: Auto-shutdown after 30 minutes for cost optimization

## 🛠️ Prerequisites

Before you begin, ensure you have:

- [Terraform](https://www.terraform.io/downloads.html) (v1.0+)
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- AWS account with necessary permissions
- Git installed

## ⚙️ Configuration

### 1. AWS Credentials Setup

```bash
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

### 2. Terraform Variables

Edit `terraform/variables.tf` to customize:

```hcl
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "stage" {
  description = "Environment stage (prod, dev, test)"
  type        = string
  default     = "dev"
}
```

## 🚀 Deployment

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Plan Deployment

```bash
terraform plan
```

### 3. Deploy Infrastructure

```bash
terraform apply
```

### 4. Get Application URL

After deployment, get the public IP:

```bash
terraform output instance_public_ip_javaapp
```

Visit: `http://<PUBLIC_IP>` to access your application.

## 🌍 Environment-Specific Deployments

### Production Environment

```bash
terraform apply -var="stage=prod"
```

- **Behavior**: Runs indefinitely
- **Use Case**: Live production workloads
- **Cost**: Higher (no auto-shutdown)

### Development Environment

```bash
terraform apply -var="stage=dev"
```

- **Behavior**: Auto-shutdown after 60 minutes
- **Use Case**: Development and testing
- **Cost**: Optimized with scheduled shutdown

### Test Environment

```bash
terraform apply -var="stage=test"
```

- **Behavior**: Auto-shutdown after 30 minutes
- **Use Case**: Quick testing and validation
- **Cost**: Most cost-effective

## 📊 Monitoring and Logs

### Check Application Status

```bash
# SSH into the instance
ssh -i your-key.pem ubuntu@<PUBLIC_IP>

# Check service status
sudo systemctl status techeazy-app

# View application logs
sudo journalctl -u techeazy-app -f
```

### Application Health Check

```bash
# Check if application is running
curl http://<PUBLIC_IP>

# Check specific endpoint (if available)
curl http://<PUBLIC_IP>/health
```

## 🔧 Customization

### Modify Application

1. Update the repository URL in `scripts/user_data.sh`:
   ```bash
   REPO_URL="https://github.com/your-username/your-repo"
   ```

2. Modify service configuration in the user_data script

3. Redeploy with `terraform apply`

### Change Instance Type

Update `terraform/variables.tf`:
```hcl
variable "instance_type" {
  default = "t3.medium"  # Change from t2.micro
}
```

## 🧹 Cleanup

To destroy all resources and avoid AWS charges:

```bash
cd terraform
terraform destroy
```

## 🔒 Security Considerations

- Security groups are configured to allow only HTTP traffic
- SSH access is commented out for security (uncomment if needed)
- All egress traffic is allowed for application functionality
- Consider adding HTTPS/SSL termination for production

## 🐛 Troubleshooting

### Common Issues

1. **Application not accessible**
   - Check security group rules
   - Verify EC2 instance is running
   - Check application logs: `sudo journalctl -u techeazy-app`

2. **Terraform state issues**
   - Run `terraform refresh` to sync state
   - Check AWS console for resource status

3. **Permission errors**
   - Verify AWS credentials: `aws sts get-caller-identity`
   - Check IAM permissions for EC2, VPC, and Security Groups

### Debug Mode

Enable debug logging in Terraform:
```bash
export TF_LOG=DEBUG
terraform apply
```

## 📈 Cost Optimization

- **Development/Test**: Use `t2.micro` with auto-shutdown
- **Production**: Use appropriate instance size based on load
- **Monitoring**: Set up CloudWatch alarms for cost tracking
- **Scheduling**: Use AWS Instance Scheduler for non-production environments

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Shreyash Joshi**
- GitHub: [@shreyashjoshi](https://github.com/shreyashjoshi)
- Project: TechEazy DevOps Training

## 📞 Support

For questions or support, please:
- Open an issue in this repository
- Contact the project maintainer
- Check the troubleshooting section above

---

**Happy Deploying! 🚀**
