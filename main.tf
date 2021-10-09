terraform {
   backend "gcs" {
     bucket  = "runnersdfsf"
     prefix  = "terraform/state"
   }
  required_providers {
    google = {
      source = "hashicorp/google"
    }
  }
}

provider "google" {}

resource "google_project_service" "cloudresourcemanager" {
  project            = var.project_id
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "gke" {
  project            = var.project_id
  service            = "container.googleapis.com"
  disable_on_destroy = false
}
resource "google_project_service" "iam" {
  project            = var.project_id
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}
resource "google_container_cluster" "runners" {
  name     = "runners"
  location = "${var.region}-a"
  initial_node_count       = 1
  node_config {
    machine_type = "e2-medium"
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  workload_identity_config {
    identity_namespace = "${var.project_id}.svc.id.goog"
  }
  depends_on = [
    google_project_service.gke,
  ]
}
