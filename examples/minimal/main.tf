# Minimal example: a single OAuth2 application.
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

module "minimal" {
  source = "../../"

  name     = "Example App"
  slug     = "example-app"
  protocol = "oauth2"

  oauth2 = {
    client_secret         = var.client_secret
    allowed_redirect_uris = ["https://app.example.com/auth/callback"]
  }
}
