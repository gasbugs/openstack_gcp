provider "google" {
  project = "sds-openstack-001" # GCP 프로젝트 ID로 변경하세요
  region  = "us-central1"       # 원하는 리전으로 변경하세요
  zone    = var.zone            # 원하는 존으로 변경하세요
}

locals {
  networks = ["10.4.20.0/24", "10.4.30.0/24", "10.4.40.0/24", "192.168.193.0/24"]
}

resource "google_compute_network" "custom_networks" {
  count = length(local.networks)
  name  = "custom-network-${count.index}"
}

resource "google_compute_subnetwork" "custom_subnets" {
  count         = length(local.networks)
  name          = "custom-subnet-${count.index}"
  ip_cidr_range = local.networks[count.index]
  network       = google_compute_network.custom_networks[count.index].id
}

resource "google_compute_instance" "vm_instances" {
  for_each = {
    kube1 = ["10.4.20.21", "10.4.30.21", "10.4.40.21", "192.168.193.21"],
    kube2 = ["10.4.20.22", "10.4.30.22", "10.4.40.22", "192.168.193.22"],
    kube3 = ["10.4.20.23", "10.4.30.23", "10.4.40.23", "192.168.193.23"]
  }

  name         = each.key
  machine_type = "n2-standard-4" # 4 vCPU, 12288GB 메모리
  zone         = var.zone

  boot_disk {
    device_name = "${each.key}-disk"
    initialize_params {
      # 원하는 OS 이미지 변경 가능z
      # https://console.cloud.google.com/compute/images 사이트 참고
      image = "ubuntu-2404-noble-amd64-v20241219"
      type  = "pd-standard" # HDD
      size  = 50            # 50GB
    }
  }

  attached_disk {
    source      = google_compute_disk.additional_disk[each.key].self_link
    device_name = "${each.key}-additional-disk" # 100GB 디스크 추가 
  }

  # VT-x 지원을 위한 고급 설정
  advanced_machine_features {
    enable_nested_virtualization = true

  }


  # Ceph Storage Public (공인 IP 부여)
  # 10.4.20.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[0].id
    subnetwork = google_compute_subnetwork.custom_subnets[0].id
    network_ip = each.value[0]
    access_config {
      # 기본 인터넷 액세스를 위한 설정 (공인 IP 할당)
    }
  }

  # Ceph Storage Replication
  # 10.4.30.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[1].id
    subnetwork = google_compute_subnetwork.custom_subnets[1].id
    network_ip = each.value[1]
  }

  # Openstack Tanent Network
  # 10.4.40.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[2].id
    subnetwork = google_compute_subnetwork.custom_subnets[2].id
    network_ip = each.value[2]
  }

  # Openstack External Network: Provider Network
  # 192.168.193.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[3].id
    subnetwork = google_compute_subnetwork.custom_subnets[3].id
    network_ip = each.value[3]
  }

  allow_stopping_for_update = true

  tags = ["allow-my-ip", "allow-internal-net", "allow-ssh"]
}

resource "google_compute_disk" "additional_disk" {
  for_each = {
    kube1 = "ceph1-additional-disk",
    kube2 = "ceph2-additional-disk",
    kube3 = "ceph3-additional-disk"
  }
  name = each.value
  type = "pd-standard"
  zone = var.zone
  size = 100 # 100GB, 필요에 따라 조정
}



resource "google_compute_firewall" "allow_my_ip" {
  name    = "allow-my-ip"
  network = google_compute_network.custom_networks[0].name

  allow {
    protocol = "all"
    #ports    = ["1-65535"]
  }

  source_ranges = ["175.198.213.37/32"] # 모든 IP 허용 (필요에 따라 제한하세요)
  target_tags   = ["allow-my-ip"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "my-allow-ssh"
  network = google_compute_network.custom_networks[0].name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # 모든 IP 허용 (필요에 따라 제한하세요)
  target_tags   = ["allow-ssh"]
}

resource "google_compute_firewall" "allow_all_interal_net" {
  count = length(local.networks)

  name    = "allow-internal-net-${count.index}"
  network = google_compute_network.custom_networks[count.index].id

  allow {
    protocol = "all"
  }

  source_ranges = local.networks # 모든 내부 IP 허용 
  target_tags   = ["allow-internal-net"]
}

variable "zone" {
  default = "us-central1-a"
}

# variable "ssh_user" {
#   default = "user0" # SSH 사용자 이름
# }
