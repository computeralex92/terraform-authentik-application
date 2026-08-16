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

output "freeradius_shared_secret" {
  description = "FreeRADIUS shared secret."
  value       = module.freeradius.radius.shared_secret
  sensitive   = true
}

output "wsfed_app_reply_url" {
  description = "WS-Federation app reply URL."
  value       = module.wsfed-app.ws_federation.reply_url
}

output "office365_client_id" {
  description = "Office 365 Microsoft Entra client ID."
  value       = module.office365.microsoft_entra.client_id
}
