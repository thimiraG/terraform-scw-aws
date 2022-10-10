

variable "subnet_prefix" {
  description = "subnet cidr block"
  type = map
  default = {
    pub = ["10.0.1.0/24", "10.0.2.0/24"]
    cache = ["10.0.3.0/24", "10.0.4.0/24"]
    prv = ["10.0.5.0/24", "10.0.6.0/24"]}
}

variable "availability_zones" {
    description = "az list"
    type = list
    default = ["eu-north-1a", "eu-north-1b"]
  
}

variable "pri-ip" {
  description = "private ips for bastians"
  type = list
  default = ["10.0.1.20", "10.0.2.20"]
  
}