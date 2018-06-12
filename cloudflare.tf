provider "cloudflare" {
   org_id = "a67e14daa5f8dceeb91fe5449ba496eb"
}

module gcp {
   source = "./gke"
}

module aks {
   source = "./aks"
   client_id = "${var.client_id}"
   client_secret = "${var.client_secret}"
}

#module eks {
#   source = "./eks"
#}

variable "zone" {
   default = "cloudflare.london"
}

resource "cloudflare_record" "aks_ip" {
   domain = "${var.zone}"
   name = "aks"
   value = "${module.aks.aks_lb_ip}"
   type = "A"
   ttl = 1
   proxied = true
}

resource "cloudflare_record" "gke_ip" {
   domain = "${var.zone}"
   name = "gke"
   value = "${module.gcp.gcp_lb_ip}"
   type = "A"
   ttl = 1
   proxied = true
}

resource "cloudflare_load_balancer_monitor" "gke_monitor" {
   method = "GET"
   expected_body = "OK"
   expected_codes = "2xx"
   path = "/api/v4/system/ping"
   timeout = 5
   interval = 30
   retries = 1
   description = "GKE Monitor"
}

resource "cloudflare_load_balancer_monitor" "aks_monitor" {
   method = "GET"
   expected_body = "OK"
   expected_codes = "2xx"
   path = "/api/v4/system/ping"
   timeout = 5
   interval = 30
   retries = 1
   description = "AKS Monitor"
}

resource "cloudflare_load_balancer_pool" "aks_pool" {
   name = "aks-pool"
   origins {
      name = "aks"
      address = "${module.aks.aks_lb_ip}"
      enabled = true
   }
   description = "Azure Kubernetes Origin"
   enabled = true
   minimum_origins = 1
   notification_email = "gg@cloudflare.com"
   monitor = "${cloudflare_load_balancer_monitor.aks_monitor.id}"
}

resource "cloudflare_load_balancer_pool" "gke_pool" {
   name = "gke-pool"
   origins {
      name = "gke"
      address = "${module.gcp.gcp_lb_ip}"
      enabled = true
   }
   description = "Google Kubernetes Origin"
   enabled = true
   minimum_origins = 1
   notification_email = "gg@cloudflare.com"
   monitor = "${cloudflare_load_balancer_monitor.gke_monitor.id}"
}

resource "cloudflare_load_balancer" "chat_demo" {
   zone = "cloudflare.london"
   name = "chat.cloudflare.london"
   fallback_pool_id = "${cloudflare_load_balancer_pool.aks_pool.id}"
   default_pool_ids = ["${cloudflare_load_balancer_pool.aks_pool.id}","${cloudflare_load_balancer_pool.gke_pool.id}"]
   description = "Load Balancer for MatterMost Chat"
   proxied = true
   region_pools {
      region = "WEU"
      pool_ids = ["${cloudflare_load_balancer_pool.gke_pool.id}"]
   }
}
