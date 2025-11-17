variable "azure_rg_name" {
  type        = string
  description = "Nazwa resource groupy"
  default     = "itlab"
}

variable "azure_location" {
  type        = string
  description = "Nazwa regionu"
  default     = "northeurope"
}

variable "ssh_pub_key" {
  type        = string
  description = "Publiczny klucz SSH do logowania się na VM"
  default     = "ssh-ed25519 XXXXXXX"
}

variable "vm_user_name" {
  type        = string
  description = "Username dla administratora"
  default     = "itlabadmin"
}
