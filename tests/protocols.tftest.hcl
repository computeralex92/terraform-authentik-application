# PROTOCOL TEST SUITE — Terraform.
#
# Mirrors tests/protocols.tofutest.hcl, and exists separately because the two
# engines materialise mock values at different times: OpenTofu during plan,
# Terraform during apply. Both suites run plan-only; this twin adds
# `override_during = plan` to force plan-time values. See docs/adr/0001.
#
# Every run exercises the module's public interface through a mocked Authentik
# provider, so the suite runs offline with no live server. Assertions cross the
# interface (outputs). The handful that assert on resources are the three
# behaviours no output can expose: SCIM backchannel attachment, flow gating,
# and inline property-mapping counts.
#
# Provider resource ids are pinned to numeric strings on purpose:
# `authentik_application.protocol_provider` is a number while a provider id is
# a string, and the module relies on the implicit string -> number conversion.
# A generated (non-numeric) mock id fails that conversion at plan time. See
# docs/adr/0001 for the wider decision.

mock_provider "authentik" {
  override_during = plan

  mock_data "authentik_flow" {
    defaults = { id = "mocked-flow-id" }
  }

  mock_data "authentik_certificate_key_pair" {
    defaults = { id = "mocked-key-pair-id" }
  }

  mock_resource "authentik_provider_oauth2" { defaults = { id = "101" } }
  mock_resource "authentik_provider_saml" { defaults = { id = "102" } }
  mock_resource "authentik_provider_proxy" { defaults = { id = "103" } }
  mock_resource "authentik_provider_ldap" { defaults = { id = "104" } }
  mock_resource "authentik_provider_radius" { defaults = { id = "105" } }
  mock_resource "authentik_provider_ws_federation" { defaults = { id = "106" } }
  mock_resource "authentik_provider_microsoft_entra" { defaults = { id = "107" } }
  mock_resource "authentik_provider_google_workspace" { defaults = { id = "108" } }
  mock_resource "authentik_provider_rac" { defaults = { id = "109" } }
  mock_resource "authentik_provider_ssf" { defaults = { id = "110" } }
  mock_resource "authentik_provider_scim" { defaults = { id = "111" } }

  # The application's computed ids are pinned so the interface assertions on
  # application_uuid resolve at plan time under Terraform.
  mock_resource "authentik_application" {
    defaults = {
      id   = "app-id"
      uuid = "app-uuid"
    }
  }
}

run "oauth2" {
  command = plan

  variables {
    name     = "OAuth2 app"
    slug     = "oauth2-app"
    protocol = "oauth2"

    oauth2 = {
      client_secret         = "oauth2-secret"
      allowed_redirect_uris = ["https://oauth2.example.com/callback"]
      scopes = [
        {
          scope_name = "test"
          expression = "return {}"
        },
      ]
    }
  }

  assert {
    condition     = output.oauth2 != null
    error_message = "oauth2 output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = output.provider_id != null
    error_message = "provider_id must be populated"
  }

  assert {
    condition     = output.application_uuid != null
    error_message = "application_uuid must be populated"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_scope.oauth2) == 1
    error_message = "oauth2 scope mapping must be created"
  }
}

run "saml" {
  command = plan

  variables {
    name     = "SAML app"
    slug     = "saml-app"
    protocol = "saml"

    saml = {
      acs_url     = "https://saml.example.com/acs"
      signing_key = "test-signing-key"
      attribute_mappings = [
        {
          saml_name  = "email"
          expression = "return request.user.email"
        },
      ]
    }
  }

  assert {
    condition     = output.saml != null
    error_message = "saml output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_saml.saml) == 1
    error_message = "saml attribute mapping must be created"
  }
}

run "proxy" {
  command = plan

  variables {
    name     = "Proxy app"
    slug     = "proxy-app"
    protocol = "proxy"

    proxy = {
      external_host = "https://proxy.example.com"
      scopes = [
        {
          scope_name = "test"
          expression = "return {}"
        },
      ]
    }
  }

  assert {
    condition     = output.proxy != null
    error_message = "proxy output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_scope.proxy) == 1
    error_message = "proxy scope mapping must be created"
  }
}

run "ldap" {
  command = plan

  variables {
    name     = "LDAP app"
    slug     = "ldap-app"
    protocol = "ldap"

    ldap = {
      base_dn = "dc=example,dc=com"
    }
  }

  assert {
    condition     = output.ldap != null
    error_message = "ldap output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  # Flow gating: LDAP uses bind/unbind flows and must not read the invalidation flow.
  assert {
    condition     = length(data.authentik_flow.invalidation) == 0
    error_message = "ldap must not read an invalidation flow"
  }

  assert {
    condition     = length(data.authentik_flow.bind) == 1
    error_message = "ldap must read a bind flow"
  }
}

run "radius" {
  command = plan

  variables {
    name     = "RADIUS app"
    slug     = "radius-app"
    protocol = "radius"

    radius = {
      shared_secret = "radius-secret"
      mappings = [
        {
          name       = "radius-attr"
          expression = "return {}"
        },
      ]
    }
  }

  assert {
    condition     = output.radius != null
    error_message = "radius output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_radius.this) == 1
    error_message = "radius mapping must be created"
  }
}

run "ws_federation" {
  command = plan

  variables {
    name     = "WS-Federation app"
    slug     = "wsfed-app"
    protocol = "ws_federation"

    ws_federation = {
      reply_url = "https://wsfed.example.com/"
      wtrealm   = "urn:example:wsfed"
      attribute_mappings = [
        {
          saml_name  = "email"
          expression = "return request.user.email"
        },
      ]
    }
  }

  assert {
    condition     = output.ws_federation != null
    error_message = "ws_federation output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_saml.ws_federation) == 1
    error_message = "ws_federation attribute mapping must be created"
  }
}

run "microsoft_entra" {
  command = plan

  variables {
    name     = "Entra app"
    slug     = "entra-app"
    protocol = "microsoft_entra"

    microsoft_entra = {
      client_id     = "entra-client-id"
      client_secret = "entra-client-secret"
      tenant_id     = "entra-tenant-id"
      user_mappings = [
        {
          name       = "entra-user"
          expression = "return {}"
        },
      ]
      group_mappings = [
        {
          name       = "entra-group"
          expression = "return {}"
        },
      ]
    }
  }

  assert {
    condition     = output.microsoft_entra != null
    error_message = "microsoft_entra output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_microsoft_entra.user) == 1
    error_message = "microsoft_entra user mapping must be created"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_microsoft_entra.group) == 1
    error_message = "microsoft_entra group mapping must be created"
  }
}

run "google_workspace" {
  command = plan

  variables {
    name     = "Google Workspace app"
    slug     = "gws-app"
    protocol = "google_workspace"

    google_workspace = {
      default_group_email_domain = "example.com"
      user_mappings = [
        {
          name       = "gws-user"
          expression = "return {}"
        },
      ]
      group_mappings = [
        {
          name       = "gws-group"
          expression = "return {}"
        },
      ]
    }
  }

  assert {
    condition     = output.google_workspace != null
    error_message = "google_workspace output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_google_workspace.user) == 1
    error_message = "google_workspace user mapping must be created"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_google_workspace.group) == 1
    error_message = "google_workspace group mapping must be created"
  }
}

run "rac" {
  command = plan

  variables {
    name     = "RAC app"
    slug     = "rac-app"
    protocol = "rac"

    rac = {
      mappings = [
        {
          name       = "rac-mapping"
          expression = "return {}"
        },
      ]
      endpoints = [
        {
          name     = "windows-host"
          host     = "10.0.0.10"
          protocol = "rdp"
        },
      ]
    }
  }

  assert {
    condition     = output.rac != null
    error_message = "rac output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_rac.this) == 1
    error_message = "rac mapping must be created"
  }

  assert {
    condition     = length(authentik_rac_endpoint.this) == 1
    error_message = "rac endpoint must be created"
  }
}

run "ssf" {
  command = plan

  variables {
    name     = "SSF app"
    slug     = "ssf-app"
    protocol = "ssf"

    ssf = {
      event_retention = "days=30"
      signing_key     = "test-signing-key"
    }
  }

  assert {
    condition     = output.ssf != null
    error_message = "ssf output must be populated"
  }

  assert {
    condition = length([
      for o in [
        output.oauth2, output.saml, output.proxy, output.ldap, output.radius,
        output.ws_federation, output.microsoft_entra, output.google_workspace,
        output.rac, output.ssf,
      ] : o if o != null
    ]) == 1
    error_message = "exactly one protocol output must be non-null"
  }
}

run "scim_backchannel" {
  command = plan

  variables {
    name     = "SCIM app"
    slug     = "scim-app"
    protocol = "oauth2"

    oauth2 = {
      client_secret = "oauth2-secret"
    }

    scim = {
      url   = "https://scim.example.com/v2"
      token = "scim-token"
      user_mappings = [
        {
          name       = "scim-user"
          expression = "return {}"
        },
      ]
      group_mappings = [
        {
          name       = "scim-group"
          expression = "return {}"
        },
      ]
    }
  }

  assert {
    condition     = output.scim != null
    error_message = "scim output must be populated when configured"
  }

  assert {
    condition     = length(authentik_application.this.backchannel_providers) == 1
    error_message = "SCIM provider must attach as a backchannel provider"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_scim.user) == 1
    error_message = "scim user mapping must be created"
  }

  assert {
    condition     = length(authentik_property_mapping_provider_scim.group) == 1
    error_message = "scim group mapping must be created"
  }
}
