variable "ress" {}
provider "google" {
    project = "multiproject-328509"
}
resource "google_service_account" "sa" {
  account_id   = "gke-deployerfromgithub"
  display_name = "deployer"
}

resource "google_project_iam_member" "role" {
  project = "multiproject-328509"
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.sa.email}"
}

resource "google_service_account_iam_member" "main" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.ress}"
}