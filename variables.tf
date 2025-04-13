variable "env" {
  default     = "test"
}

variable "region" {
  default     = "us-east-1"
}

variable "db_name" {
  default     = "corine"
}

variable "keypair_name" {
  default     = "corine"
}

variable "backend_application_port" {
  default     = 3000
}

variable "ticket" {
  description = "The ticket number for the work"
  type        = string
  default     = "123"
}

variable "owner" {
  description = "The username of the person doing the work"
  type        = string
  default     = "corine"
}