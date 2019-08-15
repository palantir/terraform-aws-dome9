## MIT License
## 
## Copyright (c) 2019 Palantir Technologies
## 
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
## 
## The above copyright notice and this permission notice shall be included in all
## copies or substantial portions of the Software.
## 
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.
## 

## Establish the callers AWS account number
data "aws_caller_identity" "current" {
  count = "${var.enable == "true" ? 1 : 0}"
}

## Json payload to register the account with Dome9
data "template_file" "account_json" {
  template = "{ \"name\": \"$${account_name}\", \"credentials\": { \"arn\": \"arn:aws:iam::$${account_id}:role/$${role_name}\", \"secret\": \"$${external_id}\", \"type\": \"RoleBased\" } }"

  vars {
    account_name = "${var.account_name}"
    account_id   = "${data.aws_caller_identity.current.account_id}"
    role_name    = "${var.dome9_role_name}"
    external_id  = "${var.dome9_external_id}"
  }

  count = "${var.enable == "true" ? 1 : 0}"
}

## TODO: AWS role doesn't get created fast enough and Dome9 chokes
## should implement a retry in the restapi provider
resource "null_resource" "delay" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  triggers = {
    "before" = "${aws_iam_role.dome9-role.name}"
  }

  count = "${var.enable == "true" ? 1 : 0}"
}

## Dome9 account registration
resource "restapi_object" "account" {
  path       = "/v2/CloudAccounts"
  read_path  = "/v2/CloudAccounts/${data.aws_caller_identity.current.account_id}"
  data       = "${data.template_file.account_json.rendered}"
  depends_on = ["null_resource.delay"]
  count      = "${var.enable == "true" ? 1 : 0}"
}

data "template_file" "continuous_compliance_json" {
  template = "{ \"cloudAccountId\": \"$${dome9_id}\", \"externalAccountId\": \"$${account_id}\", \"cloudAccountType\": \"Aws\", \"bundleId\": \"$${dome9_policy_bundle_id}\" , \"notificationIds\": [ \"$${dome9_notification_id}\" ] }"

  vars {
    dome9_id               = "${restapi_object.account.id}"
    account_id             = "${data.aws_caller_identity.current.account_id}"
    dome9_policy_bundle_id = "${var.dome9_policy_bundle_id}"
    dome9_notification_id  = "${var.dome9_notification_id}"
  }

  count = "${var.enable == "true" ? 1 : 0}"
}

resource "restapi_object" "compliance_policy" {
  path  = "/v2/Compliance/ContinuousCompliancePolicy"
  data  = "${data.template_file.continuous_compliance_json.rendered}"
  count = "${var.enable == "true" ? 1 : 0}"
}

############################################
# Below this comment is the AWS IAM Policies
############################################

## Role for Dome9 to assume
resource "aws_iam_role" "dome9-role" {
  name               = "dome9-role"
  assume_role_policy = "${data.aws_iam_policy_document.dome9-assume-role.json}"
  count              = "${var.enable == "true" ? 1 : 0}"
}

## Cross account assume role policy document
data "aws_iam_policy_document" "dome9-assume-role" {
  statement {
    effect = "Allow"

    principals = {
      type        = "AWS"
      identifiers = ["arn:aws:iam::634729597623:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      values = [
        "${var.dome9_external_id}",
      ]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }

  count = "${var.enable == "true" ? 1 : 0}"
}

## Expanded ReadOnly permission set beyond SecurityAudit and Inspector ReadOnly policy
resource "aws_iam_policy" "dome9-readonly-policy" {
  name   = "dome9-readonly-policy"
  policy = "${data.aws_iam_policy_document.dome9-read-only.json}"
  count  = "${var.enable == "true" ? 1 : 0}"
}

## Attach expanded readonly permission set to Dome9 role
resource "aws_iam_role_policy_attachment" "dome9-readonly" {
  role       = "${aws_iam_role.dome9-role.name}"
  policy_arn = "${aws_iam_policy.dome9-readonly-policy.arn}"
  count      = "${var.enable == "true" ? 1 : 0}"
}

## Attach stock SecurityAudit policy to the Dome9 role
resource "aws_iam_role_policy_attachment" "dome9-security-audit" {
  role       = "${aws_iam_role.dome9-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
  count      = "${var.enable == "true" ? 1 : 0}"
}

## Attach stock Inspector ReadOnly policy to the Dome9 role
resource "aws_iam_role_policy_attachment" "dome9-inspector-readonly" {
  role       = "${aws_iam_role.dome9-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonInspectorReadOnlyAccess"
  count      = "${var.enable == "true" ? 1 : 0}"
}

## Expanded ReadOnly permission set needed by Dome9
data "aws_iam_policy_document" "dome9-read-only" {
  statement {
    sid = "Dome9ReadOnly"

    actions = [
      "cloudtrail:LookupEvents",
      "dynamodb:DescribeTable",
      "elasticfilesystem:Describe*",
      "elasticache:ListTagsForResource",
      "firehose:Describe*",
      "firehose:List*",
      "guardduty:Get*",
      "guardduty:List*",
      "kinesis:List*",
      "kinesis:Describe*",
      "kinesisvideo:Describe*",
      "kinesisvideo:List*",
      "logs:Describe*",
      "logs:Get*",
      "logs:FilterLogEvents",
      "lambda:List*",
      "s3:List*",
      "sns:ListSubscriptions",
      "sns:ListSubscriptionsByTopic",
      "waf-regional:ListResourcesForWebACL",
    ]

    effect = "Allow"

    resources = ["*"]
  }

  count = "${var.enable == "true" ? 1 : 0}"
}
