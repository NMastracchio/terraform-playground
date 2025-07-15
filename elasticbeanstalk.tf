# 1. Look up the default VPC and Subnets for the AWS account
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  # Ensure we only select subnets in AZs where t3.micro is available
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1f"]
  }
}

# 2. A bucket to store our application code
resource "aws_s3_bucket" "app_source" {
  bucket = "poker-remote-2595d816"
}

# 3. Upload our Blazor app's ZIP file to the S3 bucket
resource "aws_s3_object" "app_zip" {
  bucket = aws_s3_bucket.app_source.id
  key    = "RemoteClient.zip"
  source = "RemoteClient.zip" # The local path to your file
  etag   = filemd5("RemoteClient.zip")
}

# 4. Define the Elastic Beanstalk application itself
resource "aws_elastic_beanstalk_application" "blazor_app" {
  name        = "pippit"
  description = "A Blazor Web App deployed via Terraform"
}

# 5. Create a specific version of our application, pointing to the code in S3
resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v-${filemd5("RemoteClient.zip")}"
  application = aws_elastic_beanstalk_application.blazor_app.name
  description = "Deployment version based on file hash"
  bucket      = aws_s3_bucket.app_source.id
  key         = aws_s3_object.app_zip.id
}

# 6. IAM Role for the Elastic Beanstalk Service
resource "aws_iam_role" "beanstalk_service_role" {
  name = "beanstalk-service-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "elasticbeanstalk.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_service_policy" {
  role       = aws_iam_role.beanstalk_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkService"
}

# 7. IAM Role and Instance Profile for the EC2 Instances
resource "aws_iam_role" "beanstalk_ec2_role" {
  name = "beanstalk-ec2-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_ec2_policy" {
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_instance_profile" "beanstalk_instance_profile" {
  name = "beanstalk-instance-profile"
  role = aws_iam_role.beanstalk_ec2_role.name
}

# 8. --- MODIFIED --- Security group to allow our app's traffic
resource "aws_security_group" "beanstalk_sg" {
  name        = "beanstalk-sg-poker-app"
  description = "Allow traffic for the Poker Party app"
  # --- ADDED --- This line is crucial
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 9998
    to_port     = 9998
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PokerAppSecurityGroup"
  }
}

# 9. --- MODIFIED --- Create and launch the environment that runs our code
resource "aws_elastic_beanstalk_environment" "app_env" {
  name                = "pippit-dev"
  application         = aws_elastic_beanstalk_application.blazor_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v3.5.0 running .NET 9"
  version_label       = aws_elastic_beanstalk_application_version.app_version.name

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

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk_sg.id
  }

  # --- ADDED --- These two blocks are crucial
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.aws_vpc.default.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.aws_subnets.default.ids)
  }
}

# 10. Output the public URL of our live application
output "beanstalk_url" {
  value = aws_elastic_beanstalk_environment.app_env.cname
}