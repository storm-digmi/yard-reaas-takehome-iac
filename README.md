# yard-reaas-takehome-iac
# Infrastructure for Podinfo Lambda Deployment

This repository contains the **Terraform code** that provisions the AWS infrastructure required for running Podinfo as a **serverless Lambda container** with a blue/green deployment strategy.

---

## Tools
- **Terraform** as IaC for AWS resource provisioning.  
- **GitHub Actions** as CI/CD orchestrator.  
- **AWS Test accounts** (region: `eu-central-1`).  

---

## Architecture Overview
The infrastructure consists of the following components:  

- **AWS Lambda** → Podinfo microservice, deployed as a container image.  
- **AWS API Gateway (HTTP API)** → public HTTPS exposure for the Lambda.  
- **AWS ECR** → stores container images.  
- **AWS CodeDeploy** → manages blue/green deployments with canary strategy.  
- **AWS Secrets Manager** → stores a dummy `SUPER_SECRET_TOKEN`, injected as environment variable into Lambda.  
- **Amazon CloudWatch** → observability (logs, metrics, dashboards, alarms).  

---

## Deployment Strategy
- **Lambda Alias (`prod`)** points to the live version.  
- Deployments are managed by CodeDeploy:  
  - Canary: **10% traffic for 5 minutes, then 100%**.  
  - Automatic rollback if errors are detected.  

---

## Monitoring & Observability
- **Logs**: Lambda writes to `/aws/lambda/<function-name>`. A **Data Protection Policy** ensures sensitive values from Secrets Manager are masked.  
- **Metrics**:  
  - Lambda: Invocations, Errors, Duration (P95).  
  - API Gateway: Requests, 4xx/5xx, Latency.  
- **Dashboard**: consolidated view with requests, errors, latency, and alarms.  
- **Alarm**: triggers when `HTTPCode_Target_5XX_Count ≥ 1` for 1 minute, sends notification via SNS.  

---

## IAM & Security
- **IAM Role** for GitHub Actions via OIDC federation.  
- Least-privilege permissions for Terraform and deployment pipelines.  
- Secrets never exposed in logs (CloudWatch masking in place).  

---

## Infrastructure Pipeline

The infrastructure is managed with **Terraform** and deployed via a dedicated GitHub Actions workflow.

### Workflow
- **Triggers**: on changes under `layers/aws/orbital_freight_infra/**` or manual dispatch.  
- **Steps**:  
  1. Load AWS account and backend settings (S3 + DynamoDB) from repo variables.  
  2. Authenticate to AWS using OIDC and an IAM role.  
  3. Initialize Terraform with remote state.  
  4. Run `terraform plan` to preview changes.  
  5. Optionally run `terraform apply` if `auto-apply: true` is set at dispatch.

### Design
- **Remote state** in S3 with DynamoDB lock for consistency.  
- **Plan-only by default**, to avoid accidental changes.  
- **OIDC authentication** for secure, short-lived AWS credentials.

This pipeline manages **infrastructure only**, while a separate pipeline handles **application build and deployment**.

---

## Trade-offs

### Lambda vs EC2
For this business case, I chose **AWS Lambda with container image support** instead of EC2 instances.  

**Why Lambda (chosen option):**
- **Cost efficiency**: no idle cost. You only pay per request and execution time, while with EC2 you would be charged even when the service is idle.  
- **Scalability**: Lambda automatically scales with traffic. With EC2 we would need to configure Auto Scaling Groups, policies, and capacity planning.  
- **Operational simplicity**: Lambda is fully managed (OS patching, runtime updates, HA). With EC2, the team would have to handle instance lifecycle, AMIs, patching, and monitoring.  
- **Faster iteration**: Deployment with container images + CodeDeploy is straightforward. On EC2 we would need additional provisioning (AMIs or ECS/EKS setup).  

**Why not EC2:**
- **Always-on cost**: even a single t3.micro instance would generate a fixed monthly charge, regardless of usage.  
- **Overhead**: managing security hardening, patching, scaling policies, and alarms would add unnecessary complexity for a demo/test case.  
- **Slower deployments**: rolling out a new AMI or updating a container orchestrator (ECS/EKS) would be slower than Lambda’s blue/green image switch.  

In summary, **Lambda reduces cost, improves agility, and removes infrastructure management**, which is ideal for this project where continuous deployments and quick rollbacks are required. EC2 would only make sense if we had **long-running workloads, custom networking, or OS-level dependencies** that Lambda cannot support.


---

## Cost Reference
See [AWS Pricing – EU (Frankfurt)](https://aws.amazon.com/de/pricing/) for Lambda, ECR, CodeDeploy, API Gateway, and CloudWatch services.  


