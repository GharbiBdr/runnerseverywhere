terraform {
   backend "gcs" {
     bucket  = "runnersdfsf"
     prefix  = "terraform/state"
   }
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.3.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.5.0"
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