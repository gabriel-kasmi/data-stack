
variable "region" {
  type        = string
  default     = "eu-west-1"
}

variable "zone" {
  type        = string
  default     = "eu-west-1b"
}

variable "zone_bis" {
  type        = string
  default     = "eu-west-1a"
}

variable "zone_ter" {
  type        = string
  default     = "eu-west-1c"
}

variable "redshift_username" {
  type        = string
  sensitive   = true
}

variable "redshift_password" {
  type        = string
  sensitive   = true
}

variable "postgres_username" {
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  type        = string
  sensitive   = true
}
