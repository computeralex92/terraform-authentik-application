# Complete example: one app per supported protocol — OAuth2, SAML with SCIM
# backchannel, proxy, LDAP, RADIUS, WS-Federation, Microsoft Entra, Google
# Workspace, RAC, and SSF.
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

module "grafana" {
  source = "../../"

  base_url = "https://auth.example.com"

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

module "jenkins" {
  source = "../../"

  base_url = "https://auth.example.com"

  name     = "Jenkins"
  slug     = "jenkins"
  protocol = "saml"

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

module "traefik" {
  source = "../../"

  name     = "Traefik forward auth"
  slug     = "traefik"
  protocol = "proxy"

  proxy = {
    external_host = "https://apps.example.com"
    mode          = "forward_single"
    internal_host = "http://traefik:80"
    cookie_domain = ".example.com"
  }
}

module "openldap" {
  source = "../../"

  name     = "OpenLDAP"
  slug     = "openldap"
  protocol = "ldap"

  ldap = {
    base_dn = "dc=apps,dc=example,dc=com"
  }
}

module "freeradius" {
  source = "../../"

  name     = "FreeRADIUS"
  slug     = "freeradius"
  protocol = "radius"

  radius = {
    shared_secret   = var.radius_shared_secret
    client_networks = "10.0.0.0/8, 192.168.0.0/16"
  }
}

module "wsfed_app" {
  source = "../../"

  name     = "WS-Federation app"
  slug     = "wsfed-app"
  protocol = "ws_federation"

  ws_federation = {
    reply_url = "https://apps.example.com/wsfed"
    wtrealm   = "urn:example:apps"
  }
}

module "office365" {
  source = "../../"

  name     = "Office 365"
  slug     = "office365"
  protocol = "microsoft_entra"

  microsoft_entra = {
    client_id     = "example-entra-client-id"
    client_secret = var.entra_client_secret
    tenant_id     = var.entra_tenant_id
    dry_run       = true
  }
}

module "gws" {
  source = "../../"

  name     = "Google Workspace"
  slug     = "gws"
  protocol = "google_workspace"

  google_workspace = {
    default_group_email_domain = "example.com"
    credentials                = var.google_workspace_credentials
    dry_run                    = true
  }
}

module "rac_app" {
  source = "../../"

  name     = "RAC access"
  slug     = "rac-app"
  protocol = "rac"

  rac = {
    connection_expiry = "minutes=30"
    endpoints = [
      {
        name     = "windows-host"
        host     = "10.0.0.10"
        protocol = "rdp"
      },
    ]
  }
}

module "ssf_app" {
  source = "../../"

  name     = "Security events"
  slug     = "ssf-app"
  protocol = "ssf"

  ssf = {
    event_retention = "days=30"
  }
}
