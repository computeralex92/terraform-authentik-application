# Complete example: OAuth2 app, SAML app with SCIM backchannel, custom property mappings.
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
  }
}

provider "authentik" {}

module "authentik_apps" {
  source = "../../"

  base_url = "https://auth.example.com"

  default_flows = {
    authorization = "default-provider-authorization-implicit-consent"
    invalidation  = "default-provider-invalidation"
  }

  applications = {
    grafana = {
      name            = "Grafana"
      slug            = "grafana"
      protocol        = "oauth2"
      meta_launch_url = "https://grafana.example.com"
      meta_icon       = "https://grafana.example.com/icon.svg"
      open_in_new_tab = true

      oauth2 = {
        client_id             = "grafana"
        client_secret         = var.grafana_client_secret
        allowed_redirect_uris = ["https://grafana.example.com/login/generic_oauth"]
        scopes = [
          {
            scope_name = "grafana"
            expression = <<-EOF
              return {
                "is_admin": False,
              }
            EOF
          },
        ]
      }
    }

    jenkins = {
      name            = "Jenkins"
      slug            = "jenkins"
      protocol        = "saml"
      meta_launch_url = "https://jenkins.example.com"

      saml = {
        acs_url    = "https://jenkins.example.com/securityRealm/finishLogin"
        audience   = "https://jenkins.example.com"
        sp_binding = "post"
      }

      scim = {
        url   = "https://jenkins.example.com/scim/v2"
        token = var.jenkins_scim_token
      }
    }
  }
}
