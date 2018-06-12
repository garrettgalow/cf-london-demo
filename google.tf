provider "google" {
   credentials = "${file(".secrets/gcp_creds.json")}"
   project = "london-customer-day"
   region = "us-central1"
}

resource "google_container_cluster" "primary" {
   name = "mm-demo"
   zone = "us-central1-a"
   initial_node_count = 2
}
