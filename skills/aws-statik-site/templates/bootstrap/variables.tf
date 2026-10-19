variable "project" {
  description = "Tüm kaynaklara project etiketi olarak yazılır; site katmanındakiyle aynı olmalı."
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

variable "github_repo" {
  description = "Deploy edecek repo, sahip/ad biçiminde (örn. ornek-kullanici/sitem)."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo sahip/ad biçiminde olmalı."
  }
}

variable "create_oidc_provider" {
  description = "Hesapta GitHub OIDC provider zaten varsa false (hesap başına bir tane olabilir)."
  type        = bool
  default     = true
}
