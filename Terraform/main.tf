terraform {
  required_providers {
    yandex = {
        source = "yandex-cloud/yandex"
        version = ">=0.120"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
    service_account_key_file = "./authorized_key.json"
    cloud_id = var.cloud-id
    folder_id = var.folder-id
    zone = var.zone
  
}
data "yandex_vpc_network" "network" {
  name = "main-network"
  
}

resource "yandex_vpc_subnet" "subnet" {
  name = "project-subnet"
  v4_cidr_blocks = ["10.6.0.0/24"]
  network_id = data.yandex_vpc_network.network.id
}

resource "yandex_iam_service_account" "account" {
  name = "service-account-for-project"
  folder_id = var.folder-id
}

resource "yandex_resourcemanager_folder_iam_member" "puller" {
  folder_id = var.folder-id
  role = "container-registry.images.puller"
  member = "serviceAccount:${yandex_iam_service_account.account.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "pusher" {
  folder_id = var.folder-id
  role = "container-registry.images.pusher"
  member = "serviceAccount:${yandex_iam_service_account.account.id}"
}

resource "yandex_compute_disk" "disk" {
  name = "disk_for_project"
  size = 10
  image_id = "fd8790f3mldktbkmf1ot"
  zone = var.zone
}

resource "yandex_compute_instance" "vm" {
  name = "vm-for-project"
  zone = var.zone
  platform_id = "standard-v1"
  service_account_id = yandex_iam_service_account.account.id
  resources {
    cores = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8790f3mldktbkmf1ot"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }
 metadata = {
    ssh-keys = "kita:${file("~/.ssh/id_ed25519.pub")}"
    foo = "bar"
  }
}

output "external_ip" {
  value = yandex_compute_instance.vm.network_interface.0.nat_ip_address
  
}

output "acccount" {
  value = yandex_iam_service_account.account.id
  
}
