output "application_id" {
  description = "ID of the created Authentik application."
  value       = authentik_application.this.id
}

output "provider_id" {
  description = "ID of the created provider."
  value       = local.provider_id
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

output "proxy" {
  description = "Reverse-proxy provider details. `null` when `protocol` is not `proxy`."
  value = var.protocol == "proxy" ? {
    client_id     = authentik_provider_proxy.this[0].client_id
    external_host = authentik_provider_proxy.this[0].external_host
  } : null
}

output "ldap" {
  description = "LDAP provider details. `null` when `protocol` is not `ldap`."
  value = var.protocol == "ldap" ? {
    base_dn = authentik_provider_ldap.this[0].base_dn
  } : null
}

output "radius" {
  description = "RADIUS provider details. `null` when `protocol` is not `radius`. Sensitive because it includes the shared secret."
  sensitive   = true
  value = var.protocol == "radius" ? {
    shared_secret   = authentik_provider_radius.this[0].shared_secret
    client_networks = authentik_provider_radius.this[0].client_networks
  } : null
}

output "ws_federation" {
  description = "WS-Federation provider details. `null` when `protocol` is not `ws_federation`."
  value = var.protocol == "ws_federation" ? {
    reply_url = authentik_provider_ws_federation.this[0].reply_url
    wtrealm   = authentik_provider_ws_federation.this[0].wtrealm
  } : null
}

output "microsoft_entra" {
  description = "Microsoft Entra provider details. `null` when `protocol` is not `microsoft_entra`. Sensitive because it includes the client secret."
  sensitive   = true
  value = var.protocol == "microsoft_entra" ? {
    client_id     = authentik_provider_microsoft_entra.this[0].client_id
    client_secret = authentik_provider_microsoft_entra.this[0].client_secret
    tenant_id     = authentik_provider_microsoft_entra.this[0].tenant_id
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
