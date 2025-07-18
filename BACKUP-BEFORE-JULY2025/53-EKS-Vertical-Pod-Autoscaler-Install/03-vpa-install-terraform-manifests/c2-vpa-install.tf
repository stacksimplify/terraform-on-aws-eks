# 1. Key Requirement-1: Install OpenSSL in local terminal whose version is 1.1.1 or higher 
# 2. Key Requirement-2: Configure kubeconfig for kubectl in your local terminal

# Resource-1: Null Resource: Clone GitHub Repository
resource "null_resource" "git_clone" {
  provisioner "local-exec" {
    command = "git clone git@github.com:kubernetes/autoscaler.git"
  }
}


# # Resource-2: Null Resource: Install Vertical Pod Autoscaler
resource "null_resource" "install_vpa" {
  depends_on = [null_resource.git_clone]
 provisioner "local-exec" { 
    command = "${path.module}/autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh"
  }
}

# Resource-3: Null Resource: Remove autoscaler folder
resource "null_resource" "remove_git_clone_autoscaler_folder" {
 provisioner "local-exec" { 
    command = "rm -rf  ${path.module}/autoscaler"
    when = destroy
  }
}


# Resource-4: Null Resource: Uninstall Vertical Pod Autoscaler
resource "null_resource" "uninstall_vpa" {
  depends_on = [null_resource.remove_git_clone_autoscaler_folder]
 provisioner "local-exec" { 
    command = "${path.module}/autoscaler/vertical-pod-autoscaler/hack/vpa-down.sh"
    when = destroy
  }
}

