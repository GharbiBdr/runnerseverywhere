variable "project_id" {
  description = "The project ID to deploy to"
}
variable "region" {
  description = "The project ID to deploy to"
  default = "us-central1"
}
variable "domain" {
  description = "Gitlab domain"
}

variable "token" {
  description = "gitlab runner token"
}