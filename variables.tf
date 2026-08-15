variable "name" {
  description = "Display name shown in the Authentik dashboard."
  type        = string
}

variable "slug" {
  description = "Unique slug; also the default OAuth `client_id`."
  type        = string
}

variable "protocol" {
  description = "Provider protocol: `oauth2` or `saml`."
  type        = string
  validation {
    condition     = contains(["oauth2", "saml"], var.protocol)
    error_message = "`protocol` must be either 'oauth2' or 'saml'."
  }

  validation {
    condition     = (var.protocol == "oauth2" && var.oauth2 != null) || (var.protocol == "saml" && var.saml != null)
    error_message = "`protocol` requires the matching provider block: provide `oauth2` when protocol is 'oauth2', or `saml` when protocol is 'saml'."
  }
}

variable "base_url" {
  description = "Base URL of the Authentik instance (e.g. https://auth.example.com). Used to build derived URLs such as the SAML metadata URL in outputs."
  type        = string
  default     = null
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
