locals {
  oauth2_signing_key    = var.protocol == "oauth2" ? try(var.oauth2.signing_key, null) : null
  oauth2_encryption_key = var.protocol == "oauth2" ? try(var.oauth2.encryption_key, null) : null
  saml_signing_key      = var.protocol == "saml" ? try(var.saml.signing_key, null) : null
  saml_encryption_key   = var.protocol == "saml" ? try(var.saml.encryption_key, null) : null
  saml_verification_key = var.protocol == "saml" ? try(var.saml.verification_key, null) : null

  oauth2_property_mappings = concat(
    try(var.oauth2.property_mappings, []),
    authentik_property_mapping_provider_scope.this[*].id,
  )

  saml_property_mappings = concat(
    try(var.saml.property_mappings, []),
    authentik_property_mapping_provider_saml.this[*].id,
  )

  scim_user_property_mappings = concat(
    try(var.scim.property_mappings, []),
    authentik_property_mapping_provider_scim.user[*].id,
  )

  scim_group_property_mappings = concat(
    try(var.scim.property_mappings_group, []),
    authentik_property_mapping_provider_scim.group[*].id,
  )
}

# ---------------------------------------------------------------------------
# Data sources: flows and certificates referenced by providers
# ---------------------------------------------------------------------------

data "authentik_flow" "authorization" {
  slug = var.authorization_flow
}

data "authentik_flow" "invalidation" {
  slug = var.invalidation_flow
}

data "authentik_flow" "authentication" {
  count = var.authentication_flow != null ? 1 : 0
  slug  = var.authentication_flow
}

data "authentik_certificate_key_pair" "oauth2_signing" {
  count = local.oauth2_signing_key != null ? 1 : 0
  name  = local.oauth2_signing_key
}

data "authentik_certificate_key_pair" "oauth2_encryption" {
  count = local.oauth2_encryption_key != null ? 1 : 0
  name  = local.oauth2_encryption_key
}

data "authentik_certificate_key_pair" "saml_signing" {
  count = local.saml_signing_key != null ? 1 : 0
  name  = local.saml_signing_key
}

data "authentik_certificate_key_pair" "saml_encryption" {
  count = local.saml_encryption_key != null ? 1 : 0
  name  = local.saml_encryption_key
}

data "authentik_certificate_key_pair" "saml_verification" {
  count = local.saml_verification_key != null ? 1 : 0
  name  = local.saml_verification_key
}

# ---------------------------------------------------------------------------
# Property mappings (created only when defined inline)
# ---------------------------------------------------------------------------

resource "authentik_property_mapping_provider_scope" "this" {
  count       = length(try(var.oauth2.scopes, []))
  name        = coalesce(try(var.oauth2.scopes[count.index].name, null), var.oauth2.scopes[count.index].scope_name)
  scope_name  = var.oauth2.scopes[count.index].scope_name
  expression  = var.oauth2.scopes[count.index].expression
  description = var.oauth2.scopes[count.index].description
}

resource "authentik_property_mapping_provider_saml" "this" {
  count         = length(try(var.saml.attribute_mappings, []))
  name          = coalesce(try(var.saml.attribute_mappings[count.index].name, null), var.saml.attribute_mappings[count.index].saml_name)
  saml_name     = var.saml.attribute_mappings[count.index].saml_name
  expression    = var.saml.attribute_mappings[count.index].expression
  friendly_name = var.saml.attribute_mappings[count.index].friendly_name
}

resource "authentik_property_mapping_provider_scim" "user" {
  count      = length(try(var.scim.user_mappings, []))
  name       = var.scim.user_mappings[count.index].name
  expression = var.scim.user_mappings[count.index].expression
}

resource "authentik_property_mapping_provider_scim" "group" {
  count      = length(try(var.scim.group_mappings, []))
  name       = var.scim.group_mappings[count.index].name
  expression = var.scim.group_mappings[count.index].expression
}

# ---------------------------------------------------------------------------
# Provider
# ---------------------------------------------------------------------------

resource "authentik_provider_oauth2" "this" {
  count = var.protocol == "oauth2" ? 1 : 0

  name          = var.name
  client_id     = coalesce(try(var.oauth2.client_id, null), var.slug)
  client_secret = var.oauth2.client_secret
  client_type   = var.oauth2.client_type

  authorization_flow  = data.authentik_flow.authorization.id
  invalidation_flow   = data.authentik_flow.invalidation.id
  authentication_flow = try(data.authentik_flow.authentication[0].id, null)

  allowed_redirect_uris = var.oauth2.allowed_redirect_uris == null ? null : [
    for uri in var.oauth2.allowed_redirect_uris : try(uri.url, null) != null ? uri : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  grant_types                = var.oauth2.grant_types
  access_code_validity       = var.oauth2.access_code_validity
  access_token_validity      = var.oauth2.access_token_validity
  refresh_token_validity     = var.oauth2.refresh_token_validity
  refresh_token_threshold    = var.oauth2.refresh_token_threshold
  include_claims_in_id_token = var.oauth2.include_claims_in_id_token
  issuer_mode                = var.oauth2.issuer_mode
  logout_method              = var.oauth2.logout_method
  logout_uri                 = var.oauth2.logout_uri
  sub_mode                   = var.oauth2.sub_mode
  signing_key                = try(data.authentik_certificate_key_pair.oauth2_signing[0].id, null)
  encryption_key             = try(data.authentik_certificate_key_pair.oauth2_encryption[0].id, null)

  property_mappings = length(local.oauth2_property_mappings) > 0 ? local.oauth2_property_mappings : null
}

resource "authentik_provider_saml" "this" {
  count = var.protocol == "saml" ? 1 : 0

  name                = var.name
  authorization_flow  = data.authentik_flow.authorization.id
  invalidation_flow   = data.authentik_flow.invalidation.id
  authentication_flow = try(data.authentik_flow.authentication[0].id, null)

  acs_url              = var.saml.acs_url
  audience             = var.saml.audience
  sp_binding           = var.saml.sp_binding
  sls_url              = var.saml.sls_url
  sls_binding          = var.saml.sls_binding
  signing_kp           = try(data.authentik_certificate_key_pair.saml_signing[0].id, null)
  encryption_kp        = try(data.authentik_certificate_key_pair.saml_encryption[0].id, null)
  verification_kp      = try(data.authentik_certificate_key_pair.saml_verification[0].id, null)
  name_id_mapping      = var.saml.name_id_mapping
  digest_algorithm     = var.saml.digest_algorithm
  signature_algorithm  = var.saml.signature_algorithm
  sign_assertion       = var.saml.sign_assertion
  sign_response        = var.saml.sign_response
  sign_logout_request  = var.saml.sign_logout_request
  sign_logout_response = var.saml.sign_logout_response
  issuer_override      = var.saml.issuer_override
  default_relay_state  = var.saml.default_relay_state

  property_mappings = length(local.saml_property_mappings) > 0 ? local.saml_property_mappings : null
}

resource "authentik_provider_scim" "this" {
  count = var.scim != null ? 1 : 0

  name              = coalesce(var.scim.name, "${var.name} SCIM")
  url               = var.scim.url
  token             = var.scim.token
  auth_mode         = var.scim.auth_mode
  auth_oauth        = var.scim.auth_oauth
  auth_oauth_params = var.scim.auth_oauth_params == null ? null : jsonencode(var.scim.auth_oauth_params)

  compatibility_mode                    = var.scim.compatibility_mode
  dry_run                               = var.scim.dry_run
  exclude_users_service_account         = var.scim.exclude_users_service_account
  group_filters                         = var.scim.group_filters
  sync_page_size                        = var.scim.sync_page_size
  service_provider_config_cache_timeout = var.scim.service_provider_config_cache_timeout
  sync_page_timeout                     = var.scim.sync_page_timeout

  property_mappings       = length(local.scim_user_property_mappings) > 0 ? local.scim_user_property_mappings : null
  property_mappings_group = length(local.scim_group_property_mappings) > 0 ? local.scim_group_property_mappings : null
}

# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------

resource "authentik_application" "this" {
  name = var.name
  slug = var.slug

  protocol_provider = var.protocol == "oauth2" ? authentik_provider_oauth2.this[0].id : authentik_provider_saml.this[0].id

  backchannel_providers = var.scim != null ? [authentik_provider_scim.this[0].id] : null

  group              = var.group
  meta_launch_url    = var.meta_launch_url
  meta_icon          = var.meta_icon
  meta_description   = var.meta_description
  meta_publisher     = var.meta_publisher
  meta_hide          = var.meta_hide
  open_in_new_tab    = var.open_in_new_tab
  policy_engine_mode = var.policy_engine_mode
}
