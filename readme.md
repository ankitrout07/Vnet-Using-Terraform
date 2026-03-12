# AWS Multi-Tier VPC Fortress (Production-Grade Network)

## Project Overview
This project implements a high-availability, 3-tier Virtual Private Cloud (VPC) architecture on AWS using Terraform. It follows the **Principle of Least Privilege** by isolating infrastructure into Public, Private (Application), and Isolated (Data) network layers.



## Architecture Components
* **Tier 1: Public Subnets** - Hosts the Application Load Balancer (ALB) and NAT Gateway. Accessible from the IGW.
* **Tier 2: Private App Subnets** - Hosts EC2/EKS workloads. No direct internet ingress; outbound traffic via NAT Gateway.
* **Tier 3: Isolated Data Subnets** - Hosts RDS/Elasticache. No internet ingress or egress.
* **NAT Gateway** - Single-point outbound valve for security updates in Tier 2.
* **Internet Gateway (IGW)** - Provides communication between the VPC and the internet.

## Technical Specifications
| Feature | Configuration |
| :--- | :--- |
| **VPC CIDR** | `10.0.0.0/16` |
| **Regions/AZs** | `us-east-1` (a, b) |
| **Security** | State Locking via AzureRM Remote Backend |
| **IAC Tool** | Terraform v1.x+ |
| **Platform** | Ubuntu 24.04 LTS |

## Prerequisites
1.  **AWS CLI v2** configured with appropriate IAM permissions.
2.  **Terraform** installed on Ubuntu.
3.  **Remote State** storage (Azure Storage Account) initialized from the previous project.

## Deployment Instructions

### 1. Initialize the Environment
Connect to the Azure Remote Backend and download providers.
```bash
terraform init