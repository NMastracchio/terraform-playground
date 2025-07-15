# terraform-playground/main.tf

################################################################################
# PROVIDER CONFIGURATION
################################################################################

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

provider "docker" {
  host = "unix:///Users/nmastracchio/.docker/run/docker.sock"
}

provider "aws" {
  region = "us-east-1" # Or your preferred region
}

################################################################################
# SHARED RESOURCES
# Resources used by multiple modules are defined here in the root.
################################################################################

resource "docker_network" "app_network" {
  name = "my-app-network"
}

# 1. Define the SQS Queue
# This creates the queue that will act as the message middleman.
resource "aws_sqs_queue" "poker_command_queue" {
  name                      = "poker-command-queue"
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 days
  visibility_timeout_seconds = 30 # How long a message is hidden after being read

  tags = {
    Project = "PokerApp"
  }
}

# 2. Define the IAM Policy for the C# Web App (Sender)
# This policy grants permission ONLY to send messages to the queue.
resource "aws_iam_policy" "beanstalk_sqs_send_policy" {
  name        = "BeanstalkSqsSendPolicy"
  description = "Allows sending messages to the poker command SQS queue."

  # The actual policy document in JSON format
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sqs:SendMessage"
        Effect   = "Allow"
        Resource = aws_sqs_queue.poker_command_queue.arn # Grabs the ARN from the queue created above
      },
    ]
  })
}

# 3. Attach the Send Policy to your Elastic Beanstalk Role
# This gives your running web application the permissions defined above.
resource "aws_iam_role_policy_attachment" "beanstalk_sends_to_sqs" {
  # This role should already be defined in your Terraform files from the previous steps.
  role       = aws_iam_role.beanstalk_ec2_role.name
  policy_arn = aws_iam_policy.beanstalk_sqs_send_policy.arn
}

# 4. Create a dedicated IAM User for the Python Desktop App
# It's best practice to create a specific user for your application.
resource "aws_iam_user" "python_poker_client" {
  name = "python-poker-client-user"
}

# 5. Define the IAM Policy for the Python App (Receiver)
# This policy grants permission to receive and delete messages.
resource "aws_iam_policy" "python_sqs_receive_policy" {
  name        = "PythonClientSqsReceivePolicy"
  description = "Allows receiving and deleting messages from the poker SQS queue."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.poker_command_queue.arn
      },
    ]
  })
}

# 6. Attach the Receive Policy to the Python App's User
resource "aws_iam_user_policy_attachment" "python_receives_from_sqs" {
  user       = aws_iam_user.python_poker_client.name
  policy_arn = aws_iam_policy.python_sqs_receive_policy.arn
}

# 7. Create Access Keys for the Python App User 🔑
# These are the credentials your Python app will use to authenticate with AWS.
# WARNING: Treat these keys like passwords. Do not commit them to Git.
resource "aws_iam_access_key" "python_client_keys" {
  user = aws_iam_user.python_poker_client.name
}

################################################################################
# MODULES
# This is where we call our reusable modules to build the infrastructure.
################################################################################

module "database" {
  source = "./modules/database"

  network_name = docker_network.app_network.name
  db_password  = var.db_password
}

module "webserver" {
  source = "./modules/webserver"

  # Pass required variables into the webserver module
  network_name  = docker_network.app_network.name
  external_port = var.external_port

  # This explicitly tells Terraform the webserver depends on the database module
  depends_on = [
    module.database
  ]
}

# 8. Output the Important Values
# After running `terraform apply`, these values will be printed to your console.
output "sqs_queue_url" {
  description = "The URL of the SQS queue."
  value       = aws_sqs_queue.poker_command_queue.id # .id attribute gives the URL
}

output "python_client_access_key_id" {
  description = "Access key ID for the Python client user."
  value       = aws_iam_access_key.python_client_keys.id
  sensitive   = true
}

output "python_client_secret_access_key" {
  description = "Secret access key for the Python client user."
  value       = aws_iam_access_key.python_client_keys.secret
  sensitive   = true
}