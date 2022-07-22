resource "google_compute_region_ssl_certificate" "default" {
  project     = var.project
  region      = var.region
  name        = "jenkin-cert"
  description = "a description"
  private_key = file("key.pem")
  certificate = file("certificate.pem")

  lifecycle {
    create_before_destroy = true
  }
}
