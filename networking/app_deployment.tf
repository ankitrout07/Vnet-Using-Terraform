# app_deployment.tf - Fully automates the application build and deployment

# 1. Docker Build and Push
resource "docker_image" "dashboard" {
  name = "${module.acr.login_server}/fortress-dashboard:${random_id.suffix.hex}"
  build {
    context    = "../dashboard"
    dockerfile = "Dockerfile"
  }
}

resource "docker_registry_image" "dashboard" {
  name          = docker_image.dashboard.name
  keep_remotely = true
}

# 2. Kubernetes Resources
resource "kubernetes_service_account" "dashboard_sa" {
  metadata {
    name      = "fortress-dashboard-sa"
    namespace = "default"
  }
}

resource "kubernetes_cluster_role" "dashboard_role" {
  metadata {
    name = "fortress-dashboard-role"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes", "pods", "namespaces", "events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "dashboard_rolebinding" {
  metadata {
    name = "fortress-dashboard-rolebinding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.dashboard_role.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.dashboard_sa.metadata[0].name
    namespace = "default"
  }
}

resource "kubernetes_deployment" "fortress_web" {
  metadata {
    name      = "fortress-web"
    namespace = "default"
  }

  depends_on = [
    azurerm_role_assignment.aks_acr_pull
  ]

  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "fortress"
      }
    }

    template {
      metadata {
        labels = {
          app = "fortress"
        }
      }

      spec {
        service_account_name = kubernetes_service_account.dashboard_sa.metadata[0].name
        container {
          name  = "fortress-dashboard"
          image = docker_registry_image.dashboard.name

          port {
            container_port = 80
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          env {
            name  = "DB_HOST"
            value = module.database.db_server_fqdn
          }
          env {
            name  = "REDIS_HOST"
            value = module.redis.redis_hostname
          }
          env {
            name  = "REDIS_KEY"
            value = module.redis.redis_primary_access_key
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 80
            }
            initial_delay_seconds = 15
            period_seconds        = 20
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "fortress_service" {
  metadata {
    name      = "fortress-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "fortress"
    }

    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "fortress_ingress" {
  metadata {
    name      = "fortress-ingress"
    namespace = "default"
    annotations = {
      "appgw.ingress.kubernetes.io/backend-path-prefix"   = "/"
      "appgw.ingress.kubernetes.io/health-probe-path"     = "/health"
      "appgw.ingress.kubernetes.io/success-codes"         = "200-399"
      "appgw.ingress.kubernetes.io/use-private-ip"        = "false"
    }
  }

  spec {
    ingress_class_name = "azure-application-gateway"

    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.fortress_service.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  # Ensure Backend sync happens AFTER these role assignments take effect
  depends_on = [
    azurerm_role_assignment.agic_rg_contributor,
    azurerm_role_assignment.agic_appgw_contributor,
    azurerm_role_assignment.agic_vnet_contributor
  ]
}
