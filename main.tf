provider "google" {
  project = "cloudslab003-tranmoon69" # GCP 프로젝트 ID로 변경하세요
  region  = "us-west1"                # 원하는 리전으로 변경하세요
  zone    = var.zone
}

variable "zone" {
  default = "us-west1-b" # 원하는 존으로 변경하세요
}

locals {
  networks = ["10.4.20.0/24", "192.168.244.0/24"]
}

resource "google_compute_network" "custom_networks" {
  count = length(local.networks)
  name  = "custom-network-${count.index}"
}

resource "random_integer" "id" {
  min = 1
  max = 50000
}

resource "google_compute_subnetwork" "custom_subnets" {
  count         = length(local.networks)
  name          = "custom-subnet-${count.index + random_integer.id.result}"
  ip_cidr_range = local.networks[count.index]
  network       = google_compute_network.custom_networks[count.index].id
}

resource "google_compute_instance" "k8s-cluster" {
  for_each = {
    controller = ["10.4.20.21", "192.168.244.21", true],
    compute1   = ["10.4.20.22", "192.168.244.22", true],
    compute2   = ["10.4.20.23", "192.168.244.23", true]
  }

  name         = each.key
  machine_type = "n2-standard-2" # 2 vCPU, 8GB 메모리
  zone         = var.zone

  boot_disk {
    device_name = "${each.key}-disk"
    initialize_params {
      # 원하는 OS 이미지 변경 가능z
      # https://console.cloud.google.com/compute/images 사이트 참고
      image = "ubuntu-2204-jammy-v20250112"
      type  = "pd-standard" # HDD
      size  = 50            # 50GB
    }
  }

  # VT-x 지원을 위한 고급 설정
  advanced_machine_features {
    enable_nested_virtualization = true
  }

  # management network 
  # 10.4.20.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[0].id
    subnetwork = google_compute_subnetwork.custom_subnets[0].id
    network_ip = each.value[0]

    # 조건문을 사용하여 public IP 할당 여부 결정
    dynamic "access_config" {
      for_each = each.value[2] ? [1] : []
      content {}
    }
  }

  # provider ip 
  # 192.168.100.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[1].id
    subnetwork = google_compute_subnetwork.custom_subnets[1].id
    network_ip = each.value[1]
  }

  allow_stopping_for_update = true

  tags = ["allow-my-ip", "allow-internal-net", "allow-ssh"]
}

/*
# 2일차에 오픈
resource "google_compute_instance" "ceph-cluster" {
  for_each = {
    ceph1 = ["10.4.20.31", true],
    ceph2 = ["10.4.20.32", true],
    ceph3 = ["10.4.20.33", true]
  }

  name         = each.key
  machine_type = "n1-standard-1" # 1vCPU, 3.75GB 메모리
  # machine_type = "e2-standard-2" # 2 vCPU, 4GB 메모리
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


  # Ceph Storage Network
  # 10.4.20.21-24/24
  network_interface {
    network    = google_compute_network.custom_networks[0].id
    subnetwork = google_compute_subnetwork.custom_subnets[0].id
    network_ip = each.value[0]

    # 조건문을 사용하여 public IP 할당 여부 결정
    dynamic "access_config" {
      for_each = each.value[1] ? [1] : []
      content {}
    }
  }

  allow_stopping_for_update = true

  tags = ["allow-my-ip", "allow-internal-net", "allow-ssh"]
}

resource "google_compute_disk" "additional_disk" {
  for_each = {
    ceph1 = "ceph1-additional-disk",
    ceph2 = "ceph2-additional-disk",
    ceph3 = "ceph3-additional-disk"
  }
  name = each.value
  type = "pd-standard"
  zone = var.zone
  size = 100 # 100GB, 필요에 따라 조정
}
*/

resource "google_compute_firewall" "allow_my_ip" {
  name    = "allow-my-ip"
  network = google_compute_network.custom_networks[0].name

  allow {
    protocol = "all"
    #ports    = ["1-65535"]
  }

  source_ranges = ["175.198.0.0/16", "121.143.0.0/16", "14.37.0.0/16", "119.197.0.0/16"] # 모든 IP 허용 (필요에 따라 제한하세요)
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

# variable "ssh_user" {
#   default = "user0" # SSH 사용자 이름
# }
