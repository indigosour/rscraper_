variable "environment_name" {
  type = string
}

variable "storage_account_name" {
    type = string
}

variable "storage_account_rg" {
    type = string
}

variable "storage_account_share_name" {
    type = string
}

variable "location" {
    type = string
}

variable "key_vault_id" {
    type = string
}

variable "rscraper_conductor_image" {
    type = string
}

variable "rscraper_worker_image" {
    type = string
}