variable "project" {
  default = ""  # Need to change based on requirement
}

variable "config-path" {
  default = "~/.kube/config"    # Provide config file path  
}

variable "config_context" {
  default = "local"         # Provide config context
}

variable "region" {
  default = "us-west1"
}

## Outputs
output "A_Jenkins-Ingress-IP" {
  value = "kubectl get ing jenkins -n jenkins"
}

output "B_Map-Ingress-IP-in-DNS" {
  value = "jenkins.hackwithv.com -> x.x.x.x"
}

output "C_Jenkins-UI" {
  value = "https://jenkins.hackwithv.com"
}

output "D_Username" {
  value = "admin"
}
output "E_password" {
  value = "kubectl get secret --namespace jenkins jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode && echo"
}