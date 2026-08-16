output "vault_client_id" {
  description = "Vault OAuth client ID."
  value       = module.vault.oauth2.client_id
}

output "vault_client_secret" {
  description = "Vault OAuth client secret."
  value       = module.vault.oauth2.client_secret
  sensitive   = true
}

output "keycloak_metadata_url" {
  description = "Keycloak SAML metadata URL."
  value       = module.keycloak.saml.metadata_url
}

output "keycloak_scim_token" {
  description = "Keycloak SCIM token."
  value       = module.keycloak.scim.token
  sensitive   = true
}

output "traefik_client_id" {
  description = "Traefik proxy client ID."
  value       = module.traefik.proxy.client_id
}

output "freeradius_shared_secret" {
  description = "FreeRADIUS shared secret."
  value       = module.freeradius.radius.shared_secret
  sensitive   = true
}

output "office365_client_id" {
  description = "Office 365 Microsoft Entra client ID."
  value       = module.office365.microsoft_entra.client_id
}

output "gws_default_group_email_domain" {
  description = "Google Workspace default group email domain."
  value       = module.gws.google_workspace.default_group_email_domain
}

output "rac_endpoints" {
  description = "RAC endpoint names."
  value       = module.rac_app.rac.endpoints
}

output "ssf_provider_id" {
  description = "SSF provider ID."
  value       = module.ssf_app.ssf.provider_id
}
