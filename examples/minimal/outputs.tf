output "application_id" {
  description = "ID of the created application."
  value       = module.minimal.application_id
}

output "client_id" {
  description = "OAuth2 client ID."
  value       = module.minimal.oauth2.client_id
}
