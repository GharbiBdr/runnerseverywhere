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