output "address" {
  value       = aws_db_instance.example.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = aws_db_instance.example.port
  description = "The port the database is listening on"
}


// -> there is commented code at the end of the page



// Code testing the output of data module
# output "aws_db_credentials" {
#     value = local.credentials["db_username"]
#     sensitive = true
# }
# output "db_username" {
#     value = jsondecode(data.aws_secretsmanager_secret_version.credential.secret_string)["db_username"]
#     sensitive = true
# }