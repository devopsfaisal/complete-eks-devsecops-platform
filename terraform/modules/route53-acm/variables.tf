variable "domain_name" {
  description = "Base domain hosted on Route 53 (e.g. faisal.host)"
  type        = string
  default     = "faisal.host"
}

variable "subdomain" {
  description = "Subdomain to provision (e.g. eks.faisal.host)"
  type        = string
  default     = "eks.faisal.host"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}
