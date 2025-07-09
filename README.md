# Terraform Learning Project: Docker Stack & AWS Deployment

This project serves as a hands-on guide to learning Terraform. It starts by creating a local, multi-service application stack using Docker and then progresses to deploying a real-world .NET web application to AWS Elastic Beanstalk.

The entire infrastructure, from the local Docker containers to the cloud-based AWS services, is defined and managed as code using Terraform.

---
## Architecture

### Local Infrastructure (Docker)
* **Nginx Web Server**: A containerized Nginx instance serving a basic HTML page.
* **PostgreSQL Database**: A containerized PostgreSQL database.
* **Docker Network**: A custom bridge network allowing the Nginx and PostgreSQL containers to communicate.

### Cloud Infrastructure (AWS)
* **Amazon S3**: An S3 bucket is used to store the packaged .NET application code.
* **AWS Elastic Beanstalk**: This service automates the deployment and management of the .NET Blazor web application. It includes:
    * An **EC2 Instance** to host the application.
    * **IAM Roles** to grant necessary permissions to Elastic Beanstalk and the EC2 instance.

---
## Prerequisites

Before you begin, ensure you have the following installed and configured:

1.  **Terraform**: [Installation Guide](https://developer.hashicorp.com/terraform/install)
2.  **Docker Desktop**: [Download Page](https://www.docker.com/products/docker-desktop/)
3.  **.NET SDK**: (.NET 9) [Download Page](https://dotnet.microsoft.com/en-us/download)
4.  **AWS CLI**: [Installation Guide](https://aws.amazon.com/cli/)
5.  **AWS Account**: An active AWS account with an **IAM user** configured with programmatic access (Access Key ID and Secret Access Key). Your credentials should be configured locally, either via `~/.aws/credentials` or environment variables.

---
## How to Deploy

1.  **Clone the Repository**
    ```bash
    git clone <your-repo-url>
    cd <your-repo-directory>
    ```

2.  **Package the .NET Application**
    Navigate to your .NET Blazor application's source directory and run the following commands to create a deployment ZIP file.
    ```bash
    # Publish the application
    dotnet publish --configuration Release

    # Create the ZIP file (from within the publish directory)
    cd bin/Release/net9.0/publish/
    zip -r ./RemoteClient.zip .
    ```
    Move the generated `RemoteClient.zip` file into the root of this Terraform project directory.

3.  **Initialize Terraform**
    This command downloads the necessary providers (Docker and AWS).
    ```bash
    terraform init
    ```

4.  **Review the Plan**
    See what infrastructure Terraform will create.
    ```bash
    terraform plan
    ```

5.  **Apply the Configuration**
    This command builds all the resources defined in the `.tf` files. This step will take 5-15 minutes.
    ```bash
    terraform apply
    ```
    Once complete, Terraform will output the public URL for your live Elastic Beanstalk application.

---
## Cleanup

To avoid ongoing charges for cloud resources, you must destroy the infrastructure when you are finished.

**Warning**: This action is irreversible and will permanently delete all resources created by Terraform.

```bash
terraform destroy
```

Enter yes when prompted to confirm.
