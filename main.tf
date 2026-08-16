locals {
  uses_authorization_flow  = contains(["oauth2", "saml", "proxy", "radius", "ws_federation", "rac"], var.protocol)
  uses_invalidation_flow   = contains(["oauth2", "saml", "proxy", "radius", "ws_federation"], var.protocol)
  uses_authentication_flow = contains(["oauth2", "saml", "proxy", "ws_federation", "rac"], var.protocol)

  oauth2_property_mappings = concat(
    try(var.oauth2.property_mappings, []),
    authentik_property_mapping_provider_scope.this[*].id,
  )

  saml_property_mappings = concat(
    try(var.saml.property_mappings, []),
    authentik_property_mapping_provider_saml.this[*].id,
  )

  proxy_property_mappings = concat(
    try(var.proxy.property_mappings, []),
    authentik_property_mapping_provider_scope.proxy[*].id,
  )

  radius_property_mappings = concat(
    try(var.radius.property_mappings, []),
    authentik_property_mapping_provider_radius.this[*].id,
  )

  ws_federation_property_mappings = concat(
    try(var.ws_federation.property_mappings, []),
    authentik_property_mapping_provider_saml.ws_federation[*].id,
  )

  entra_user_property_mappings = concat(
    try(var.microsoft_entra.property_mappings, []),
    authentik_property_mapping_provider_microsoft_entra.user[*].id,
  )

  entra_group_property_mappings = concat(
    try(var.microsoft_entra.property_mappings_group, []),
    authentik_property_mapping_provider_microsoft_entra.group[*].id,
  )

  google_workspace_user_property_mappings = concat(
    try(var.google_workspace.property_mappings, []),
    authentik_property_mapping_provider_google_workspace.user[*].id,
  )

  google_workspace_group_property_mappings = concat(
    try(var.google_workspace.property_mappings_group, []),
    authentik_property_mapping_provider_google_workspace.group[*].id,
  )

  rac_property_mappings = concat(
    try(var.rac.property_mappings, []),
    authentik_property_mapping_provider_rac.this[*].id,
  )

  scim_user_property_mappings = concat(
    try(var.scim.property_mappings, []),
    authentik_property_mapping_provider_scim.user[*].id,
  )

  scim_group_property_mappings = concat(
    try(var.scim.property_mappings_group, []),
    authentik_property_mapping_provider_scim.group[*].id,
  )

  provider_id = one(concat(
    authentik_provider_oauth2.this[*].id,
    authentik_provider_saml.this[*].id,
    authentik_provider_proxy.this[*].id,
    authentik_provider_ldap.this[*].id,
    authentik_provider_radius.this[*].id,
    authentik_provider_ws_federation.this[*].id,
    authentik_provider_microsoft_entra.this[*].id,
    authentik_provider_google_workspace.this[*].id,
    authentik_provider_rac.this[*].id,
    authentik_provider_ssf.this[*].id,
  ))
}

# ---------------------------------------------------------------------------
# Data sources: flows and certificates referenced by providers
# ---------------------------------------------------------------------------

data "authentik_flow" "authorization" {
  count = local.uses_authorization_flow ? 1 : 0
  slug  = var.authorization_flow
}

data "authentik_flow" "invalidation" {
  count = local.uses_invalidation_flow ? 1 : 0
  slug  = var.invalidation_flow
}

data "authentik_flow" "authentication" {
  count = local.uses_authentication_flow && var.authentication_flow != null ? 1 : 0
  slug  = var.authentication_flow
}

data "authentik_flow" "bind" {
  count = var.protocol == "ldap" ? 1 : 0
  slug  = var.bind_flow
}

data "authentik_flow" "unbind" {
  count = var.protocol == "ldap" ? 1 : 0
  slug  = var.unbind_flow
}

data "authentik_certificate_key_pair" "oauth2_signing" {
  count = var.protocol == "oauth2" && try(var.oauth2.signing_key, null) != null ? 1 : 0
  name  = var.oauth2.signing_key
}

data "authentik_certificate_key_pair" "oauth2_encryption" {
  count = var.protocol == "oauth2" && try(var.oauth2.encryption_key, null) != null ? 1 : 0
  name  = var.oauth2.encryption_key
}

data "authentik_certificate_key_pair" "saml_signing" {
  count = var.protocol == "saml" && try(var.saml.signing_key, null) != null ? 1 : 0
  name  = var.saml.signing_key
}

data "authentik_certificate_key_pair" "saml_encryption" {
  count = var.protocol == "saml" && try(var.saml.encryption_key, null) != null ? 1 : 0
  name  = var.saml.encryption_key
}

data "authentik_certificate_key_pair" "saml_verification" {
  count = var.protocol == "saml" && try(var.saml.verification_key, null) != null ? 1 : 0
  name  = var.saml.verification_key
}

data "authentik_certificate_key_pair" "ldap_cert" {
  count = var.protocol == "ldap" && try(var.ldap.certificate, null) != null ? 1 : 0
  name  = var.ldap.certificate
}

data "authentik_certificate_key_pair" "radius_cert" {
  count = var.protocol == "radius" && try(var.radius.certificate, null) != null ? 1 : 0
  name  = var.radius.certificate
}

data "authentik_certificate_key_pair" "ws_fed_signing" {
  count = var.protocol == "ws_federation" && try(var.ws_federation.signing_key, null) != null ? 1 : 0
  name  = var.ws_federation.signing_key
}

data "authentik_certificate_key_pair" "ws_fed_encryption" {
  count = var.protocol == "ws_federation" && try(var.ws_federation.encryption_key, null) != null ? 1 : 0
  name  = var.ws_federation.encryption_key
}

data "authentik_certificate_key_pair" "ssf_signing" {
  count = var.protocol == "ssf" && try(var.ssf.signing_key, null) != null ? 1 : 0
  name  = var.ssf.signing_key
}

# ---------------------------------------------------------------------------
# Property mappings (created only when defined inline)
# ---------------------------------------------------------------------------

resource "authentik_property_mapping_provider_scope" "this" {
  count       = var.protocol == "oauth2" ? length(try(var.oauth2.scopes, [])) : 0
  name        = coalesce(try(var.oauth2.scopes[count.index].name, null), var.oauth2.scopes[count.index].scope_name)
  scope_name  = var.oauth2.scopes[count.index].scope_name
  expression  = var.oauth2.scopes[count.index].expression
  description = var.oauth2.scopes[count.index].description
}

resource "authentik_property_mapping_provider_scope" "proxy" {
  count       = var.protocol == "proxy" ? length(try(var.proxy.scopes, [])) : 0
  name        = coalesce(try(var.proxy.scopes[count.index].name, null), var.proxy.scopes[count.index].scope_name)
  scope_name  = var.proxy.scopes[count.index].scope_name
  expression  = var.proxy.scopes[count.index].expression
  description = var.proxy.scopes[count.index].description
}

resource "authentik_property_mapping_provider_saml" "this" {
  count         = var.protocol == "saml" ? length(try(var.saml.attribute_mappings, [])) : 0
  name          = coalesce(try(var.saml.attribute_mappings[count.index].name, null), var.saml.attribute_mappings[count.index].saml_name)
  saml_name     = var.saml.attribute_mappings[count.index].saml_name
  expression    = var.saml.attribute_mappings[count.index].expression
  friendly_name = var.saml.attribute_mappings[count.index].friendly_name
}

resource "authentik_property_mapping_provider_saml" "ws_federation" {
  count         = var.protocol == "ws_federation" ? length(try(var.ws_federation.attribute_mappings, [])) : 0
  name          = coalesce(try(var.ws_federation.attribute_mappings[count.index].name, null), var.ws_federation.attribute_mappings[count.index].saml_name)
  saml_name     = var.ws_federation.attribute_mappings[count.index].saml_name
  expression    = var.ws_federation.attribute_mappings[count.index].expression
  friendly_name = var.ws_federation.attribute_mappings[count.index].friendly_name
}

resource "authentik_property_mapping_provider_radius" "this" {
  count      = var.protocol == "radius" ? length(try(var.radius.mappings, [])) : 0
  name       = var.radius.mappings[count.index].name
  expression = var.radius.mappings[count.index].expression
}

resource "authentik_property_mapping_provider_microsoft_entra" "user" {
  count      = var.protocol == "microsoft_entra" ? length(try(var.microsoft_entra.user_mappings, [])) : 0
  name       = var.microsoft_entra.user_mappings[count.index].name
  expression = var.microsoft_entra.user_mappings[count.index].expression
}

resource "authentik_property_mapping_provider_microsoft_entra" "group" {
  count      = var.protocol == "microsoft_entra" ? length(try(var.microsoft_entra.group_mappings, [])) : 0
  name       = var.microsoft_entra.group_mappings[count.index].name
  expression = var.microsoft_entra.group_mappings[count.index].expression
}

resource "authentik_property_mapping_provider_google_workspace" "user" {
  count      = var.protocol == "google_workspace" ? length(try(var.google_workspace.user_mappings, [])) : 0
  name       = var.google_workspace.user_mappings[count.index].name
  expression = var.google_workspace.user_mappings[count.index].expression
}

resource "authentik_property_mapping_provider_google_workspace" "group" {
  count      = var.protocol == "google_workspace" ? length(try(var.google_workspace.group_mappings, [])) : 0
  name       = var.google_workspace.group_mappings[count.index].name
  expression = var.google_workspace.group_mappings[count.index].expression
}

resource "authentik_property_mapping_provider_rac" "this" {
  count      = var.protocol == "rac" ? length(try(var.rac.mappings, [])) : 0
  name       = var.rac.mappings[count.index].name
  expression = var.rac.mappings[count.index].expression
  settings   = var.rac.mappings[count.index].settings == null ? null : jsonencode(var.rac.mappings[count.index].settings)
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

  authorization_flow  = data.authentik_flow.authorization[0].id
  invalidation_flow   = data.authentik_flow.invalidation[0].id
  authentication_flow = try(data.authentik_flow.authentication[0].id, null)

  allowed_redirect_uris = var.oauth2.allowed_redirect_uris == null ? null : [
    for uri in var.oauth2.allowed_redirect_uris : try(uri.url, null) != null ? uri : {
      matching_mode = "strict"
      url           = uri
    }
  ]

  grant_types                = var.oauth2.grant_types
  jwt_federation_providers   = var.oauth2.jwt_federation_providers
  jwt_federation_sources     = var.oauth2.jwt_federation_sources
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
  authorization_flow  = data.authentik_flow.authorization[0].id
  invalidation_flow   = data.authentik_flow.invalidation[0].id
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

resource "authentik_provider_proxy" "this" {
  count = var.protocol == "proxy" ? 1 : 0

  name          = var.name
  external_host = var.proxy.external_host
  mode          = var.proxy.mode
  internal_host = var.proxy.internal_host

  authorization_flow  = data.authentik_flow.authorization[0].id
  invalidation_flow   = data.authentik_flow.invalidation[0].id
  authentication_flow = try(data.authentik_flow.authentication[0].id, null)

  internal_host_ssl_validation  = var.proxy.internal_host_ssl_validation
  intercept_header_auth         = var.proxy.intercept_header_auth
  cookie_domain                 = var.proxy.cookie_domain
  basic_auth_enabled            = var.proxy.basic_auth_enabled
  basic_auth_username_attribute = var.proxy.basic_auth_username_attribute
  basic_auth_password_attribute = var.proxy.basic_auth_password_attribute
  access_token_validity         = var.proxy.access_token_validity
  refresh_token_validity        = var.proxy.refresh_token_validity
  skip_path_regex               = var.proxy.skip_path_regex
  jwt_federation_providers      = var.proxy.jwt_federation_providers
  jwt_federation_sources        = var.proxy.jwt_federation_sources

  property_mappings = length(local.proxy_property_mappings) > 0 ? local.proxy_property_mappings : null
}

resource "authentik_provider_ldap" "this" {
  count = var.protocol == "ldap" ? 1 : 0

  name             = var.name
  base_dn          = var.ldap.base_dn
  bind_flow        = data.authentik_flow.bind[0].id
  unbind_flow      = data.authentik_flow.unbind[0].id
  bind_mode        = var.ldap.bind_mode
  search_mode      = var.ldap.search_mode
  certificate      = try(data.authentik_certificate_key_pair.ldap_cert[0].id, null)
  mfa_support      = var.ldap.mfa_support
  tls_server_name  = var.ldap.tls_server_name
  gid_start_number = var.ldap.gid_start_number
  uid_start_number = var.ldap.uid_start_number
}

resource "authentik_provider_radius" "this" {
  count = var.protocol == "radius" ? 1 : 0

  name            = var.name
  shared_secret   = var.radius.shared_secret
  client_networks = var.radius.client_networks
  certificate     = try(data.authentik_certificate_key_pair.radius_cert[0].id, null)
  mfa_support     = var.radius.mfa_support

  authorization_flow = data.authentik_flow.authorization[0].id
  invalidation_flow  = data.authentik_flow.invalidation[0].id

  property_mappings = length(local.radius_property_mappings) > 0 ? local.radius_property_mappings : null
}

resource "authentik_provider_ws_federation" "this" {
  count = var.protocol == "ws_federation" ? 1 : 0

  name      = var.name
  reply_url = var.ws_federation.reply_url
  wtrealm   = var.ws_federation.wtrealm

  authorization_flow  = data.authentik_flow.authorization[0].id
  invalidation_flow   = data.authentik_flow.invalidation[0].id
  authentication_flow = try(data.authentik_flow.authentication[0].id, null)

  assertion_valid_not_before      = var.ws_federation.assertion_valid_not_before
  assertion_valid_not_on_or_after = var.ws_federation.assertion_valid_not_on_or_after
  authn_context_class_ref_mapping = var.ws_federation.authn_context_class_ref_mapping
  digest_algorithm                = var.ws_federation.digest_algorithm
  signature_algorithm             = var.ws_federation.signature_algorithm
  signing_kp                      = try(data.authentik_certificate_key_pair.ws_fed_signing[0].id, null)
  encryption_kp                   = try(data.authentik_certificate_key_pair.ws_fed_encryption[0].id, null)
  name_id_mapping                 = var.ws_federation.name_id_mapping
  session_valid_not_on_or_after   = var.ws_federation.session_valid_not_on_or_after
  sign_assertion                  = var.ws_federation.sign_assertion
  sign_logout_request             = var.ws_federation.sign_logout_request

  property_mappings = length(local.ws_federation_property_mappings) > 0 ? local.ws_federation_property_mappings : null
}

resource "authentik_provider_microsoft_entra" "this" {
  count = var.protocol == "microsoft_entra" ? 1 : 0

  name          = var.name
  client_id     = var.microsoft_entra.client_id
  client_secret = var.microsoft_entra.client_secret
  tenant_id     = var.microsoft_entra.tenant_id

  dry_run                       = var.microsoft_entra.dry_run
  exclude_users_service_account = var.microsoft_entra.exclude_users_service_account
  filter_group                  = var.microsoft_entra.filter_group
  group_delete_action           = var.microsoft_entra.group_delete_action
  user_delete_action            = var.microsoft_entra.user_delete_action
  sync_page_size                = var.microsoft_entra.sync_page_size
  sync_page_timeout             = var.microsoft_entra.sync_page_timeout

  property_mappings       = length(local.entra_user_property_mappings) > 0 ? local.entra_user_property_mappings : null
  property_mappings_group = length(local.entra_group_property_mappings) > 0 ? local.entra_group_property_mappings : null
}

resource "authentik_provider_google_workspace" "this" {
  count = var.protocol == "google_workspace" ? 1 : 0

  name                          = var.name
  default_group_email_domain    = var.google_workspace.default_group_email_domain
  credentials                   = var.google_workspace.credentials == null ? null : jsonencode(var.google_workspace.credentials)
  delegated_subject             = var.google_workspace.delegated_subject
  dry_run                       = var.google_workspace.dry_run
  exclude_users_service_account = var.google_workspace.exclude_users_service_account
  filter_group                  = var.google_workspace.filter_group
  group_delete_action           = var.google_workspace.group_delete_action
  user_delete_action            = var.google_workspace.user_delete_action
  sync_page_size                = var.google_workspace.sync_page_size
  sync_page_timeout             = var.google_workspace.sync_page_timeout

  property_mappings       = length(local.google_workspace_user_property_mappings) > 0 ? local.google_workspace_user_property_mappings : null
  property_mappings_group = length(local.google_workspace_group_property_mappings) > 0 ? local.google_workspace_group_property_mappings : null
}

resource "authentik_provider_rac" "this" {
  count = var.protocol == "rac" ? 1 : 0

  name                = var.name
  authorization_flow  = data.authentik_flow.authorization[0].id
  authentication_flow = try(data.authentik_flow.authentication[0].id, null)
  connection_expiry   = var.rac.connection_expiry
  settings            = var.rac.settings == null ? null : jsonencode(var.rac.settings)

  property_mappings = length(local.rac_property_mappings) > 0 ? local.rac_property_mappings : null
}

resource "authentik_rac_endpoint" "this" {
  count = var.protocol == "rac" ? length(try(var.rac.endpoints, [])) : 0

  name                = var.rac.endpoints[count.index].name
  host                = var.rac.endpoints[count.index].host
  protocol            = var.rac.endpoints[count.index].protocol
  protocol_provider   = authentik_provider_rac.this[0].id
  maximum_connections = var.rac.endpoints[count.index].maximum_connections
  settings            = var.rac.endpoints[count.index].settings == null ? null : jsonencode(var.rac.endpoints[count.index].settings)
  property_mappings   = var.rac.endpoints[count.index].property_mappings
}

resource "authentik_provider_ssf" "this" {
  count = var.protocol == "ssf" ? 1 : 0

  name                     = var.name
  event_retention          = var.ssf.event_retention
  signing_key              = try(data.authentik_certificate_key_pair.ssf_signing[0].id, null)
  jwt_federation_providers = var.ssf.jwt_federation_providers
  push_verify_certificates = var.ssf.push_verify_certificates
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

  protocol_provider = local.provider_id

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
