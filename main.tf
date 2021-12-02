
locals {
  tmp_dir      = "${path.cwd}/.tmp"
  bin_dir      = module.setup_clis.bin_dir
  gitops_dir   = var.gitops_dir != "" ? var.gitops_dir : "${path.cwd}/gitops"
  chart_name   = "cloud-setup"
  chart_dir    = "${path.module}/chart/cloud-setup"
  ibmcloud_release_name = "ibmcloud-config"

  helm_values       = {
    banner = {
      text = var.banner_text
      backgroundColor = var.banner_background_color
      color = var.banner_text_color
    }
  }
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

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["helm"]
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
  provisioner "local-exec" {
    command = "kubectl api-resources -o name | grep -q consolelink && kubectl delete consolelink toolkit-first-app --ignore-not-found"

    environment = {
      KUBECONFIG = var.cluster_config_file
    }
  }
}

resource null_resource cloud_setup_helm {
  depends_on = [null_resource.delete-helm-cloud-config, null_resource.delete-consolelink]

  triggers = {
    namespace = var.namespace
    name = "cloud-setup"
    chart = local.chart_dir
    values_file_content = yamlencode(local.helm_values)
    kubeconfig = var.cluster_config_file
    tmp_dir = local.tmp_dir
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/deploy-helm.sh ${self.triggers.namespace} ${self.triggers.name} ${self.triggers.chart}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
      VALUES_FILE_CONTENT = self.triggers.values_file_content
      TMP_DIR = self.triggers.tmp_dir
      BIN_DIR = self.triggers.bin_dir
    }
  }

  provisioner "local-exec" {
    when = destroy

    command = "${path.module}/scripts/destroy-helm.sh ${self.triggers.namespace} ${self.triggers.name} ${self.triggers.chart}"

    environment = {
      KUBECONFIG = self.triggers.kubeconfig
      VALUES_FILE_CONTENT = self.triggers.values_file_content
      TMP_DIR = self.triggers.tmp_dir
      BIN_DIR = self.triggers.bin_dir
    }
  }
}