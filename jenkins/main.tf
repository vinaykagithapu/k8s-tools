## Provider

provider "kubernetes" {
  config_path    = var.config-path
  config_context = var.config_context
}

provider "helm" {
  kubernetes {
    config_path = var.config-path
  }
}