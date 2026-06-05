variable "project_id" {
  description = "GCP project ID where all resources will be provisioned."
  type        = string
}

variable "region" {
  description = "GCP region for the subnet and GKE cluster."
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "cloud-practice-vpc"
}

variable "subnet_name" {
  description = "Name of the primary subnet."
  type        = string
  default     = "cloud-practice-subnet"
}

variable "subnet_cidr" {
  description = "Primary CIDR block for the subnet."
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_cidr" {
  description = "Secondary CIDR block allocated to GKE pods."
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "Secondary CIDR block allocated to GKE services."
  type        = string
  default     = "10.2.0.0/20"
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
  default     = "cloud-practice-sandbox"
}

variable "node_zones" {
  description = "List of zones in which the node pool will create nodes."
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "node_machine_type" {
  description = "Machine type for GKE worker nodes."
  type        = string
  default     = "e2-small"
}

variable "node_min_count" {
  description = "Minimum number of nodes per zone in the node pool (autoscaling)."
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum number of nodes per zone in the node pool (autoscaling)."
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "Initial number of nodes per zone when the node pool is created."
  type        = number
  default     = 1
}

variable "labels" {
  description = "Labels applied to all resources."
  type        = map(string)
  default = {
    env   = "demo"
    team  = "cloud-practice"
    owner = "marcelo"
  }
}
