# Complete example

One application per supported protocol — the best starting point for
catalog-style usage: each app is a separate module invocation, mirroring how
the module would be consumed from a real application catalog.

## What it does

Creates one Authentik application per protocol:

| Module | Protocol | Notes |
|---|---|---|
| `grafana` | OAuth2 | With an inline scope mapping |
| `jenkins` | SAML | With a SCIM backchannel provider |
| `traefik` | Proxy | Forward-auth mode with a cookie domain |
| `openldap` | LDAP | Minimal config |
| `freeradius` | RADIUS | Restricted client networks |
| `wsfed_app` | WS-Federation | Enterprise only |
| `office365` | Microsoft Entra | Enterprise only, `dry_run = true` |
| `gws` | Google Workspace | Enterprise only, `dry_run = true` |
| `rac_app` | RAC | Single RDP endpoint |
| `ssf_app` | SSF | Enterprise only |

Outputs expose the client IDs, SAML metadata URL, SCIM token, and shared
secrets for each app.

## Prerequisites

- A reachable Authentik instance and a superuser token
- `AUTHENTIK_URL` and `AUTHENTIK_TOKEN` set in the environment
- An [Authentik Enterprise license](https://goauthentik.io/pricing/) for the
  WS-Federation, Microsoft Entra, Google Workspace, RAC, and SSF apps — remove
  those module blocks if you only run the open-source edition
- OpenTofu (or Terraform >= 1.9)

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in secrets
tofu init
tofu apply
```

## Files

- `main.tf` — one module block per application
- `variables.tf` — sensitive inputs for the apps
- `outputs.tf` — client IDs, metadata URL, SCIM token, secrets
- `terraform.tfvars.example` — template for `terraform.tfvars`

See the [provider reference](../docs/protocols.md) for a description of every
block, and the [main README](../README.md) for the full interface.
