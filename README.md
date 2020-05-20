# Miiingle.NET - AWS Terraform Script
Terraform Script for Setting up the AWS Infrastructure

## One-time Setup
```
choco install terraform
terraform init
```

## Prepare a Plan
```
terraform plan -out .terraform/plan -var-file="local.tfvars"
```

## Apply the Plan
```
terraform apply ".terraform/plan"
```

## Setup kubectl
```
aws eks --region us-east-1 update-kubeconfig --name <cluster name>
```

## [Danger] Destroy the Infrastructure
```
terraform destroy
```