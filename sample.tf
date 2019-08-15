terraform {
  required_version = "~> 0.11.8"
}

provider "aws" {
  region  = "us-east-1"
  version = "~> 1.38.0"
}

provider "restapi" {
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
