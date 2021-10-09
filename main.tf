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

provider "google" {
    project = var.project_id
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = google_container_cluster.runners.endpoint
  cluster_ca_certificate = base64decode(google_container_cluster.runners.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

provider "helm" {
  kubernetes {
    host                   = google_container_cluster.runners.endpoint
    cluster_ca_certificate = base64decode(google_container_cluster.runners.master_auth.0.cluster_ca_certificate)
    token                  = data.google_client_config.current.access_token
  }
}
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

module "my-app-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "my-application-name"
  namespace  = "default"
  project_id = var.project_id
  roles      = ["roles/storage.admin", "roles/compute.admin"]
}

module "my-app-workload-identity" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "my-application-name"
  namespace  = "test"
  project_id = var.project_id
  roles      = ["roles/storage.admin", "roles/compute.admin"]
}
