###############################################################################
#
# vault-k8s
#
# A Terraform project that manages a Google Kubernetes Engine cluster with
# the Vault Helm chart installed in it.
#
###############################################################################

terraform {
    required_version = "~> 0.12"
}

provider "google-beta" {
    project = "vault-k8s-marc"
    region  = "us-central1"

    version = "~> 3.1"
}

provider "google" {
    project = "vault-k8s-marc"
    region  = "us-central1"

    version = "~> 2.20"
}

###############################################################################
#
# vpc_network module
#   Provisions a VPC network.
#
###############################################################################

module "vpc_network" {
    source = "git::git@github.com:gruntwork-io/terraform-google-network.git//modules/vpc-network?ref=v0.2.7"

    project     = "vault-k8s-marc"
    region      = "us-central1"
    name_prefix = "vault-k8s"
}

###############################################################################
#
# gke_cluster module
#   Provisions a GKE cluster.
#
###############################################################################

module "gke_cluster" {
  source = "git::git@github.com:gruntwork-io/terraform-google-gke.git//modules/gke-cluster?ref=v0.3.7"

  name = "vault-k8s-cluster"

  project  = "vault-k8s-marc"
  location = "us-central1"

  # We're using a 'public' subnetwork in our VPC Network for outbound internet access
  network                      = module.vpc_network.network
  subnetwork                   = module.vpc_network.public_subnetwork
  cluster_secondary_range_name = module.vpc_network.public_subnetwork_secondary_range_name

  enable_private_nodes = true

  # When creating a private cluster, the 'master_ipv4_cidr_block' must have a size of /28
  master_ipv4_cidr_block = "10.128.0.0/28"

  # To make interacting with this example’s cluster easier, we:
  #   - keep the public cluster master endpoint available.
  #   - allow all inbound traffic to the cluster master
  # In production, we highly recommend restricting access to only within the network boundary
  # requiring Kubernetes users to use a bastion host within your cluster’s VPC network or a VPN.
  disable_public_endpoint           = false
  master_authorized_networks_config = [{
    cidr_blocks = [{
      cidr_block   = "135.23.94.39/32"
      display_name = "all-for-testing"
    }]
  }]
}