# Terraform Remote State Setup

Terraform setup to spin up S3 state bucket

## Structure

Description of files and directories within this directory.

| Path                             | Description |
|----------------------------------|-------------------------------------------|
| [`main.tf`](./main.tf) | Configuration of applications to deploy |

[terraform_backend]: https://www.terraform.io/docs/backends/index.html
[terraform_providers]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## Prerequsites

Amazon Web Services (AWS) IAM Admin user with both:

* Terraform user created as desribed in the main `README`

## Setup

### Create backend storage with state lock

* This only needs to be done one time as the bucket will be there.

> Note that you can reuse S3 backends to hold more than one state file, or you can create more S3 buckets. This will, of course, affect how you run this script.

It is easier to actually create the S3 bucket for storing the remote state using Terraform. Especially if state locking is introduced, which is a requirement  when collaborating and using a CI/CD pipeline.

Run `terraform init` to configure, and `terraform plan` to see the changes that will be introduced:

```bash
terraform init
terraform plan -var-file=../env/${TERRAFORM_ENVIRONMENT}.tfvars
```

Verify the plan content, and when satisfied run `terraform apply` to create the resources.

```bash
terraform apply -var-file=../env/${TERRAFORM_ENVIRONMENT}.tfvars
````

This will create a S3 bucket with a globally unique name, as well as a DynamoDB state lock table. The names of these resources must be set as Environmental variables to be used when running `terraform init` for the main script, as they provide the information needed for creating the state file remotely.

```bash
export TERRAFORM_STATE_AWS_BUCKET=<Your bucket name>
export TERRAFORM_STATE_DYNAMODB_TABLE=<Your table name>
```
