variable "project" {
  description = "Tüm kaynaklara project etiketi olarak yazılır; bootstrap'teki project ile aynı olmalı."
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,30}$", var.project))
    error_message = "project küçük harf, rakam ve tire içermeli, 3-30 karakter."
  }
}

variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "instance_type" {
  description = "Free plan kapsamındaki küçük bir tip; t3.micro çoğu region'da var."
  type        = string
  default     = "t3.micro"
}
