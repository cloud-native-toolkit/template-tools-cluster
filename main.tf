
locals {
  tmp_dir      = "${path.cwd}/.tmp"
  gitops_dir   = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name   = "cloud-setup"
  chart_dir    = "${path.module}/chart/cloud-setup"
  ibmcloud_release_name = "ibmcloud-config"
}

resource null_resource create_dirs {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "mkdir -p ${local.tmp_dir}"
  }

  provisioner "local-exec" {
    command = "echo 'KUBECONFIG=${var.cluster_config_file}'"
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
    command = "kubectl api-resources -o name | grep -q consolelink && kubectl delete consolelink toolkit-cntk-dev-guide --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource "helm_release" "cloud_setup" {
  depends_on = [null_resource.delete-helm-cloud-config, null_resource.delete-consolelink]

  name              = "cloud-setup"
  chart             = local.chart_dir
  namespace         = var.namespace
  timeout           = 1200
  dependency_update = true
  force_update      = true
  replace           = true

  disable_openapi_validation = true
}
