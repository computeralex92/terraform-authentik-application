output "grafana_client_id" {
  description = "Grafana OAuth client ID."
  value       = module.grafana.oauth2.client_id
}

output "grafana_client_secret" {
  description = "Grafana OAuth client secret."
  value       = module.grafana.oauth2.client_secret
  sensitive   = true
}

output "jenkins_saml_metadata_url" {
  description = "Jenkins SAML metadata URL."
  value       = module.jenkins.saml.metadata_url
}

output "jenkins_scim_token" {
  description = "Jenkins SCIM token."
  value       = module.jenkins.scim.token
  sensitive   = true
}
