# # Cloud Router 생성
# resource "google_compute_router" "router" {
#   name    = "nat-router"
#   network = google_compute_network.custom_networks[0].name
# }

# # Cloud NAT 게이트웨이 생성
# resource "google_compute_router_nat" "nat" {
#   name                               = "nat-gateway"
#   router                             = google_compute_router.router.name
#   region                             = google_compute_router.router.region
#   nat_ip_allocate_option             = "AUTO_ONLY"
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

#   log_config {
#     enable = true
#     filter = "ERRORS_ONLY"
#   }
# }

# # 필요한 방화벽 규칙 설정 (예시)
# resource "google_compute_firewall" "allow_internal" {
#   name    = "allow-internal"
#   network = google_compute_network.custom_networks[0].name

#   allow {
#     protocol = "tcp"
#     ports    = ["0-65535"]
#   }

#   allow {
#     protocol = "udp"
#     ports    = ["0-65535"]
#   }

#   allow {
#     protocol = "icmp"
#   }

#   source_ranges = ["10.4.20.0/24"]
# }

# resource "google_compute_subnetwork" "custom_subnets" {
#   count         = length(local.networks)
#   name          = "custom-subnet-${count.index + random_integer.id.result}"
#   ip_cidr_range = local.networks[count.index]
#   network       = google_compute_network.custom_networks[count.index].id
# }
