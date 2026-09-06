resource "kubernetes_service" "example_service" {
  metadata {
    name = "example-service"
  }

  spec {
    selector = {
      test = "MyExampleApp"
    }

    port {
      protocol = "TCP"
      port     = 80
      target_port = 80
    }
  }
}