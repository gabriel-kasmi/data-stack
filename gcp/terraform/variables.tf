
variable "project_id" {
  type        = string
  default     = "dsaas-437416"
}

variable "region" {
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  type        = string
  default     = "europe-west1-b"
}

variable "postgres_username" {
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  type        = string
  sensitive   = true
}
