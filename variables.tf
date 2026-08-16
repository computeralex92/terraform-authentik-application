variable "name" {
  description = "Display name shown in the Authentik dashboard."
  type        = string
}

variable "slug" {
  description = "Unique slug; also the default OAuth `client_id`."
  type        = string
  validation {
    condition     = can(regex("^[-a-zA-Z0-9_]+$", var.slug))
    error_message = "`slug` must match Authentik's slug format: letters, digits, hyphens, and underscores only."
  }
}

variable "protocol" {
  description = "Provider protocol: `oauth2`, `saml`, `proxy`, `ldap`, `radius`, `ws_federation`, `microsoft_entra`, `google_workspace`, `rac`, or `ssf`."
  type        = string
  validation {
    condition     = contains(["oauth2", "saml", "proxy", "ldap", "radius", "ws_federation", "microsoft_entra", "google_workspace", "rac", "ssf"], var.protocol)
    error_message = "`protocol` must be one of 'oauth2', 'saml', 'proxy', 'ldap', 'radius', 'ws_federation', 'microsoft_entra', 'google_workspace', 'rac', or 'ssf'."
  }

  validation {
    condition = (
      (var.protocol == "oauth2" && var.oauth2 != null) ||
      (var.protocol == "saml" && var.saml != null) ||
      (var.protocol == "proxy" && var.proxy != null) ||
      (var.protocol == "ldap" && var.ldap != null) ||
      (var.protocol == "radius" && var.radius != null) ||
      (var.protocol == "ws_federation" && var.ws_federation != null) ||
      (var.protocol == "microsoft_entra" && var.microsoft_entra != null) ||
      (var.protocol == "google_workspace" && var.google_workspace != null) ||
      (var.protocol == "rac" && var.rac != null) ||
      (var.protocol == "ssf" && var.ssf != null)
    )
    error_message = "`protocol` requires the matching provider block: provide the block for the protocol you select."
  }
}

variable "base_url" {
  description = "Base URL of the Authentik instance (e.g. https://auth.example.com). Used to build derived URLs such as the SAML metadata URL in outputs."
  type        = string
  default     = null
  validation {
    condition     = var.base_url == null || can(regex("^https?://", var.base_url))
    error_message = "`base_url` must be an absolute http(s) URL (e.g. https://auth.example.com)."
  }
}

variable "meta_launch_url" {
  description = "Launch URL for the application."
  type        = string
  default     = null
}

variable "meta_icon" {
  description = "Icon URL for the application."
  type        = string
  default     = null
}

variable "meta_description" {
  description = "Short description of the application."
  type        = string
  default     = null
}

variable "meta_publisher" {
  description = "Publisher name of the application."
  type        = string
  default     = null
}

variable "meta_hide" {
  description = "Hide the application from the Authentik dashboard."
  type        = bool
  default     = false
}

variable "open_in_new_tab" {
  description = "Open the application launch URL in a new tab."
  type        = bool
  default     = false
}

variable "group" {
  description = "Application group for dashboard organization."
  type        = string
  default     = null
}

variable "policy_engine_mode" {
  description = "Policy engine mode for the application."
  type        = string
  default     = "any"
  validation {
    condition     = contains(["any", "all"], var.policy_engine_mode)
    error_message = "`policy_engine_mode` must be 'any' or 'all'."
  }
}

variable "authorization_flow" {
  description = "Slug of the authorization flow used by the provider (must exist in Authentik)."
  type        = string
  default     = "default-provider-authorization-implicit-consent"
}

variable "invalidation_flow" {
  description = "Slug of the invalidation flow used by the provider (must exist in Authentik)."
  type        = string
  default     = "default-provider-invalidation"
}

variable "authentication_flow" {
  description = "Slug of an optional authentication flow used by the provider (must exist in Authentik)."
  type        = string
  default     = null
}

variable "bind_flow" {
  description = "Slug of the bind flow used by the LDAP provider (must exist in Authentik)."
  type        = string
  default     = "default-authentication-flow"
}

variable "unbind_flow" {
  description = "Slug of the unbind flow used by the LDAP provider (must exist in Authentik)."
  type        = string
  default     = "default-provider-invalidation"
}

variable "oauth2" {
  description = <<-EOT
    OAuth2 provider configuration. Required when `protocol = "oauth2"`. If
    `client_secret` is omitted, Authentik generates one. `signing_key` and
    `encryption_key` are certificate key pair names. `scopes` creates scope
    mappings and attaches them; `property_mappings` references existing scope
    mapping IDs.
  EOT
  type = object({
    client_id                  = optional(string)
    client_secret              = optional(string)
    client_type                = optional(string)
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
  })
  default = null
}

variable "saml" {
  description = <<-EOT
    SAML provider configuration. Required when `protocol = "saml"`. `signing_key`,
    `encryption_key`, and `verification_key` are certificate key pair names.
    `attribute_mappings` creates SAML property mappings and attaches them;
    `property_mappings` references existing SAML property mapping IDs.
  EOT
  type = object({
    acs_url              = string
    audience             = optional(string)
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
  })
  default = null
}

variable "proxy" {
  description = <<-EOT
    Reverse-proxy provider configuration. Required when `protocol = "proxy"`.
    `external_host` is the externally reachable host. `scopes` creates scope
    mappings and attaches them; `property_mappings` references existing scope
    mapping IDs.
  EOT
  type = object({
    external_host                 = string
    mode                          = optional(string)
    internal_host                 = optional(string)
    internal_host_ssl_validation  = optional(bool)
    intercept_header_auth         = optional(bool)
    cookie_domain                 = optional(string)
    basic_auth_enabled            = optional(bool)
    basic_auth_username_attribute = optional(string)
    basic_auth_password_attribute = optional(string)
    access_token_validity         = optional(string)
    refresh_token_validity        = optional(string)
    skip_path_regex               = optional(string)
    jwt_federation_providers      = optional(list(number))
    jwt_federation_sources        = optional(list(string))
    scopes = optional(list(object({
      scope_name  = string
      expression  = string
      description = optional(string)
      name        = optional(string)
    })))
    property_mappings = optional(list(string))
  })
  default = null
}

variable "ldap" {
  description = <<-EOT
    LDAP provider configuration. Required when `protocol = "ldap"`. Uses
    `bind_flow` / `unbind_flow` for the bind/unbind flows. `certificate` is a
    certificate key pair name.
  EOT
  type = object({
    base_dn          = string
    bind_mode        = optional(string)
    search_mode      = optional(string)
    certificate      = optional(string)
    mfa_support      = optional(bool)
    tls_server_name  = optional(string)
    gid_start_number = optional(number)
    uid_start_number = optional(number)
  })
  default = null
}

variable "radius" {
  description = <<-EOT
    RADIUS provider configuration. Required when `protocol = "radius"`.
    `shared_secret` is the RADIUS shared secret. `certificate` is a certificate
    key pair name. `mappings` creates RADIUS property mappings and attaches
    them; `property_mappings` references existing RADIUS property mapping IDs.
  EOT
  type = object({
    shared_secret   = string
    client_networks = optional(string)
    certificate     = optional(string)
    mfa_support     = optional(bool)
    mappings = optional(list(object({
      name       = string
      expression = string
    })))
    property_mappings = optional(list(string))
  })
  default = null
}

variable "ws_federation" {
  description = <<-EOT
    WS-Federation provider configuration. Required when `protocol = "ws_federation"`.
    `signing_key` and `encryption_key` are certificate key pair names.
    `attribute_mappings` creates WS-Federation property mappings and attaches
    them; `property_mappings` references existing WS-Federation property
    mapping IDs.
  EOT
  type = object({
    reply_url                       = string
    wtrealm                         = string
    assertion_valid_not_before      = optional(string)
    assertion_valid_not_on_or_after = optional(string)
    authn_context_class_ref_mapping = optional(string)
    digest_algorithm                = optional(string)
    signature_algorithm             = optional(string)
    signing_key                     = optional(string)
    encryption_key                  = optional(string)
    name_id_mapping                 = optional(string)
    session_valid_not_on_or_after   = optional(string)
    sign_assertion                  = optional(bool)
    sign_logout_request             = optional(bool)
    attribute_mappings = optional(list(object({
      saml_name     = string
      expression    = string
      name          = optional(string)
      friendly_name = optional(string)
    })))
    property_mappings = optional(list(string))
  })
  default = null
}

variable "microsoft_entra" {
  description = <<-EOT
    Microsoft Entra provider configuration. Required when `protocol = "microsoft_entra"`.
    `user_mappings` / `group_mappings` create Entra property mappings;
    `property_mappings` / `property_mappings_group` reference existing Entra
    property mapping IDs.
  EOT
  type = object({
    client_id                     = string
    client_secret                 = string
    tenant_id                     = string
    dry_run                       = optional(bool)
    exclude_users_service_account = optional(bool)
    filter_group                  = optional(string)
    group_delete_action           = optional(string)
    user_delete_action            = optional(string)
    sync_page_size                = optional(number)
    sync_page_timeout             = optional(string)
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
  })
  default = null
}

variable "google_workspace" {
  description = <<-EOT
    Google Workspace provider configuration. Required when `protocol = "google_workspace"`.
    Provisioning provider that syncs users and groups from Authentik to Google
    Workspace. `credentials` is a service-account JSON object (json-encoded).
    `user_mappings` / `group_mappings` create Google Workspace property
    mappings; `property_mappings` / `property_mappings_group` reference
    existing Google Workspace property mapping IDs.
  EOT
  type = object({
    default_group_email_domain    = string
    credentials                   = optional(map(any))
    delegated_subject             = optional(string)
    dry_run                       = optional(bool)
    exclude_users_service_account = optional(bool)
    filter_group                  = optional(string)
    group_delete_action           = optional(string)
    user_delete_action            = optional(string)
    sync_page_size                = optional(number)
    sync_page_timeout             = optional(string)
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
  })
  default = null
}

variable "rac" {
  description = <<-EOT
    RAC (Remote Access Control) provider configuration. Required when
    `protocol = "rac"`. Provides SSH/RDP/VNC access to remote machines defined
    as `endpoints`. `mappings` creates RAC property mappings and attaches them;
    `property_mappings` references existing RAC property mapping IDs.
  EOT
  type = object({
    connection_expiry = optional(string)
    settings          = optional(map(any))
    mappings = optional(list(object({
      name       = string
      expression = optional(string)
      settings   = optional(map(any))
    })))
    property_mappings = optional(list(string))
    endpoints = optional(list(object({
      name                = string
      host                = string
      protocol            = string
      maximum_connections = optional(number)
      settings            = optional(map(any))
      property_mappings   = optional(list(string))
    })))
  })
  default = null

  validation {
    condition = var.rac == null || alltrue([
      for endpoint in var.rac.endpoints == null ? [] : var.rac.endpoints : contains(["rdp", "vnc", "ssh"], endpoint.protocol)
    ])
    error_message = "`rac` endpoints `protocol` must be one of 'rdp', 'vnc', or 'ssh'."
  }
}

variable "ssf" {
  description = <<-EOT
    SSF (Shared Signals Framework) provider configuration. Required when
    `protocol = "ssf"`. Streams real-time security events (MFA changes,
    logouts) as Security Event Tokens to subscribed OIDC applications.
    `signing_key` is a certificate key pair name.
  EOT
  type = object({
    event_retention          = optional(string)
    signing_key              = optional(string)
    jwt_federation_providers = optional(list(number))
    push_verify_certificates = optional(bool)
  })
  default = null
}

variable "scim" {
  description = <<-EOT
    SCIM backchannel provider configuration. Omit (or set to null) to disable;
    providing this block creates a SCIM provider and attaches it to the
    application as a backchannel provider so users/groups can be provisioned
    into the application. `token` is required unless `auth_mode = "oauth"`.
  EOT
  type = object({
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
  })
  default = null

  validation {
    condition     = var.scim == null || (var.scim.token != null || var.scim.auth_mode == "oauth")
    error_message = "`scim` requires `token` (the default token auth_mode) or `auth_mode = \"oauth\"`."
  }
}
