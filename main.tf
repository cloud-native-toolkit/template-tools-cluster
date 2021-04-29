
locals {
  tmp_dir      = "${path.cwd}/.tmp"
  gitops_dir   = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name   = "cloud-setup"
  chart_dir    = "${local.gitops_dir}/${local.chart_name}"
  ibmcloud_release_name = "ibmcloud-config"
  global_config = {
    clusterType = var.cluster_type_code
    ingressSubdomain = var.ingress_hostname
    tlsSecretName = var.tls_secret
  }
  ibmcloud_config = {
    ingress_subdomain = var.ingress_hostname
    tls_secret_name = var.tls_secret
  }
  cntk_dev_guide_config = {
    name = "cntk-dev-guide"
    displayName = "Cloud-Native Toolkit"
    url = "https://cloudnativetoolkit.dev"
  }
  first_app_config = {
    name = "first-app"
    displayName = "Deploy first app"
    url = "https://cloudnativetoolkit.dev/getting-started-day-1/deploy-app/"
  }
}

resource null_resource create_dirs {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }
}

resource "null_resource" "list_tmp" {
  depends_on = [null_resource.create_dirs]

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "ls ${local.tmp_dir}"
  }
}

resource null_resource setup-chart {
  provisioner "local-exec" {
    command = "mkdir -p ${local.chart_dir} && cp -R ${path.module}/chart/${local.chart_name}/* ${local.chart_dir}"
  }
}

resource null_resource delete-helm-cloud-config {

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${var.namespace} -l name=${local.ibmcloud_release_name} --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${var.namespace} -l name=cloud-setup --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${var.namespace} ibmcloud-apikey --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${var.namespace} ibmcloud-config --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete secret -n ${var.namespace} cloud-access --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }

  provisioner "local-exec" {
    command = "kubectl delete configmap -n ${var.namespace} cloud-config --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "null_resource" "delete-consolelink" {

  provisioner "local-exec" {
    command = "kubectl api-resources -o name | grep -q consolelink && kubectl delete consolelink toolkit-github --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }

  provisioner "local-exec" {
    command = "kubectl api-resources -o name | grep -q consolelink && kubectl delete consolelink toolkit-registry --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "local_file" "cloud-values" {
  depends_on = [null_resource.setup-chart]

  content  = yamlencode({
    global = local.global_config
    cloud-setup = {
      ibmcloud = local.ibmcloud_config
      cntk-dev-guide = local.cntk_dev_guide_config
      first-app = local.first_app_config
    }
  })
  filename = "${local.chart_dir}/values.yaml"
}

resource "null_resource" "print-values" {
  provisioner "local-exec" {
    command = "cat ${local_file.cloud-values.filename}"
  }
}

resource "helm_release" "cloud_setup" {
  depends_on = [null_resource.delete-helm-cloud-config, null_resource.delete-consolelink, local_file.cloud-values]

  name              = "cloud-setup"
  chart             = local.chart_dir
  version           = "0.1.0"
  namespace         = var.namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
