#Instance Type
variable "type" {
  default = {
    "dev" = "t2.micro"
  }
  type        = map(string)
  description = "Instances Type"
}


# Variable to signal the current environment 
variable "env" {
  default     = "dev"
  type        = string
  description = "environment"
}