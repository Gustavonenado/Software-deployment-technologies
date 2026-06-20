output "worker_ip" {
  description = "IP адреса worker ВМ"
  value       = libvirt_domain.worker.network_interface[0].addresses[0]
}

output "db_ip" {
  description = "IP адреса db ВМ"
  value       = libvirt_domain.db.network_interface[0].addresses[0]
}

output "ssh_command_worker" {
  description = "SSH команда для підключення до worker"
  value       = "ssh -i ${var.ssh_private_key} ubuntu@${libvirt_domain.worker.network_interface[0].addresses[0]}"
}

output "ssh_command_db" {
  description = "SSH команда для підключення до db"
  value       = "ssh -i ${var.ssh_private_key} ubuntu@${libvirt_domain.db.network_interface[0].addresses[0]}"
}

output "ansible_ready" {
  description = "Команда для запуску Ansible"
  value       = "cd ../ansible && ansible-playbook -i inventory/hosts.ini playbook.yml"
}
