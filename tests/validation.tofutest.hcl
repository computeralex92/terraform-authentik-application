# VALIDATION TEST SUITE — OpenTofu.
#
# Mirrors tests/validation.tftest.hcl. Asserts the input validation the module
# currently enforces, by expecting each bad input to fail at plan time. These
# runs never reach the provider, so the mock needs no resource data.
#
# A stray provider block that does not match `protocol` is deliberately NOT
# covered: the module does not reject it yet (it is silently ignored). That is
# a separate, out-of-scope change.

mock_provider "authentik" {}

run "protocol_block_mismatch" {
  command = plan

  variables {
    name     = "Bad app"
    slug     = "bad-app"
    protocol = "saml"
  }

  expect_failures = [var.protocol]
}

run "scim_requires_token" {
  command = plan

  variables {
    name     = "Bad SCIM app"
    slug     = "bad-scim-app"
    protocol = "oauth2"

    oauth2 = {
      client_secret = "oauth2-secret"
    }

    scim = {
      url = "https://scim.example.com/v2"
    }
  }

  expect_failures = [var.scim]
}

run "scim_oauth_requires_source" {
  command = plan

  variables {
    name     = "Bad SCIM app"
    slug     = "bad-scim-app"
    protocol = "oauth2"

    oauth2 = {
      client_secret = "oauth2-secret"
    }

    scim = {
      url       = "https://scim.example.com/v2"
      auth_mode = "oauth"
    }
  }

  expect_failures = [var.scim]
}

run "scim_invalid_auth_mode" {
  command = plan

  variables {
    name     = "Bad SCIM app"
    slug     = "bad-scim-app"
    protocol = "oauth2"

    oauth2 = {
      client_secret = "oauth2-secret"
    }

    scim = {
      url       = "https://scim.example.com/v2"
      token     = "scim-token"
      auth_mode = "magic"
    }
  }

  expect_failures = [var.scim]
}

run "rac_invalid_endpoint_protocol" {
  command = plan

  variables {
    name     = "Bad RAC app"
    slug     = "bad-rac-app"
    protocol = "rac"

    rac = {
      endpoints = [
        {
          name     = "bad-host"
          host     = "10.0.0.10"
          protocol = "telnet"
        },
      ]
    }
  }

  expect_failures = [var.rac]
}
