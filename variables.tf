
variable "namespace" {
  type        = string
  description = "The namespace where the configureation will be deployed"
}

variable "cluster_config_file" {
  type        = string
  description = "Cluster config file for Kubernetes cluster."
}

variable "cluster_type_code" {
  type        = string
  description = "Cluster type."
  default     = "ocp4"
}

variable "ingress_hostname" {
  type        = string
  description = "The ingress hostname for the cluster."
  default     = ""
}

variable "tls_secret" {
  type        = string
  description = "The name of the tls secret for the ingress."
  default     = ""
}

variable "gitops_dir" {
  type        = string
  description = "Directory where the gitops repo content should be written"
  default     = ""
}

variable "banner_text" {
  type        = string
  description = "Text that should be shown in the banner on the cluster"
  default     = ""
}

variable "banner_background_color" {
  type        = string
  description = "The background color for the banner"
  default     = "purple"
}

variable "banner_text_color" {
  type        = string
  description = "The foreground color for the banner"
  default     = "white"
}
