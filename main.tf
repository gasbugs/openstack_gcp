provider "google" {
  project = "sds-openstack-001" # GCP 프로젝트 ID로 변경하세요
  region  = "us-central1"       # 원하는 리전으로 변경하세요
  zone    = var.zone            # 원하는 존으로 변경하세요
}

resource "google_compute_network" "custom_network" {
  name                    = "custom-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "custom-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.custom_network.id
}

resource "google_compute_network" "custom_network_2" {
  name                    = "custom-network-2"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom_subnet_2" {
  name          = "custom-subnet-2"
  ip_cidr_range = "10.0.100.0/24"
  network       = google_compute_network.custom_network_2.id
}

resource "google_compute_instance" "vm_instance" {
  for_each = {
    controller = ["10.0.0.11", "10.0.100.11"],
    compute1   = ["10.0.0.31", "10.0.100.31"],
    #block1     = ["10.0.0.41"],
    #object1    = ["10.0.0.51"],
    #object2    = ["10.0.0.52"]
  }
  name = each.key
  #machine_type = "custom-4-12288" # 2 vCPU, 8GB 메모리
  machine_type = "n1-standard-4" # 4CPU, 15GB 메모리
  zone         = var.zone

  boot_disk {
    initialize_params {
      # 원하는 OS 이미지 변경 가능z
      # https://console.cloud.google.com/compute/images 사이트 참고
      image = "ubuntu-2404-noble-amd64-v20241219"
      type  = "pd-standard" # HDD
      size  = 100           # 100GB
    }
  }

  # 외부 통신용
  network_interface {
    network = "default"
    access_config {
      # 기본 인터넷 액세스를 위한 설정 (공인 IP 할당)
    }
  }

  # 내부 통신용
  network_interface {
    network    = google_compute_network.custom_network.id
    subnetwork = google_compute_subnetwork.custom_subnet.id
    network_ip = each.value[0]
  }

  # OVN용
  network_interface {
    network    = google_compute_network.custom_network_2.id
    subnetwork = google_compute_subnetwork.custom_subnet_2.id
    network_ip = each.value[1]
  }

  # metadata = {
  #   ssh-keys = "${var.ssh_user}:${file("~/.ssh/id_rsa.pub")}"
  # }

  tags = ["ssh-allow", "allow-internal-net"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # 모든 IP 허용 (필요에 따라 제한하세요)
  target_tags   = ["ssh-allow"]
}

resource "google_compute_firewall" "allow_all_interal_net" {
  name    = "allow-internal-net"
  network = google_compute_network.custom_network.name

  allow {
    protocol = "all"
  }

  source_ranges = ["10.0.0.0/24"] # 모든 IP 허용 (필요에 따라 제한하세요)
  target_tags   = ["allow-internal-net"]
}

variable "zone" {
  default = "us-central1-a"
}

variable "ssh_user" {
  default = "user0" # SSH 사용자 이름
}
