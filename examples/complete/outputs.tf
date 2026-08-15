output "applications" {
  description = "Application details from the module."
  value       = module.authentik_apps.applications
  sensitive   = true
}

output "grafana_client_id" {
  description = "Grafana OAuth client ID."
  value       = module.authentik_apps.applications["grafana"].oauth2.client_id
}

output "jenkins_saml_metadata_url" {
  description = "Jenkins SAML metadata URL."
  value       = module.authentik_apps.applications["jenkins"].saml.metadata_url
}
