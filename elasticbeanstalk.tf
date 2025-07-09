# 1. A bucket to store our application code
resource "aws_s3_bucket" "app_source" {
  bucket = "poker-remote-2595d816"
}

# 2. Upload our Blazor app's ZIP file to the S3 bucket
resource "aws_s3_object" "app_zip" {
  bucket = aws_s3_bucket.app_source.id
  key    = "RemoteClient.zip"
  source = "RemoteClient.zip" # The local path to your file

  # This ensures that if the ZIP file changes, it gets re-uploaded
  etag = filemd5("RemoteClient.zip")
}

# 3. Define the Elastic Beanstalk application itself
resource "aws_elastic_beanstalk_application" "blazor_app" {
  name        = "MyBlazorWebApp"
  description = "A Blazor Web App deployed via Terraform"
}

# 4. Create a specific version of our application, pointing to the code in S3
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v1.0.0" # You can make this dynamic later
  application = aws_elastic_beanstalk_application.blazor_app.name
  description = "Initial version"
  bucket      = aws_s3_bucket.app_source.id
  key         = aws_s3_object.app_zip.id
}

# 1. IAM Role for the Elastic Beanstalk Service
resource "aws_iam_role" "beanstalk_service_role" {
  name = "beanstalk-service-role"

  # Trust policy allowing Elastic Beanstalk to assume this role
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AWS managed policy for Elastic Beanstalk services
resource "aws_iam_role_policy_attachment" "beanstalk_service_policy" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# 2. IAM Role and Instance Profile for the EC2 Instances
resource "aws_iam_role" "beanstalk_ec2_role" {
  name = "beanstalk-ec2-role"

  # Trust policy allowing EC2 instances to assume this role
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach the AWS managed policy for web tier instances
resource "aws_iam_role_policy_attachment" "beanstalk_ec2_policy" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

# The instance profile is a container for the role that gets attached to the EC2 instance
resource "aws_iam_instance_profile" "beanstalk_instance_profile" {
  name = "beanstalk-instance-profile"
  role = aws_iam_role.beanstalk_ec2_role.name
}

# 5. Create and launch the environment that runs our code
resource "aws_elastic_beanstalk_environment" "app_env" {
  name                = "MyBlazorWebApp-dev"
  application         = aws_elastic_beanstalk_application.blazor_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v3.5.0 running .NET 9" # Or your verified name
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

  # --- Corrected Settings ---
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
  
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_service_role.arn
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_instance_profile.name
  }
}

# 6. Output the public URL of our live application
output "beanstalk_url" {
  value = aws_elastic_beanstalk_environment.app_env.cname
}

