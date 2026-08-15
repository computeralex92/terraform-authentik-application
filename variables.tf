variable "applications" {
  description = <<-EOT
    Map of Authentik applications to configure. Each map key is a unique
    identifier (usually the app slug); each value describes one application and
    its providers.

    Set `protocol` to `oauth2` or `saml` and provide the matching provider
    block. An optional `scim` block adds a SCIM backchannel provider so
    users/groups can be provisioned into the application.

    Property mappings (OAuth scopes, SAML attributes, SCIM user/group mappings)
    referenced via `property_mappings`/`property_mappings_group` must already
    exist in Authentik (resolve them with the corresponding `data.authentik_*`
    data sources in the calling configuration). Custom mappings defined inline
    (e.g. `oauth2.scopes`) are created by this module and attached to the
    provider.
  EOT

  type = map(object({
    name               = string
    slug               = string
    protocol           = string # "oauth2" or "saml"
    meta_launch_url    = optional(string)
    meta_icon          = optional(string)
    meta_description   = optional(string)
    meta_publisher     = optional(string)
    meta_hide          = optional(bool, false)
    open_in_new_tab    = optional(bool, false)
    group              = optional(string)
    policy_engine_mode = optional(string, "any")

    oauth2 = optional(object({
      client_id                  = optional(string)
      client_secret              = optional(string)
      client_type                = optional(string)
      authorization_flow         = optional(string)
      invalidation_flow          = optional(string)
      authentication_flow        = optional(string)
      allowed_redirect_uris      = optional(list(any))
      grant_types                = optional(list(string))
      access_code_validity       = optional(string)
      access_token_validity      = optional(string)
      refresh_token_validity     = optional(string)
      refresh_token_threshold    = optional(string)
      include_claims_in_id_token = optional(bool)
      issuer_mode                = optional(string)
      logout_method              = optional(string)
      logout_uri                 = optional(string)
      sub_mode                   = optional(string)
      signing_key                = optional(string)
      encryption_key             = optional(string)
      scopes = optional(list(object({
        scope_name  = string
        expression  = string
        description = optional(string)
        name        = optional(string)
      })))
      property_mappings = optional(list(string))
    }))

    saml = optional(object({
      acs_url              = string
      audience             = optional(string)
      authorization_flow   = optional(string)
      invalidation_flow    = optional(string)
      authentication_flow  = optional(string)
      sp_binding           = optional(string)
      sls_url              = optional(string)
      sls_binding          = optional(string)
      signing_key          = optional(string)
      encryption_key       = optional(string)
      verification_key     = optional(string)
      name_id_mapping      = optional(string)
      digest_algorithm     = optional(string)
      signature_algorithm  = optional(string)
      sign_assertion       = optional(bool)
      sign_response        = optional(bool)
      sign_logout_request  = optional(bool)
      sign_logout_response = optional(bool)
      issuer_override      = optional(string)
      default_relay_state  = optional(string)
      attribute_mappings = optional(list(object({
        saml_name     = string
        expression    = string
        name          = optional(string)
        friendly_name = optional(string)
      })))
      property_mappings = optional(list(string))
    }))

    scim = optional(object({
      url                                   = string
      name                                  = optional(string)
      token                                 = optional(string)
      auth_mode                             = optional(string)
      auth_oauth                            = optional(string)
      auth_oauth_params                     = optional(map(any))
      compatibility_mode                    = optional(string)
      dry_run                               = optional(bool)
      exclude_users_service_account         = optional(bool)
      group_filters                         = optional(list(string))
      sync_page_size                        = optional(number)
      service_provider_config_cache_timeout = optional(string)
      sync_page_timeout                     = optional(string)
      user_mappings = optional(list(object({
        name       = string
        expression = string
      })))
      group_mappings = optional(list(object({
        name       = string
        expression = string
      })))
      property_mappings       = optional(list(string))
      property_mappings_group = optional(list(string))
    }))
  }))

  validation {
    condition = alltrue([
      for k, v in var.applications : contains(["oauth2", "saml"], v.protocol)
    ])
    error_message = "Each application's 'protocol' must be either 'oauth2' or 'saml'."
  }

  validation {
    condition = alltrue([
      for k, v in var.applications : (
        (v.protocol == "oauth2" && v.oauth2 != null) ||
        (v.protocol == "saml" && v.saml != null)
      )
    ])
    error_message = "Each application must provide the matching provider config block (oauth2 for protocol 'oauth2', saml for protocol 'saml')."
  }

  validation {
    condition = alltrue([
      for k, v in var.applications : v.scim == null || (
        v.scim.token != null || v.scim.auth_mode == "oauth"
      )
    ])
    error_message = "SCIM config requires 'token' (the default token auth_mode) or 'auth_mode = \"oauth\"'."
  }
}

variable "default_flows" {
  description = <<-EOT
    Flow slugs used by providers when an application does not override them.
    These flows must exist in Authentik (the shipped defaults are used unless
    overridden).
  EOT
  type = object({
    authorization  = optional(string, "default-provider-authorization-implicit-consent")
    invalidation   = optional(string, "default-provider-invalidation")
    authentication = optional(string)
  })
  default = {}
}

variable "base_url" {
  description = "Base URL of the Authentik instance (e.g. https://auth.example.com). Used to build derived URLs such as the SAML metadata URL in outputs."
  type        = string
  default     = null
}
