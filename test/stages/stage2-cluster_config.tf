module "cluster_config" {
  source = "./module"

  namespace           = module.dev_capture_state.namespace
  cluster_config_file = module.dev_cluster.config_file_path
  cluster_type_code   = module.dev_cluster.platform.type_code
  ingress_hostname    = module.dev_cluster.platform.ingress
  tls_secret          = module.dev_cluster.platform.tls_secret
}
