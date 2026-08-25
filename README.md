# Secure Automated Web Architecture

## Description
This project automates the deployment of a hardened, public-facing web server environment on AWS using Terraform infrastructure-as-code. The architecture incorporates automated static application security testing (SAST) using `tfsec` within a GitHub Actions CI/CD pipeline to ensure continuous compliance and security quality gates.

## Technologies Used
* **AWS** (VPC, Subnet, Internet Gateway, Security Group, EC2, EBS, IMDSv2)
* **Terraform** (Infrastructure as Code)
* **GitHub Actions** (CI/CD Automation Pipeline)
* **tfsec** (Static Application Security Testing)

## Architecture
The infrastructure is built inside a dedicated Virtual Private Cloud (VPC) with a single public subnet routed through an Internet Gateway. Network security is enforced via a security group that restricts inbound SSH access exclusively to designated administrative IP addresses while allowing public HTTP access for web traffic. The EC2 instance is hardened with compulsory Instance Metadata Service Version 2 (IMDSv2) and encrypted EBS root storage volumes.