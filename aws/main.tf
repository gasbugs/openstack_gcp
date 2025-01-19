provider "aws" {
  region  = "us-east-1" # 원하는 AWS 리전으로 변경하세요
  profile = "my-profile"
}

locals {
  networks1 = ["10.4.20.0/24", "10.4.30.0/24", "10.4.40.0/24"]
  networks2 = "192.168.193.0/24"
}

resource "aws_vpc" "custom_vpc_1" {
  cidr_block           = "10.4.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "custom-vpc-1"
  }
}

resource "aws_vpc" "custom_vpc_2" {
  cidr_block           = "192.168.193.0/24"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "custom-vpc-2"
  }
}


resource "aws_subnet" "custom_subnets" {
  count             = length(local.networks1)
  vpc_id            = aws_vpc.custom_vpc_1.id
  cidr_block        = local.networks1[count.index]
  availability_zone = var.availability_zone

  tags = {
    Name = "custom-subnet-${count.index}"
  }
}

resource "aws_subnet" "custom_subnets_192" {
  vpc_id            = aws_vpc.custom_vpc_2.id
  cidr_block        = local.networks2
  availability_zone = var.availability_zone

  tags = {
    Name = "custom-subnet-192"
  }
}

resource "aws_instance" "vm_instances" {
  for_each = {
    kube1 = ["10.4.20.21", "10.4.30.21", "10.4.40.21", "192.168.193.21"],
    kube2 = ["10.4.20.22", "10.4.30.22", "10.4.40.22", "192.168.193.22"],
    kube3 = ["10.4.20.23", "10.4.30.23", "10.4.40.23", "192.168.193.23"]
  }

  ami               = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS AMI ID (us-east-1)
  instance_type     = "t3.xlarge"             # 4 vCPU, 16GB 메모리 (n2-standard-4와 유사)
  availability_zone = var.availability_zone

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp2"
    volume_size = 100
  }

  network_interface {
    network_interface_id = aws_network_interface.nic0[each.key].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.nic1[each.key].id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.nic2[each.key].id
    device_index         = 2
  }

  network_interface {
    network_interface_id = aws_network_interface.nic3[each.key].id
    device_index         = 3
  }

  tags = {
    Name = each.key
  }
}

resource "aws_network_interface" "nic0" {
  for_each        = { kube1 = "10.4.20.21", kube2 = "10.4.20.22", kube3 = "10.4.20.23" }
  subnet_id       = aws_subnet.custom_subnets[0].id
  private_ips     = [each.value]
  security_groups = [aws_security_group.allow_my_ip.id, aws_security_group.allow_internal_net.id, aws_security_group.allow_ssh.id]
}

resource "aws_network_interface" "nic1" {
  for_each    = { kube1 = "10.4.30.21", kube2 = "10.4.30.22", kube3 = "10.4.30.23" }
  subnet_id   = aws_subnet.custom_subnets[1].id
  private_ips = [each.value]
}

resource "aws_network_interface" "nic2" {
  for_each    = { kube1 = "10.4.40.21", kube2 = "10.4.40.22", kube3 = "10.4.40.23" }
  subnet_id   = aws_subnet.custom_subnets[2].id
  private_ips = [each.value]
}

resource "aws_network_interface" "nic3" {
  for_each    = { kube1 = "192.168.193.21", kube2 = "192.168.193.22", kube3 = "192.168.193.23" }
  subnet_id   = aws_subnet.custom_subnets_192.id
  private_ips = [each.value]
}

resource "aws_eip" "public_ip" {
  for_each          = aws_network_interface.nic0
  network_interface = each.value.id
}

resource "aws_security_group" "allow_my_ip" {
  name        = "allow-my-ip"
  description = "Allow inbound traffic from my IP"
  vpc_id      = aws_vpc.custom_vpc_1.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["175.198.213.37/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.custom_vpc_2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_internal_net" {
  name        = "allow-internal-net"
  description = "Allow all internal network traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = local.networks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "availability_zone" {
  default = "us-east-1a"
}
