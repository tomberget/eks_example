terraform {
  backend "s3" {
    # this assumes that a bucket has already been created.
    # s3 bucket permissions also need to be applied
    # https://www.terraform.io/docs/backends/types/s3.html#s3-bucket-permissions

    # note that for access credentials, a partial configuration is recommended, and used in this example:
    # https://www.terraform.io/docs/backends/config.html#partial-configuration

    # read more about Credentials and Shared Configuration here:
    # https://www.terraform.io/docs/backends/types/s3.html#credentials-and-shared-configuration

    key = "terraform/terraform.tfstate"
  }
}
