
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
  roles      = ["roles/storage.admin", "roles/compute.admin", "roles/owner"]
}


# deploy runners using helm chart
resource "helm_release" "runner" {
  name       = "runners"
  repository = "https://charts.gitlab.io"
  chart      = "gitlab-runner"
  #create_namespace = true
  #namespace = default

  values = [templatefile("./values.tmpl", {
    GITLABURL = var.domain
    TOKEN = var.token
    SERVICEACCOUNT = module.my-app-workload-identity.k8s_service_account_name
    NAMESPACE = module.my-app-workload-identity.k8s_service_account_namespace
    TAG = var.project_id
  })]

}









module "test" {
  source     = "terraform-google-modules/kubernetes-engine/google//modules/workload-identity"
  name       = "testfromprojecttoproject"
  namespace  = "test"
  project_id = "multiproject-328509"
  roles      = ["roles/storage.admin", "roles/compute.admin", "roles/owner"]
}