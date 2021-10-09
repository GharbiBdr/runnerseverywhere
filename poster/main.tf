provider "google" {
    project = "multiproject-328509"
}
resource "google_service_account" "sa" {
  account_id   = "gke-deployer"
  display_name = "deployer"
}