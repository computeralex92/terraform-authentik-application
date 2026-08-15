output "application_id" {
  description = "ID of the created Authentik application."
  value       = authentik_application.this.id
}

output "provider_id" {
  description = "ID of the created OAuth2 or SAML provider."
  value       = var.protocol == "oauth2" ? authentik_provider_oauth2.this[0].id : authentik_provider_saml.this[0].id
}

output "oauth2" {
  description = "OAuth2 client details. `null` when `protocol` is not `oauth2`. Sensitive because it includes the client secret."
  sensitive   = true
  value = var.protocol == "oauth2" ? {
    client_id     = authentik_provider_oauth2.this[0].client_id
    client_secret = authentik_provider_oauth2.this[0].client_secret
  } : null
}

output "saml" {
  description = "SAML provider endpoints. `null` when `protocol` is not `saml`."
  value = var.protocol == "saml" ? {
    sso_url_redirect = authentik_provider_saml.this[0].url_sso_redirect
    sso_url_post     = authentik_provider_saml.this[0].url_sso_post
    slo_url_redirect = authentik_provider_saml.this[0].url_slo_redirect
    slo_url_post     = authentik_provider_saml.this[0].url_slo_post
    metadata_url     = var.base_url != null ? "${trimend(var.base_url, "/")}/api/v3/providers/saml/${authentik_provider_saml.this[0].id}/metadata/" : null
  } : null
}

output "scim" {
  description = "SCIM backchannel provider details. `null` when SCIM is not configured. Sensitive because it includes the SCIM token."
  sensitive   = true
  value = var.scim != null ? {
    provider_id = authentik_provider_scim.this[0].id
    name        = authentik_provider_scim.this[0].name
    token       = authentik_provider_scim.this[0].token
  } : null
}
