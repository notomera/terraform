variable "server_port" {
  description = "This is the webapp port"
  default     = 8081
}

data "aws_vpc" "hive_test" {
  default = true

}

