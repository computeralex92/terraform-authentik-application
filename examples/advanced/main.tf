# Advanced example: kitchen-sink configuration for every supported protocol.
#
# Demonstrates self-generated signing/encryption/verification key pairs (via
# the tls provider), inline property mappings, provider tuning options, SCIM
# backchannel provisioning, and application metadata.
#
# Configure the provider via AUTHENTIK_URL and AUTHENTIK_TOKEN environment
# variables (token from a superuser account).

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2026.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }
}

provider "authentik" {}

# Self-generated certificate key pairs, referenced by name from the providers
# below. The module looks key pairs up by name, so only the `name` matters.
locals {
  cert_names = toset(["signing", "encryption", "ldap", "radius"])
}

resource "tls_private_key" "app" {
  for_each    = local.cert_names
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "app" {
  for_each        = local.cert_names
  private_key_pem = tls_private_key.app[each.key].private_key_pem

  subject {
    common_name  = "advanced-${each.key}.example.com"
    organization = "Example"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "authentik_certificate_key_pair" "app" {
  for_each         = local.cert_names
  name             = "advanced-example-${each.key}"
  certificate_data = tls_self_signed_cert.app[each.key].cert_pem
  key_data         = tls_private_key.app[each.key].private_key_pem
}

# OAuth2 app with scopes, signing key, and tuning options.
module "vault" {
  source = "../../"

  base_url = "https://auth.example.com"

  name     = "Vault"
  slug     = "vault"
  protocol = "oauth2"

  group              = "Infrastructure"
  policy_engine_mode = "any"
  meta_launch_url    = "https://vault.example.com"
  meta_icon          = "https://vault.example.com/icon.svg"
  meta_description   = "Secrets management"
  meta_publisher     = "HashiCorp"
  open_in_new_tab    = true

  authorization_flow  = "default-provider-authorization-implicit-consent"
  invalidation_flow   = "default-provider-invalidation"
  authentication_flow = "default-authentication-flow"

  oauth2 = {
    client_id     = "vault"
    client_secret = var.oauth2_client_secret
    client_type   = "confidential"
    signing_key   = authentik_certificate_key_pair.app["signing"].name
    allowed_redirect_uris = [
      {
        matching_mode = "strict"
        url           = "https://vault.example.com/oidc/callback"
      },
    ]
    grant_types                = ["authorization_code", "refresh_token"]
    access_code_validity       = "minutes=5"
    access_token_validity      = "minutes=10"
    refresh_token_validity     = "days=30"
    refresh_token_threshold    = "minutes=5"
    include_claims_in_id_token = true
    issuer_mode                = "per_provider"
    logout_method              = "frontchannel"
    logout_uri                 = "https://vault.example.com"
    sub_mode                   = "user_uuid"
    scopes = [
      {
        name        = "Vault admin"
        scope_name  = "vault_admin"
        description = "Grant Vault admin permissions"
        expression  = "return {'role': 'admin'}"
      },
      {
        scope_name = "vault_reader"
        expression = "return {'role': 'reader'}"
      },
    ]
  }
}

# SAML app with signing/encryption keys, attribute mappings, and a SCIM
# backchannel provider for provisioning users/groups.
module "keycloak" {
  source = "../../"

  base_url = "https://auth.example.com"

  name     = "Keycloak"
  slug     = "keycloak"
  protocol = "saml"

  group = "Identity"

  saml = {
    acs_url              = "https://keycloak.example.com/realms/master/protocol/saml/clients/authentik"
    audience             = "https://keycloak.example.com/realms/master"
    sp_binding           = "post"
    sls_url              = "https://keycloak.example.com/realms/master/protocol/saml/clients/authentik/slo"
    sls_binding          = "redirect"
    signing_key          = authentik_certificate_key_pair.app["signing"].name
    encryption_key       = authentik_certificate_key_pair.app["encryption"].name
    verification_key     = authentik_certificate_key_pair.app["signing"].name
    digest_algorithm     = "http://www.w3.org/2001/04/xmlenc#sha256"
    signature_algorithm  = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    sign_assertion       = true
    sign_response        = true
    sign_logout_request  = true
    sign_logout_response = true
    issuer_override      = "https://auth.example.com/application/saml/keycloak/"
    default_relay_state  = "https://keycloak.example.com"
    attribute_mappings = [
      {
        saml_name     = "groups"
        friendly_name = "Groups"
        expression    = "return ','.join([group.name for group in request.user.ak_groups.all()])"
      },
    ]
  }

  scim = {
    url                = "https://keycloak.example.com/realms/master/protocol/scim/v2"
    token              = var.scim_token
    compatibility_mode = "default"
    dry_run            = true
    user_mappings = [
      {
        name       = "SCIM username"
        expression = "return request.user.username"
      },
    ]
    group_mappings = [
      {
        name       = "SCIM group name"
        expression = "return request.group.name"
      },
    ]
  }
}

# Reverse-proxy app with basic auth and skip-path configuration.
module "traefik" {
  source = "../../"

  name     = "Traefik forward auth"
  slug     = "traefik"
  protocol = "proxy"

  group = "Infrastructure"

  proxy = {
    external_host                 = "https://apps.example.com"
    mode                          = "forward_single"
    internal_host                 = "http://traefik:80"
    internal_host_ssl_validation  = false
    intercept_header_auth         = true
    cookie_domain                 = ".example.com"
    basic_auth_enabled            = true
    basic_auth_username_attribute = "username"
    basic_auth_password_attribute = "password"
    skip_path_regex               = "/healthz|/api/v1/status"
    access_token_validity         = "minutes=10"
    refresh_token_validity        = "days=30"
    scopes = [
      {
        scope_name = "traefik"
        expression = "return {'groups': [g.name for g in request.user.ak_groups.all()]}"
      },
    ]
  }
}

# LDAP app with a certificate and explicit bind/unbind flows.
module "openldap" {
  source = "../../"

  name     = "OpenLDAP"
  slug     = "openldap"
  protocol = "ldap"

  group = "Infrastructure"

  bind_flow   = "default-authentication-flow"
  unbind_flow = "default-provider-invalidation"

  ldap = {
    base_dn          = "dc=apps,dc=example,dc=com"
    bind_mode        = "cached"
    search_mode      = "direct"
    certificate      = authentik_certificate_key_pair.app["ldap"].name
    mfa_support      = true
    tls_server_name  = "ldap.example.com"
    gid_start_number = 4000
    uid_start_number = 2000
  }
}

# RADIUS app with a certificate and inline property mappings.
module "freeradius" {
  source = "../../"

  name     = "FreeRADIUS"
  slug     = "freeradius"
  protocol = "radius"

  group = "Network"

  radius = {
    shared_secret   = var.radius_shared_secret
    client_networks = "10.0.0.0/8, 192.168.0.0/16"
    certificate     = authentik_certificate_key_pair.app["radius"].name
    mfa_support     = true
    mappings = [
      {
        name       = "WLAN user type"
        expression = "return {'user_type': 'wifi'}"
      },
    ]
  }
}

# WS-Federation app with signing/encryption keys and attribute mappings.
module "wsfed" {
  source = "../../"

  name     = "WS-Federation app"
  slug     = "wsfed"
  protocol = "ws_federation"

  ws_federation = {
    reply_url                       = "https://apps.example.com/wsfed"
    wtrealm                         = "urn:example:apps"
    signing_key                     = authentik_certificate_key_pair.app["signing"].name
    encryption_key                  = authentik_certificate_key_pair.app["encryption"].name
    digest_algorithm                = "http://www.w3.org/2001/04/xmlenc#sha256"
    signature_algorithm             = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    sign_assertion                  = true
    sign_logout_request             = true
    assertion_valid_not_before      = "minutes=-5"
    assertion_valid_not_on_or_after = "minutes=5"
    session_valid_not_on_or_after   = "hours=8"
    attribute_mappings = [
      {
        saml_name  = "employee_id"
        expression = "return request.user.attributes.get('employee_id', '')"
      },
    ]
  }
}

# Microsoft Entra app (dry-run) with user and group mappings.
module "office365" {
  source = "../../"

  name     = "Office 365"
  slug     = "office365"
  protocol = "microsoft_entra"

  group = "Productivity"

  microsoft_entra = {
    client_id                     = "example-entra-client-id"
    client_secret                 = var.entra_client_secret
    tenant_id                     = var.entra_tenant_id
    dry_run                       = true
    exclude_users_service_account = true
    filter_group                  = "authentik-users"
    sync_page_size                = 50
    user_mappings = [
      {
        name       = "Entra user email"
        expression = "return request.user.email"
      },
    ]
    group_mappings = [
      {
        name       = "Entra group name"
        expression = "return request.group.name"
      },
    ]
  }
}

# Google Workspace provisioning provider with inline user/group mappings.
module "gws" {
  source = "../../"

  name     = "Google Workspace"
  slug     = "gws"
  protocol = "google_workspace"

  group = "Productivity"

  google_workspace = {
    default_group_email_domain    = "example.com"
    credentials                   = var.google_workspace_credentials
    delegated_subject             = "admin@example.com"
    dry_run                       = true
    exclude_users_service_account = true
    filter_group                  = "authentik-users"
    sync_page_size                = 50
    user_mappings = [
      {
        name       = "GWS user email"
        expression = "return request.user.email"
      },
    ]
    group_mappings = [
      {
        name       = "GWS group name"
        expression = "return request.group.name"
      },
    ]
  }
}

# RAC provider with inline mappings and two endpoints (RDP + SSH).
module "rac_app" {
  source = "../../"

  name     = "RAC access"
  slug     = "rac-app"
  protocol = "rac"

  group = "Infrastructure"

  rac = {
    connection_expiry = "minutes=30"
    settings = {
      "security" = "any"
    }
    mappings = [
      {
        name       = "RAC username"
        expression = "return request.user.username"
      },
    ]
    endpoints = [
      {
        name                = "windows-host"
        host                = "10.0.0.10"
        protocol            = "rdp"
        maximum_connections = 2
        settings = {
          "enable-wallpaper" = "true"
        }
      },
      {
        name     = "linux-host"
        host     = "10.0.0.20"
        protocol = "ssh"
      },
    ]
  }
}

# SSF provider streaming security events, signed with a key pair.
module "ssf_app" {
  source = "../../"

  name     = "Security events"
  slug     = "ssf-app"
  protocol = "ssf"

  group = "Security"

  ssf = {
    event_retention          = "days=30"
    signing_key              = authentik_certificate_key_pair.app["signing"].name
    push_verify_certificates = true
  }
}
