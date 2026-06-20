variable "ubuntu_image" {
  description = "Шлях до образу Ubuntu"
  type        = string
  default     = "/var/lib/libvirt/images/focal-server-cloudimg-amd64.img"
}

variable "ssh_private_key" {
  description = "Шлях до приватного SSH ключа"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "worker_memory" {
  description = "Пам'ять для worker ВМ (МБ)"
  type        = number
  default     = 2048
}

variable "worker_vcpu" {
  description = "Кількість CPU для worker"
  type        = number
  default     = 2
}

variable "db_memory" {
  description = "Пам'ять для db ВМ (МБ)"
  type        = number
  default     = 2048
}

variable "db_vcpu" {
  description = "Кількість CPU для db"
  type        = number
  default     = 2
}

variable "ansible_user" {
  description = "Користувач Ansible"
  type        = string
  default     = "ansible"
}

variable "ansible_password" {
  description = "Пароль для Ansible користувача"
  type        = string
  sensitive   = true
  default     = "ansible123"
}
