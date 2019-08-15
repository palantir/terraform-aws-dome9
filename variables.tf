variable "account_name" {
  description = "Friendly human readable account name"
  type        = "string"
}

variable "dome9_user" {
  description = "Dome9 user ID string"
  type        = "string"
}

variable "dome9_secret" {
  description = "Dome9 secret"
  type        = "string"
}

variable "dome9_role_name" {
  description = "Dome9 Role Name"
  default     = "dome9-role"
  type        = "string"
}

variable "dome9_external_id" {
  description = "External ID used for assuming role. Not considered a secret"
  type        = "string"
}

variable "dome9_policy_bundle_id" {
  description = "The PolicyBundleId from Dome9 used to assign to the account"
  type        = "string"
}

variable "dome9_notification_id" {
  description = "The notificationIds from Dome9 just for the Policy"
  type        = "string"
}

variable "enable" {
  description = "Toggle to enable/disable the module"
  default     = "true"
  type        = "string"
}
