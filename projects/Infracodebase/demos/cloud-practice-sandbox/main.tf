# ---------------------------------------------------------------------------
# VPC Network
# ---------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false

  # google_compute_network does not support the standard `labels` argument;
  # labeling is done on the subnet and firewall resources below instead.
}

# ---------------------------------------------------------------------------
# Subnet — primary + two secondary ranges consumed by GKE VPC-native mode
# ---------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  name    = var.subnet_name
  region  = var.region
  network = google_compute_network.vpc.id

  ip_cidr_range = var.subnet_cidr

  # Secondary ranges must be named exactly as referenced in
  # google_container_cluster.ip_allocation_policy below.
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# ---------------------------------------------------------------------------
# Firewall — allow internal traffic across RFC-1918 10.x space
# ---------------------------------------------------------------------------
resource "google_compute_firewall" "allow_internal" {
  name    = "cloud-practice-allow-internal"
  network = google_compute_network.vpc.name

  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/8"]

  target_tags = []

  # google_compute_firewall does not support the `labels` argument in the
  # Google provider; labeling is applied via the network, subnet, and cluster.
}

# ---------------------------------------------------------------------------
# Dedicated GKE service account (least-privilege; avoids default Compute SA)
# ---------------------------------------------------------------------------
resource "google_service_account" "gke_sa" {
  account_id   = "gke-${var.cluster_name}"
  display_name = "GKE node service account for ${var.cluster_name}"
}

# Minimum roles required for nodes to write logs and metrics.
locals {
  gke_sa_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset(local.gke_sa_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# ---------------------------------------------------------------------------
# GKE Cluster — regional (control plane across all three zones)
# ---------------------------------------------------------------------------
resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.region  # regional cluster; control plane spans all zones

  # Destroy the auto-created default node pool immediately; we manage nodes
  # via the separate google_container_node_pool resource below.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  # VPC-native mode — secondary range names must exactly match those declared
  # on the subnet resource above.
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Restrict public access to the control plane API.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false  # keeps kubectl access from the internet
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Workload Identity — enables pod-level GCP IAM bindings.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  resource_labels = var.labels

  # Prevents accidental cluster deletion.
  deletion_protection = false  # set to true in non-demo environments
}

# ---------------------------------------------------------------------------
# Node Pool — per-zone autoscaling; nodes spread across all three zones
# ---------------------------------------------------------------------------
resource "google_container_node_pool" "nodes" {
  name     = "${var.cluster_name}-node-pool"
  cluster  = google_container_cluster.cluster.id
  location = var.region  # must match cluster location for a regional cluster

  # node_locations controls which zones receive nodes.  The count fields
  # (initial_node_count, autoscaling min/max) are all PER ZONE.
  node_locations = var.node_zones

  initial_node_count = var.initial_node_count  # 1 per zone → 3 nodes total

  autoscaling {
    min_node_count = var.node_min_count  # per zone
    max_node_count = var.node_max_count  # per zone
  }

  node_config {
    machine_type    = var.node_machine_type
    service_account = google_service_account.gke_sa.email

    # Restrict the OAuth scopes to the minimum needed by the dedicated SA.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # Workload Identity on the node pool side.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    labels = var.labels

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
