
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
      "iam.gke.io/gcp-service-account" = "gke-deployer@multiproject-328509.iam.gserviceaccount.com"
    }
  }
  depends_on = [
    google_container_cluster.runners,
  ]
}

resource "google_service_account" "sa" {
  account_id   = "gke-deployer"
  display_name = "deployer"
}

resource "google_service_account_iam_member" "main" {
  service_account_id = "gke-deployer@multiproject-328509.iam.gserviceaccount.com"
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${kubernetes_namespace.runner.metadata[0].name}/${kubernetes_service_account.runner-sa.metadata[0].name}]"
}



# deploy runners using helm chart
resource "helm_release" "runner" {
  name       = "runners"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  #create_namespace = true
  namespace = kubernetes_namespace.runner.metadata[0].name

  values = [templatefile("./values.tmpl", {
    GITLABURL = var.domain
    TOKEN = var.token
    SERVICEACCOUNT = "deployer"
    NAMESPACE = kubernetes_namespace.runner.metadata[0].name
    TAG = var.project_id
  })]

}