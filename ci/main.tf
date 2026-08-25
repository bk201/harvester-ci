terraform {
  required_version = ">= 0.13"
  required_providers {
    harvester = {
      source  = "harvester/harvester"
      version = "1.9.0-rc6"
    }
  }
}

provider "harvester" {
  kubeconfig = "${path.module}/kubeconfig"
}

locals {
  config = yamldecode(file("./config.yaml"))

  pubkey = file("./${local.config.ssh_pubkey_name}.pub")
}

data "harvester_network" "existing" {
  name      = local.config.network_name
  namespace = local.config.namespace
}

resource "harvester_image" "vm_image" {
  name      = local.config.image_name
  namespace = local.config.namespace

  display_name = local.config.image_name
  source_type  = "download"
  url          = local.config.image_url
}

resource "harvester_ssh_key" "mysshkey" {
  name      = local.config.ssh_pubkey_name
  namespace = local.config.namespace

  public_key = local.pubkey
}

resource "harvester_virtualmachine" "ci-vm" {
  count                = local.config.vm_count
  name                 = "${local.config.vm_name}-${count.index}"
  namespace            = local.config.namespace
  restart_after_update = true

  description = "ci vm ${count.index}"
  tags = {
    ssh-user = "opensuse"
  }

  cpu    = local.config.vm_cpu
  memory = "${local.config.vm_memory_in_gib}Gi"

  efi         = true
  secure_boot = true

  run_strategy = "RerunOnFailure"
  hostname     = "${local.config.vm_name}-${count.index}"
  machine_type = "q35"

  network_interface {
    name         = "nic-1"
    network_name = data.harvester_network.existing.id

    wait_for_lease = true
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = "${local.config.vm_disk_size}Gi"
    bus        = "virtio"
    boot_order = 1

    image       = harvester_image.vm_image.id
    auto_delete = true
  }

  #  disk {
  #    name        = "emptydisk"
  #    type        = "disk"
  #    size        = "20Gi"
  #    bus         = "virtio"
  #    auto_delete = true
  #  }

  cloudinit {
    user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      pubkey  = local.pubkey
      vm_user = local.config.vm_user_name
      vm_password = local.config.vm_password
    })
    network_data = ""
  }
}

output "vm_ip_addresses" {
  value = harvester_virtualmachine.ci-vm[*].network_interface[0].ip_address
}