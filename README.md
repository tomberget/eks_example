# Terraform Setup

Terraform setup to spin up basics in AWS

## Structure

Description of files and directories within this directory.

| Path                             | Description |
|----------------------------------|-------------------------------------------|
| [`charts`](./charts/) | Helm charts deployed along with the infrastructure |
| [`env`](./env/) | Holding variable files for environments (test, prod etc) |
| [`modules`](./modules/) | Holding the local modules created |
| [`remote-state-create`](./remote-state-create/) | Configuration of S3 bucket with state lock provided by DynamoDB |
| [`.terraform.lock.hcl`](./.terraform.lock.hcl)     | Terraform version lock file |
| [`backend.tf`](./backend.tf)     | Configuration of [Terraform state backend][terraform_backend] |
| [`eks.tf`](./eks.tf)             | Configuration of EKS cluster |
| [`modules.tf`](./modules.tf) | Configuration of applications to deploy |
| [`network.tf`](./network.tf) | Configuration of network resources to deploy |
| [`policies.tf`](./policies.tf) | Configuring the necessary policies to use |
| [`providers.tf`](./providers.tf) | Configuration of AWS [Terraform providers][terraform_providers] |
| [`variables.tf`](./variables.tf) | Declaration of top level project variables |
| [`versions.tf`](./versions.tf)   | Declaration of required minimum Terraform version to use |

[terraform_backend]: https://www.terraform.io/docs/backends/index.html
[terraform_providers]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs

## Prerequsites

Amazon Web Services (AWS) IAM Admin user with both:

* Programmatic access
* AWS Management Console access

## Setup

### AWS CLI

#### Create an AWS profile to use for the CLI

* This will only need to be performed one time, as you can reuse the same profile later.

Create a profile using the `aws` command line, filling in values for `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name` and `Default output format`.

* Note that by omitting the `--profile`, the profile will be created as `default`, and you will not need to specify `--profile` for subsequent commands. However, you can set the AWS_PROFILE environment variable to a certain profile, and all commands will be executed as that profile: `export AWS_PROFILE="<profile_name>"`.
* Also note that the default AWS output format is JSON. If omitted, JSON will be used. The credentials file later used in this example relies on JSON output.

```bash
aws configure [--profile <profile_name>]
```

#### Create an IAM user to use for Terraform only

* This will only be done one time, as the `terraform` user credentials must be shared with the users creating the Terraform scripts, as well as the CI/CD.

Create an IAM group, and the IAM user that we are using in order to run the Terraform scripts. Add the user to the group.

```bash
aws iam create-group --group-name IaC
aws iam create-user --user-name terraform
aws iam add-user-to-group --user-name terraform --group-name IaC
```

Verify that the user has been added to the group by running the following command:

```bash
aws iam get-group --group-name IaC
```

Provide the group with an IAM managed policy with sufficient rights. Terraform will create and destroy items all over the place, and will require extensive rights. In this example, the `AdministratorAccess` right is used:

```bash
aws iam attach-group-policy --group-name IaC --policy-arn $(aws iam list-policies --query 'Policies[?PolicyName==`AdministratorAccess`].{ARN:Arn}' --output text)
```

Verify that the policy has been attached by executing the command:

```bash
aws iam list-attached-group-policies --group-name IaC
```

Create the terraform user access key, and pipe the result to a credentials file:

```bash
aws iam create-access-key --user-name terraform > credentials.json
```

#### Export environmental variables from the credentials file

Move the `.json` file somewhere safe and set the following environment variables:

* Note that in this example, the region eu-west-1 is used. You may, of course, use a different region, but keep in mind to use the same region everywhere.

```bash
export AWS_ACCESS_KEY_ID=$(cat /path/to/credentials/file.json | jq -r '.AccessKey.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat /path/to/credentials/file.json | jq -r '.AccessKey.SecretAccessKey')
export AWS_DEFAULT_REGION="eu-west-1"
export TERRAFORM_ENVIRONMENT=test
```

### Create backend storage with state lock

> See the `remote-state-create` folder for how to set it up. Please remember to export your environment variables for the backend:

```bash
export TERRAFORM_STATE_AWS_BUCKET=<Your bucket name>
export TERRAFORM_STATE_DYNAMODB_TABLE=<Your table name>
```

## Terraform Init

* Navigate back to the main Terraform script in order to set the remote state location.

```bash
terraform init -reconfigure -backend-config="dynamodb_table=${TERRAFORM_STATE_DYNAMODB_TABLE}" -backend-config="bucket=${TERRAFORM_STATE_AWS_BUCKET}"
terraform workspace new ${TERRAFORM_ENVIRONMENT} #This only needs to be done the first time
```

## Select the right workspace

Ensure that you are using the correct workspace when running plan (and apply) by setting the workspace to the Environment Variable. This command only needs to be set when changing between environments or Terraform scripts.

```bash
terraform workspace select ${TERRAFORM_ENVIRONMENT}
```

## Terraform Plan

```bash
terraform plan -var-file=env/${TERRAFORM_ENVIRONMENT}.tfvars
```

### Terraform Plan with Out file

The idea behind using an `-out` file, is that the apply will not need to run the the plan section one more time. It can, instead, read and execute upon the saved `.tfplan` file. If you create a `.tfplan` file, please use the `Terraform Apply with Out file` in order to apply changes.

```bash
terraform plan -var-file=env/${TERRAFORM_ENVIRONMENT}.tfvars -out ${TERRAFORM_ENVIRONMENT}.tfplan
```

## Terraform Apply

```bash
terraform apply -var-file=env/${TERRAFORM_ENVIRONMENT}.tfvars
```

### Terraform Apply with Out file

> Only valid if you have created a `.tfplan` file for it to apply.
> You will NOT be asked to accept the changes when using this.

```bash
terraform apply ${TERRAFORM_ENVIRONMENT}.tfplan
```

## Kubernetes Credentials

Run the following command in order to fetch the credentials for the new
Kubernetes cluster:

```bash
aws eks --region region update-kubeconfig --name cluster_name
```

You can now list the running pods with the `kubectl` command:

```bash
kubectl get pods --all-namespaces
```
