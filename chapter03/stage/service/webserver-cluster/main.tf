provider "aws" {
    profile = "prod"
}

module "webserver_cluster" {
    source = "../../../modules/services/webserver-cluster"
    
    cluster_name = "webservers-stage"
    db_remote_state_bucket = var.bucket#"terraform-hive-mind"
    db_remote_state_key = "stage/data-store/mysql/terraform.tfstate"
}