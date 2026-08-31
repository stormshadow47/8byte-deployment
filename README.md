# Infrastructure as Code (IaC) Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture](#architecture)
3. [Security](#security)
4. [Provisioning with Terraform](#provisioning-with-terraform)
5. [Database Setup](#database-setup)
6. [CI/CD Pipeline](#cicd-pipeline)
7. [Troubleshooting](#troubleshooting)
8. [Cost Optimization](#cost-optimization)
9. [Monitoring](#monitoring)
10. [Appendix: Useful Commands](#appendix-useful-commands)

---

## Prerequisites

**Tools**
- Terraform >= 1.0
- AWS CLI >= 2.0
- Git
- Docker (for local testing)

**AWS credentials**
```bash
aws configure
```
Set region to `us-east-1` and output format to `json`.

**IAM permissions needed**: EC2, VPC, ECS, ECR, RDS, ALB, CloudWatch, IAM, S3 (Terraform state), DynamoDB (state locking).

---

## Architecture

GitHub Actions builds and pushes Docker images to ECR, then deploys them to ECS (Fargate) behind an Application Load Balancer. The app talks to a PostgreSQL RDS instance. Frontend and backend each run as separate ECS services.

**Core components**
- **VPC** — public subnets for the ALB, private subnets for ECS and RDS, NAT Gateway for outbound access
- **Security groups** — ALB accepts HTTP/HTTPS from the internet; ECS only accepts traffic from the ALB (ports 3000/8000); RDS only accepts traffic from ECS (port 5432)
- **ECR** — separate repos per environment/service (`todoapp-{staging,production}-{frontend,backend}`)
- **ECS (Fargate)** — separate clusters for frontend and backend, so each can scale and deploy independently
- **ALB** — layer 7 routing, health checks.
- **RDS (PostgreSQL)** — Multi-AZ, encrypted at rest, automated backups
- **CloudWatch Logs** — one log group per service/environment

**Why these choices:**
- Fargate over EC2 — no servers to patch or manage, pay only for what's used
- Separate staging/production Terraform workspaces — test changes safely before they hit prod, no shared resources between environments
- S3 + DynamoDB for Terraform state — durable, encrypted, and locks prevent concurrent applies from clobbering each other

---

## Approach

This project uses a modern, cloud-native approach to deploy a full-stack Todo application on AWS.

**Infrastructure as Code (IaC)**
- Terraform modules for reusable infrastructure components (VPC, ECS, RDS, ALB, ECR)
- Separate environments (staging/production) with isolated Terraform workspaces
- S3 backend with DynamoDB for state management and locking
- Infrastructure is version-controlled alongside application code

**Containerization**
- Multi-stage Docker builds for both frontend (Next.js) and backend (FastAPI)
- Separate ECR repositories per environment and service
- Images tagged with Git commit SHA for traceability
- Slim base images to reduce attack surface and image size

**CI/CD Pipeline**
- GitHub Actions for automated testing, building, and deployment
- Pipeline runs on every push to staging or main branches
- Automated security scanning (Trivy for images, Gitleaks for secrets)
- Tests run before deployment to catch issues early
- Manual approval gate for production deployments

**Deployment Strategy**
- Blue-green style deployments via ECS service updates
- Separate ECS clusters for frontend and backend for independent scaling
- Load balancer health checks ensure only healthy tasks receive traffic
- Zero-downtime deployments with `force-new-deployment`

**Database Management**
- Managed PostgreSQL via RDS for operational simplicity
- Credentials stored in AWS Secrets Manager for security
- Automated backups and Multi-AZ for high availability
- Connection strings injected at runtime via ECS task definitions

**Monitoring and Observability**
- CloudWatch Logs for centralized logging
- CloudWatch Metrics for performance monitoring
- Resource tagging for cost allocation and identification
- CloudTrail for audit logging

---

## Security

- Private subnets for ECS/RDS — nothing there is directly reachable from the internet, and there's no inbound SSH
- Security groups follow least privilege (only required ports open)
- RDS and Terraform state are encrypted at rest.
- Container Security: Containers run as non-root, on slim base images, Trivy scans images in CI/CD pipeline.
- DB credentials can be injected via AWS Secrets Manager rather than as plain environment variables.
- IAM roles are scoped per task, no hardcoded credentials anywhere.
- CI pipeline runs Trivy (image vulnerability scanning) and Gitleaks (secret scanning) on every build
- CloudTrail covers audit logging; resources are tagged for cost tracking

---

## Provisioning with Terraform

```bash
cd terraform/environments/staging
terraform init
```

Create your vars file:
```bash
cp staging.tfvars.example staging.tfvars
```

Fill in `staging.tfvars`:
```hcl
project        = "todoapp"
environment    = "staging"
region         = "us-east-1"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

db_instance_class  = "db.t3.micro"
db_name            = "todoapp_staging"
db_username        = "todoapp_admin"
db_password        = "your_secure_password_here"
allocated_storage  = 20

frontend_cpu    = 256
frontend_memory = 512
backend_cpu     = 256
backend_memory  = 512

```

```bash
terraform plan -var-file=staging.tfvars
terraform apply -var-file=staging.tfvars
```


```bash
terraform output rds_endpoint
terraform output alb_dns_name
```

For production, repeat the same steps from `terraform/environments/production`.

To tear an environment down:
```bash
terraform destroy -var-file=staging.tfvars
```

---

## Database Setup

Build the connection string from the Terraform output:
```
postgresql://<db_username>:<db_password>@<rds_endpoint>:5432/<db_name>
```

**Example**:
```
postgresql://todoapp_admin:SecurePass123@todoapp-staging.xxxx.us-east-1.rds.amazonaws.com:5432/todoapp_staging
```


### AWS Secrets Manager

Create a secret per environment:
```bash
aws secretsmanager create-secret \
  --name todoapp/staging/database-url \
  --description "PostgreSQL database connection URL for staging" \
  --secret-string "postgresql://todoapp_admin:SecurePass123@todoapp-staging.xxxx.us-east-1.rds.amazonaws.com:5432/todoapp_staging" \
  --region us-east-1

aws secretsmanager create-secret \
  --name todoapp/production/database-url \
  --description "PostgreSQL database connection URL for production" \
  --secret-string "postgresql://todoapp_admin:SecurePass123@todoapp-production.xxxx.us-east-1.rds.amazonaws.com:5432/todoapp_production" \
  --region us-east-1
```

Verify or update it later:
```bash
aws secretsmanager get-secret-value --secret-id todoapp/staging/database-url --region us-east-1

aws secretsmanager update-secret \
  --secret-id todoapp/staging/database-url \
  --secret-string "postgresql://newuser:newpass@endpoint:5432/dbname" \
  --region us-east-1
```

The ECS task execution role needs read access:
```hcl
resource "aws_iam_policy" "secrets_access" {
  name        = "ecs-secrets-access"
  description = "Allow ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:us-east-1:123456789012:secret:todoapp/staging/database-url-*",
          "arn:aws:secretsmanager:us-east-1:123456789012:secret:todoapp/production/database-url-*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_custom" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
```



### Connecting locally

```bash
sudo apt-get install postgresql-client
psql -h <rds_endpoint> -U <db_username> -d <db_name>
```

---

## CI/CD Pipeline

`.github/workflows/deploy.yml` runs three jobs: tests, secret scanning (Gitleaks), and build/scan/deploy.

```yaml
- name: Run frontend tests
  run: npm test

- name: Run backend tests
  run: |
    cd api
    pytest --cov=. --cov-report=xml

- name: Run Gitleaks
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

- name: Build frontend image
  run: docker build -t todoapp-frontend:${{ env.IMAGE_TAG }} .

- name: Run Trivy on frontend image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: todoapp-frontend:${{ env.IMAGE_TAG }}
    format: 'table'
    severity: 'CRITICAL,HIGH'

- name: Push to ECR
  run: docker push ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY_FRONTEND }}:${{ env.IMAGE_TAG }}

- name: Deploy to ECS
  run: |
    aws ecs update-service --cluster todoapp-staging-frontend-cluster --service todoapp-staging-frontend-service --force-new-deployment
    aws ecs wait services-stable --cluster todoapp-staging-frontend-cluster --services todoapp-staging-frontend-service
```

**Required GitHub secrets**: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `EMAIL_USERNAME`, `EMAIL_PASSWORD`, `NOTIFICATION_EMAIL`



---

## Troubleshooting

**Terraform state locked**
```bash
terraform force-unlock <LOCK_ID>
```
Only do this if you're sure no one else is at mid-apply.

**ECS deployment issues**
```bash
aws ecs describe-services --cluster <cluster-name> --services <service-name>
aws logs tail /ecs/<log-group-name> --follow
```

**Database connection issues**
```bash
psql -h <rds-endpoint> -U <username> -d <dbname>
aws ec2 describe-security-groups --group-ids <sg-id>
```

**Docker build fails**
```bash
docker build -t test-image .
docker run -it test-image sh
```

Known issues/challenges and resolutions:
- Ran into several 500 and 504 errors on staging due to RDS misconfigurations: Formulated a new manual database URL construction strategy and documented it's addition to secrets manager.
- Application resolution due to misconfigured security groups config in Terraform: Created a dedicated module for SG addressing backend ingress for FastAPI's port 8000 to resolve issue.
- `psycopg2-binary` has no prebuilt wheel for Python 3.13 — stick to 3.12 for now
- `npm ci` will fail if `package-lock.json` is out of sync — `npm install` is recommended.
- Exclude `__tests__` from `tsconfig.json`'s compile scope, or the production build will fail on test files

---

## Cost Optimization

- Consider Fargate Spot for non-critical workloads
- Turn on ECS auto-scaling based on CPU/memory
- Keep staging on `db.t3.micro`
- Add S3 lifecycle rules to clean up old Terraform state versions
- Set shorter CloudWatch log retention in staging

**Rough staging cost**: RDS ~$15, ECS ~$20, ALB ~$18, NAT Gateway ~$32, CloudWatch ~$5–10 → **~$90–100/month**

---

## Monitoring

Watch these CloudWatch metrics:
- **ECS**: CPUUtilization, MemoryUtilization, task count
- **ALB**: RequestCount, TargetResponseTime, HTTPCode_Target_5XX
- **RDS**: CPUUtilization, FreeableMemory, DatabaseConnections

Example alarm:
```bash
aws cloudwatch put-metric-alarm \
  --alarm-name ecs-high-cpu \
  --alarm-description "Alert when ECS CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

---

## Service runtime screenshots:



<img width="1917" height="553" alt="Screenshot From 2026-08-31 13-55-48" src="https://github.com/user-attachments/assets/570cf5e8-c51c-4081-b25e-54e635f42f20" />


<img width="1912" height="652" alt="Screenshot From 2026-08-31 13-56-30" src="https://github.com/user-attachments/assets/d744d6f4-27a0-4dc4-aebf-45231f59f634" />


<img width="1912" height="652" alt="Screenshot From 2026-08-31 13-57-43" src="https://github.com/user-attachments/assets/9e8a4600-4763-4b66-ab7d-0ca956c491cc" />


<img width="1676" height="487" alt="Screenshot From 2026-08-31 14-09-17" src="https://github.com/user-attachments/assets/c779fb1a-cf9d-4a80-ab3a-9a9f29a6ad2d" />


<img width="1676" height="487" alt="Screenshot From 2026-08-31 14-13-42" src="https://github.com/user-attachments/assets/795fd689-3dad-4985-92aa-7a93377541ca" />


<img width="1917" height="482" alt="Screenshot From 2026-08-31 14-58-18" src="https://github.com/user-attachments/assets/faeed489-2922-4ff4-8007-22937697fe52" />



## Appendix: Useful Commands

**Terraform**
```bash
terraform state list
terraform state show <resource_address>
terraform import <resource_address> <resource_id>
terraform refresh
terraform fmt -recursive
terraform validate
```

**AWS CLI**
```bash
aws ecs list-clusters
aws ecs list-services --cluster <cluster-name>
aws ecs describe-task-definition --task-definition <task-def-name>
aws ecr describe-repositories
aws rds describe-db-instances --db-instance-identifier <db-id>
```
