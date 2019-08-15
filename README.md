# Dome9 Automatic Registration via Terraform

---

## Requirements
- [provider.restapi](https://github.com/Mastercard/terraform-provider-restapi): version = "~> 1.3"
- provider.aws: version = "~> 1.33"
- provider.template: version = "~> 1.0"
- provider.null: version = "~> 1.0"

---

## Usage

### What this is?

This is the public repoository for Palantir's Terraform module leveraging a RESTAPI provider to manage AWS Cloud Accounts inside Dome9. 

It will do the following things: 
1. Create a new policy within the target AWS accounts for the extra permissions needed as outlined in the Dome9 documentation.
2. Create a role for Dome9 to assume to perform security and compliance scans within the target account. 
3. Attach the Security Audit managed policy to the newly created role.
4. Attach the additionally created managed-policy to the newly created role.
5. Attach the Inspector ReadOnly managed policy to the newly created role.
6. Creates cross account role assumption parameters for Dome9 platform to assume this newly defined role
7. Makes call to Dome9 API to add AWS account to your Dome9 account.
8. Schedules a defined compliance scan for the newly added AWS account in your Dome9 account.

The RESTAPI provider also supports the inverse actions for account removal when using `terraform destroy`

### When to use this repo.

This repo is intended to be used as an imported module to your terraform codebase. It does not include the restapi provider configuration nor binary
and therefore must be manually pulled into your repo to use in Terraform.

Prior to running this code, you must know the following variables:

* `dome9_user`: User ID string for the Dome9 platform. This will be presented to you when you create an API key in the Dome9 console.
* `account_name`: Friendly human readable account name
* `dome9_external_id`: External ID used for assuming a role within Dome9.
* `dome9_policy_bundble_id`: This is the PolicyBundleId within Dome9. The value is an integer cast as a string and can be found from within the developer console when interacting with the Dome9 policies within your web-view of the dashboard.
* `dome9_notification_id`: This is the notificationIds within Dome9. A notification is how findings should be presented to you during a scan. Can also be found within the developer console in the Dome9 web-view. Format: `00000000-0000-0000-0000-000000000000`
* `dome9_secret`: Private portion of the API key used to add accounts to Dome9.

### Local runs:

* Initial run of terraform init to download the AWS provider, and AWS template.
* Run terraform plan -var account_name='MYACCOUNT NAME' -var dome9_secret=SECRET to sanity check the output.
* Run terraform apply -var account_name='MYACCOUNT NAME' -var dome9_secret=SECRET


#### Example Terraform configuration
```
terraform {
  required_version = "~> 0.11.8"
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 1.38.0"
}

provider "restapi" {
  version      = "~> 1.4.0"
  uri          = "https://api.dome9.com/"
  username     = "${var.dome9_user}"
  password     = "${var.dome9_secret}"
  id_attribute = "id"

  headers = {
    "Content-Type" = "application/json"
    "Accept"       = "application/json"
  }

  debug                = true
  write_returns_object = true
}

module "dome9-registration" {
  source = "<HOSTNAME>/<NAMESPACE>/<NAME>/<PROVIDER>/terraform-aws-dome9-1.0.0.tgz"
  account_name = "Human friendly account name"
}

```

## Contributing
Contributions, fixes, and improvements can be submitted directly against this project as a GitHub issue or pull request. 

## License
MIT License

Copyright (c) 2017 Palantir Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
