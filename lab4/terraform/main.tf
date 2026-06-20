terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Мережа для ВМ
resource "libvirt_network" "mynet" {
  name      = "mynet"
  mode      = "nat"
  domain    = "local.lab"
  addresses = ["192.168.122.0/24"]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
  }
}

# Volume з образом для worker
resource "libvirt_volume" "worker_volume" {
  name             = "worker_volume"
  pool             = "default"
  source           = var.ubuntu_image
  format           = "qcow2"
}

# Volume з образом для db
resource "libvirt_volume" "db_volume" {
  name             = "db_volume"
  pool             = "default"
  source           = var.ubuntu_image
  format           = "qcow2"
}

# Cloud-init для worker
resource "libvirt_cloudinit_disk" "worker_init" {
  name           = "worker_init.iso"
  pool           = "default"
  user_data      = file("${path.module}/cloud-init/worker.yml")
  network_config = file("${path.module}/cloud-init/network.yml")
}

# Cloud-init для db
resource "libvirt_cloudinit_disk" "db_init" {
  name           = "db_init.iso"
  pool           = "default"
  user_data      = file("${path.module}/cloud-init/db.yml")
  network_config = file("${path.module}/cloud-init/network.yml")
}

# Worker ВМ
resource "libvirt_domain" "worker" {
  name       = "worker"
  memory     = var.worker_memory
  vcpu       = var.worker_vcpu
  autostart  = true

  boot_device {
    dev = ["hd"]
  }

  disk {
    volume_id = libvirt_volume.worker_volume.id
  }

  cloudinit = libvirt_cloudinit_disk.worker_init.id

  network_interface {
    network_id = libvirt_network.mynet.id
    wait_for_lease = true
  }

  # Очікувати запуск системи
  provisioner "remote-exec" {
    inline = ["echo 'System ready'"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.network_interface[0].addresses[0]
      timeout     = "5m"
    }
  }
}

# DB ВМ
resource "libvirt_domain" "db" {
  name       = "db"
  memory     = var.db_memory
  vcpu       = var.db_vcpu
  autostart  = true
  depends_on = [libvirt_domain.worker]

  boot_device {
    dev = ["hd"]
  }

  disk {
    volume_id = libvirt_volume.db_volume.id
  }

  cloudinit = libvirt_cloudinit_disk.db_init.id

  network_interface {
    network_id = libvirt_network.mynet.id
    wait_for_lease = true
  }

  # Очікувати запуск системи
  provisioner "remote-exec" {
    inline = ["echo 'System ready'"]
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.network_interface[0].addresses[0]
      timeout     = "5m"
    }
  }
}

# Сохранити IP адреси для Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    worker_ip = libvirt_domain.worker.network_interface[0].addresses[0]
    db_ip     = libvirt_domain.db.network_interface[0].addresses[0]
  })
  
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  
  depends_on = [libvirt_domain.worker, libvirt_domain.db]
}
