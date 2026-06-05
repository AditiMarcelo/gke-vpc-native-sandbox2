output "vpc_name" {
  description = "Name of the VPC network."
  value       = google_compute_network.vpc.name
}

output "subnet_name" {
  description = "Name of the primary subnet."
  value       = google_compute_subnetwork.subnet.name
}

output "cluster_name" {
  description = "Name of the GKE cluster."
  value       = google_container_cluster.cluster.name
}

output "cluster_endpoint" {
  description = "HTTPS endpoint of the GKE cluster master."
  value       = google_container_cluster.cluster.endpoint
  sensitive   = true
}

output "node_pool_name" {
  description = "Name of the managed node pool."
  value       = google_container_node_pool.nodes.name
}

output "gke_service_account_email" {
  description = "Email of the dedicated GKE node service account."
  value       = google_service_account.gke_sa.email
}
