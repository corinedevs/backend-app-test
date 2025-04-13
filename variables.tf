variable "env" {
  default     = "test"
}

variable "region" {
  default     = "us-east-1"
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