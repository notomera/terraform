variable "cluster_name" {
    description = "The name to use for all of the cluster resrouces"
    type = string
}

variable "db_remote_state_bucket" {
    description = "the name of the s3 bucket for the database's remote state"
    type = string
}

variable "db_remote_state_key" {
    description = "the path for the database's remote state in S3"
    type = string
}
