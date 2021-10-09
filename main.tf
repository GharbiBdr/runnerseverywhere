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
  location = var.region
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

# create namespace for runners
resource "kubernetes_namespace" "runner" {
  metadata {
    name = "deployer"
  }
}

# create kubernetes service account
resource "kubernetes_service_account" "runner-sa" {
  metadata {
    name      = "deployer"
    namespace = kubernetes_namespace.runner.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.sa.email
    }
  }
  depends_on = [
    google_container_cluster.runners,
  ]
}



resource "google_service_account_iam_member" "main" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.runner.metadata[0].name}/${kubernetes_service_account.runner-sa.metadata[0].name}]"
}

resource "google_project_iam_member" "role" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# deploy runners using helm chart
resource "helm_release" "runner" {
  name       = "runners"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"

  values = [
    "${file("./modules/gitlab-runners/helm_values/runners.yaml")}"
  ]
  set {
    name  = "gitlabUrl"
    value = var.domain
  }
  set {
    name  = "runnerRegistrationToken"
    value =  var.token
  }
  set {
    name  = "runners.namespace"
    value =  kubernetes_namespace.runner.metadata[0].name
  }
  set {
    name  = "runners.serviceAccountName"
    value =  kubernetes_service_account.runner-sa.metadata[0].name
  }
  depends_on = [
    kubernetes_service_account.runner-sa,
  ]
}

module "runner" {
  source              = "./poster"
}