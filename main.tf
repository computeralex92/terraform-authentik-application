locals {
  oauth_apps = {
    for k, v in var.applications : k => v
    if v.protocol == "oauth2"
  }

  saml_apps = {
    for k, v in var.applications : k => v
    if v.protocol == "saml"
  }

  scim_apps = {
    for k, v in var.applications : k => v
    if v.scim != null
  }

  flow_slugs = {
    for k, v in var.applications : k => {
      authorization = coalesce(
        try(v.oauth2.authorization_flow, null),
        try(v.saml.authorization_flow, null),
        var.default_flows.authorization,
      )
      invalidation = coalesce(
        try(v.oauth2.invalidation_flow, null),
        try(v.saml.invalidation_flow, null),
        var.default_flows.invalidation,
      )
      authentication = coalesce(
        try(v.oauth2.authentication_flow, null),
        try(v.saml.authentication_flow, null),
        var.default_flows.authentication,
      )
    }
  }

  authentication_flows = {
    for k, v in local.flow_slugs : k => v.authentication
    if v.authentication != null
  }

  oauth2_signing_keys = {
    for k, v in local.oauth_apps : k => v.oauth2.signing_key
    if v.oauth2.signing_key != null
  }
  oauth2_encryption_keys = {
    for k, v in local.oauth_apps : k => v.oauth2.encryption_key
    if v.oauth2.encryption_key != null
  }
  saml_signing_keys = {
    for k, v in local.saml_apps : k => v.saml.signing_key
    if v.saml.signing_key != null
  }
  saml_encryption_keys = {
    for k, v in local.saml_apps : k => v.saml.encryption_key
    if v.saml.encryption_key != null
  }
  saml_verification_keys = {
    for k, v in local.saml_apps : k => v.saml.verification_key
    if v.saml.verification_key != null
  }

  scope_mappings = {
    for pair in flatten([
      for k, v in var.applications : [
        for idx, scope in try(v.oauth2.scopes, []) : {
          key   = "${k}-${idx}"
          app   = k
          scope = scope
        }
      ]
    ]) : pair.key => pair
  }

  saml_mappings = {
    for pair in flatten([
      for k, v in var.applications : [
        for idx, mapping in try(v.saml.attribute_mappings, []) : {
          key     = "${k}-${idx}"
          app     = k
          mapping = mapping
        }
      ]
    ]) : pair.key => pair
  }

  scim_user_mappings = {
    for pair in flatten([
      for k, v in var.applications : [
        for idx, mapping in try(v.scim.user_mappings, []) : {
          key     = "${k}-${idx}"
          app     = k
          mapping = mapping
        }
      ]
    ]) : pair.key => pair
  }

  scim_group_mappings = {
    for pair in flatten([
      for k, v in var.applications : [
        for idx, mapping in try(v.scim.group_mappings, []) : {
          key     = "${k}-${idx}"
          app     = k
          mapping = mapping
        }
      ]
    ]) : pair.key => pair
  }

  oauth2_property_mappings = {
    for k, v in local.oauth_apps : k => concat(
      try(v.oauth2.property_mappings, []),
      [for pair in local.scope_mappings : authentik_property_mapping_provider_scope.this[pair.key].id if pair.app == k],
    )
  }

  saml_property_mappings = {
    for k, v in local.saml_apps : k => concat(
      try(v.saml.property_mappings, []),
      [for pair in local.saml_mappings : authentik_property_mapping_provider_saml.this[pair.key].id if pair.app == k],
    )
  }

  scim_user_property_mappings = {
    for k, v in local.scim_apps : k => concat(
      try(v.scim.property_mappings, []),
      [for pair in local.scim_user_mappings : authentik_property_mapping_provider_scim.user[pair.key].id if pair.app == k],
    )
  }

  scim_group_property_mappings = {
    for k, v in local.scim_apps : k => concat(
      try(v.scim.property_mappings_group, []),
      [for pair in local.scim_group_mappings : authentik_property_mapping_provider_scim.group[pair.key].id if pair.app == k],
    )
  }
}

# ---------------------------------------------------------------------------
# Data sources: flows and certificates referenced by providers
# ---------------------------------------------------------------------------

data "authentik_flow" "authorization" {
  for_each = var.applications
  slug     = local.flow_slugs[each.key].authorization
}

data "authentik_flow" "invalidation" {
  for_each = var.applications
  slug     = local.flow_slugs[each.key].invalidation
}

data "authentik_flow" "authentication" {
  for_each = local.authentication_flows
  slug     = each.value
}

data "authentik_certificate_key_pair" "oauth2_signing" {
  for_each = local.oauth2_signing_keys
  name     = each.value
}

data "authentik_certificate_key_pair" "oauth2_encryption" {
  for_each = local.oauth2_encryption_keys
  name     = each.value
}

data "authentik_certificate_key_pair" "saml_signing" {
  for_each = local.saml_signing_keys
  name     = each.value
}

data "authentik_certificate_key_pair" "saml_encryption" {
  for_each = local.saml_encryption_keys
  name     = each.value
}

data "authentik_certificate_key_pair" "saml_verification" {
  for_each = local.saml_verification_keys
  name     = each.value
}

# ---------------------------------------------------------------------------
# Property mappings (created only when defined inline per application)
# ---------------------------------------------------------------------------

resource "authentik_property_mapping_provider_scope" "this" {
  for_each    = local.scope_mappings
  name        = coalesce(each.value.scope.name, each.value.scope.scope_name)
  scope_name  = each.value.scope.scope_name
  expression  = each.value.scope.expression
  description = each.value.scope.description
}

resource "authentik_property_mapping_provider_saml" "this" {
  for_each      = local.saml_mappings
  name          = coalesce(each.value.mapping.name, each.value.mapping.saml_name)
  saml_name     = each.value.mapping.saml_name
  expression    = each.value.mapping.expression
  friendly_name = each.value.mapping.friendly_name
}

resource "authentik_property_mapping_provider_scim" "user" {
  for_each   = local.scim_user_mappings
  name       = each.value.mapping.name
  expression = each.value.mapping.expression
}

resource "authentik_property_mapping_provider_scim" "group" {
  for_each   = local.scim_group_mappings
  name       = each.value.mapping.name
  expression = each.value.mapping.expression
}

# ---------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------

resource "authentik_provider_oauth2" "this" {
  for_each = local.oauth_apps

  name          = each.value.name
  client_id     = coalesce(try(each.value.oauth2.client_id, null), each.value.slug)
  client_secret = each.value.oauth2.client_secret
  client_type   = each.value.oauth2.client_type

  authorization_flow  = data.authentik_flow.authorization[each.key].id
  invalidation_flow   = data.authentik_flow.invalidation[each.key].id
  authentication_flow = try(data.authentik_flow.authentication[each.key].id, null)

  allowed_redirect_uris = each.value.oauth2.allowed_redirect_uris == null ? null : [
    for uri in each.value.oauth2.allowed_redirect_uris : try(uri.url, null) != null ? uri : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  grant_types                = each.value.oauth2.grant_types
  access_code_validity       = each.value.oauth2.access_code_validity
  access_token_validity      = each.value.oauth2.access_token_validity
  refresh_token_validity     = each.value.oauth2.refresh_token_validity
  refresh_token_threshold    = each.value.oauth2.refresh_token_threshold
  include_claims_in_id_token = each.value.oauth2.include_claims_in_id_token
  issuer_mode                = each.value.oauth2.issuer_mode
  logout_method              = each.value.oauth2.logout_method
  logout_uri                 = each.value.oauth2.logout_uri
  sub_mode                   = each.value.oauth2.sub_mode
  signing_key                = try(data.authentik_certificate_key_pair.oauth2_signing[each.key].id, null)
  encryption_key             = try(data.authentik_certificate_key_pair.oauth2_encryption[each.key].id, null)

  property_mappings = length(local.oauth2_property_mappings[each.key]) > 0 ? local.oauth2_property_mappings[each.key] : null
}

resource "authentik_provider_saml" "this" {
  for_each = local.saml_apps

  name                = each.value.name
  authorization_flow  = data.authentik_flow.authorization[each.key].id
  invalidation_flow   = data.authentik_flow.invalidation[each.key].id
  authentication_flow = try(data.authentik_flow.authentication[each.key].id, null)

  acs_url              = each.value.saml.acs_url
  audience             = each.value.saml.audience
  sp_binding           = each.value.saml.sp_binding
  sls_url              = each.value.saml.sls_url
  sls_binding          = each.value.saml.sls_binding
  signing_kp           = try(data.authentik_certificate_key_pair.saml_signing[each.key].id, null)
  encryption_kp        = try(data.authentik_certificate_key_pair.saml_encryption[each.key].id, null)
  verification_kp      = try(data.authentik_certificate_key_pair.saml_verification[each.key].id, null)
  name_id_mapping      = each.value.saml.name_id_mapping
  digest_algorithm     = each.value.saml.digest_algorithm
  signature_algorithm  = each.value.saml.signature_algorithm
  sign_assertion       = each.value.saml.sign_assertion
  sign_response        = each.value.saml.sign_response
  sign_logout_request  = each.value.saml.sign_logout_request
  sign_logout_response = each.value.saml.sign_logout_response
  issuer_override      = each.value.saml.issuer_override
  default_relay_state  = each.value.saml.default_relay_state

  property_mappings = length(local.saml_property_mappings[each.key]) > 0 ? local.saml_property_mappings[each.key] : null
}

resource "authentik_provider_scim" "this" {
  for_each = local.scim_apps

  name              = coalesce(each.value.scim.name, "${each.value.name} SCIM")
  url               = each.value.scim.url
  token             = each.value.scim.token
  auth_mode         = each.value.scim.auth_mode
  auth_oauth        = each.value.scim.auth_oauth
  auth_oauth_params = each.value.scim.auth_oauth_params == null ? null : jsonencode(each.value.scim.auth_oauth_params)

  compatibility_mode                    = each.value.scim.compatibility_mode
  dry_run                               = each.value.scim.dry_run
  exclude_users_service_account         = each.value.scim.exclude_users_service_account
  group_filters                         = each.value.scim.group_filters
  sync_page_size                        = each.value.scim.sync_page_size
  service_provider_config_cache_timeout = each.value.scim.service_provider_config_cache_timeout
  sync_page_timeout                     = each.value.scim.sync_page_timeout

  property_mappings       = length(local.scim_user_property_mappings[each.key]) > 0 ? local.scim_user_property_mappings[each.key] : null
  property_mappings_group = length(local.scim_group_property_mappings[each.key]) > 0 ? local.scim_group_property_mappings[each.key] : null
}

# ---------------------------------------------------------------------------
# Application
# ---------------------------------------------------------------------------

resource "authentik_application" "this" {
  for_each = var.applications

  name = each.value.name
  slug = each.value.slug

  protocol_provider = each.value.protocol == "oauth2" ? authentik_provider_oauth2.this[each.key].id : authentik_provider_saml.this[each.key].id

  backchannel_providers = each.value.scim != null ? [authentik_provider_scim.this[each.key].id] : null

  group              = each.value.group
  meta_launch_url    = each.value.meta_launch_url
  meta_icon          = each.value.meta_icon
  meta_description   = each.value.meta_description
  meta_publisher     = each.value.meta_publisher
  meta_hide          = each.value.meta_hide
  open_in_new_tab    = each.value.open_in_new_tab
  policy_engine_mode = each.value.policy_engine_mode
}
