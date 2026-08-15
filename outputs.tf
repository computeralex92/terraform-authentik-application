output "applications" {
  description = <<-EOT
    Map of created applications keyed by the `applications` map key, containing
    the application ID, protocol, and provider-specific details. Sensitive
    because it includes OAuth client secrets and SCIM tokens.
  EOT
  sensitive   = true
  value = {
    for k, v in var.applications : k => {
      id          = authentik_application.this[k].id
      name        = v.name
      slug        = v.slug
      protocol    = v.protocol
      launch_url  = authentik_application.this[k].meta_launch_url
      provider_id = v.protocol == "oauth2" ? authentik_provider_oauth2.this[k].id : authentik_provider_saml.this[k].id

      oauth2 = v.protocol == "oauth2" ? {
        client_id     = authentik_provider_oauth2.this[k].client_id
        client_secret = authentik_provider_oauth2.this[k].client_secret
      } : null

      saml = v.protocol == "saml" ? {
        sso_url_redirect = authentik_provider_saml.this[k].url_sso_redirect
        sso_url_post     = authentik_provider_saml.this[k].url_sso_post
        slo_url_redirect = authentik_provider_saml.this[k].url_slo_redirect
        slo_url_post     = authentik_provider_saml.this[k].url_slo_post
        metadata_url     = var.base_url != null ? "${trimend(var.base_url, "/")}/api/v3/providers/saml/${authentik_provider_saml.this[k].id}/metadata/" : null
      } : null

      scim = v.scim != null ? {
        provider_id = authentik_provider_scim.this[k].id
        name        = authentik_provider_scim.this[k].name
        token       = authentik_provider_scim.this[k].token
      } : null
    }
  }
}
