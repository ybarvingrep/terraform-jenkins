terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.52.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
  }
}

/*
data "terraform_remote_state" "gke" {
  backend = "local"

  config = {
    path = "../provision/terraform.tfstate"
  }
}
*/

data "tfe_outputs" "gke" {
  organization = "PEACEHAVENCORP"
  workspace = "terraform-jenkins-GKE-provision"
}

# Retrieve GKE cluster information
provider "google" {
  project = data.tfe_outputs.gke.outputs.project_id
  region  = data.tfe_outputs.gke.outputs.region
}

# Configure kubernetes provider with Oauth2 access token.
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config
# This fetches a new token, which will expire in 1 hour.
data "google_client_config" "default" {}

data "google_container_cluster" "my_cluster" {
  name     = data.tfe_outputs.gke.outputs.kubernetes_cluster_name
  location = data.tfe_outputs.gke.outputs.region
}

provider "kubernetes" {
  host = data.tfe_outputs.gke.outputs.kubernetes_cluster_host

  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}
