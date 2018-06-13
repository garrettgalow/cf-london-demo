provider "kubernetes"{
   host = "${azurerm_kubernetes_cluster.k8s.kube_config.0.host}"
   username = "${azurerm_kubernetes_cluster.k8s.kube_config.0.username}"
   password = "${azurerm_kubernetes_cluster.k8s.kube_config.0.password}"
   cluster_ca_certificate = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.cluster_ca_certificate)}"
   client_certificate = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_certificate)}"
   client_key = "${base64decode(azurerm_kubernetes_cluster.k8s.kube_config.0.client_key)}"
}

output "aks_lb_ip" {
   value = "${kubernetes_service.expose_mm.load_balancer_ingress.0.ip}"
}

resource "kubernetes_service" "expose_mm" {
   metadata {
      name = "mattermost"
      namespace = "default"
   }
   spec {
      type = "LoadBalancer"
      port {
         port = 80
         target_port = 80
         protocol = "TCP"
         name = "http"
      }
      selector {
         app = "mattermost"
         tier = "app"
      }
   } 
}

resource "kubernetes_pod" "mm_pod" {
   metadata {
      name = "mattermost-app"
      labels {
         app = "mattermost"
         tier = "app"
      }
   }

   spec {
      container {
	 name = "mattermost-app"
	 image = "mattermost/mattermost-prod-app:4.7.0"
	 env {
	    name = "DB_HOST"
	    value_from {
	       secret_key_ref {
		    name = "mattermost-env"
		    key = "db-host"
		}
	    }
	}
	env {
	    name = "DB_PORT"
	    value_from {
	       secret_key_ref {
		  name = "mattermost-env"
		  key = "db-port"
	       }
	    }
	}
	env {
	    name = "MM_USERNAME"
	    value_from {
	       secret_key_ref {
		  name = "mattermost-env"
		  key = "mm-username"
	       }
	    }
	}
	env {
	    name = "MM_PASSWORD"
	    value_from {
	       secret_key_ref {
		  name = "mattermost-env"
		  key = "mm-password"
	       }
	    }
	}
	env {
	    name = "MM_DBNAME"
	    value_from {
		  secret_key_ref {
		     name = "mattermost-env"
		     key = "mm-dbname"
		  }
	    } 
	 }
	 volume_mount {
	    name = "etclocaltime"
	    mount_path = "/etc/localtime"
	    read_only = "true"
	 }
      }
      volume {
	 name = "etclocaltime"
	 host_path {
	    path = "/etc/localtime"
	 }
      }
      dns_policy = "ClusterFirst"
   }
}

resource "kubernetes_secret" "db_conn" {
   metadata {
      name = "mattermost-env"
      namespace = "default"
   }

   type = "Opaque"

   data {
      "db-host" = "35.230.114.138"
      "db-port" = "80"
      "mm-username" = "mmuser"
      "mm-password" = "mmuser_password"
      "mm-dbname" = "mattermost"
   }
}
