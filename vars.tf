variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "AWS_REGION" {
  default = "ap-southeast-3"
}
variable "AMIS" {
  type = map(string)
  default = {
    ap-southeast-3 = "ami-029497464bf11fc26"
    ap-southeast-1 = "ami-0fbb51b4aa5671449"
    eu-west-1 = "ami-064562725417500be"
  }
}

variable "PATH_TO_PRIVATE_KEY" {
  default = "terraform-key"
}

variable "PATH_TO_PUBLIC_KEY" {
  default = "terraform-key.pub"
}

variable "INSTANCE_USERNAME" {
  default = "ubuntu"
}

variable "availability_zone" {
  default = "ap-southeast-3b"  
}

