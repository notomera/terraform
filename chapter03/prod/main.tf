provider "aws" {
    profile = "prod"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"

    cluster_name = "webservers-prod"
    db_remote_state_bucket = var.bucket#"terraform-hive-mind"
    db_remote_state_key = "prod/data-store/mysql/terraform.tfstate"
}