variable "project_id" {
  description = "The GCP project ID for dev environment"
  type        = string
  default     = "ezcopro-dev"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
