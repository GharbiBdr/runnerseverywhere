variable "project_id" {
  description = "GCP Project to deploy resources"
}

variable "domain" {
  description = "Gitlab domain"
}

variable "token" {}

variable "region" {
  default     = "us-central1"
  description = "GCP region to deploy resources to"
}