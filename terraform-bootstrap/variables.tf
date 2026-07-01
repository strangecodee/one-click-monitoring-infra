variable "backend_bucket_name" {
  description = "S3 bucket name for Terraform backend state"
  type        = string
  default     = "monitoring-stack-dev-state"
}

variable "backend_lock_table_name" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "monitoring-stack-dev-lock"
}
