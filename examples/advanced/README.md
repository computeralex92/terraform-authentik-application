# Advanced example

Kitchen-sink configuration that exercises every option the module exposes:
self-generated signing/encryption/verification key pairs (via the `tls`
provider), inline property mappings, provider tuning, RAC endpoints, and a
SCIM backchannel provider.

## What it does

- Generates ECDSA P-384 key pairs with the `tls` provider and imports them as
  Authentik certificate key pairs, referenced by name from the providers
- One application per protocol, each tuned further than in
  [`examples/complete`](../complete/README.md):

| Module | Protocol | Highlights |
|---|---|---|
| `vault` | OAuth2 | Signing key, token exchange grants, scopes, token validity tuning |
| `keycloak` | SAML | Signing/encryption/verification keys, attribute mapping, SCIM backchannel |
| `traefik` | Proxy | Basic auth, skip-path regex, scopes |
| `openldap` | LDAP | Certificate, cached bind, MFA support, explicit flows |
| `freeradius` | RADIUS | Certificate, MFA support, inline mapping |
| `wsfed` | WS-Federation | Signing/encryption keys, attribute mapping (Enterprise) |
| `office365` | Microsoft Entra | Dry-run, user/group mappings (Enterprise) |
| `gws` | Google Workspace | Dry-run, delegated subject, user/group mappings (Enterprise) |
| `rac_app` | RAC | Inline mappings, RDP + SSH endpoints (Enterprise) |
| `ssf_app` | SSF | Signing key, event retention (Enterprise) |

## Prerequisites

- A reachable Authentik instance and a superuser token
- `AUTHENTIK_URL` and `AUTHENTIK_TOKEN` set in the environment
- An [Authentik Enterprise license](https://goauthentik.io/pricing/) for the
  WS-Federation, Microsoft Entra, Google Workspace, RAC, and SSF apps
- OpenTofu (or Terraform >= 1.9)

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in secrets
tofu init
tofu apply
```

## Files

- `main.tf` — certificate generation, one module block per application
- `variables.tf` — sensitive inputs for the apps
- `outputs.tf` — client IDs, metadata URL, SCIM token, shared secrets, RAC endpoints
- `terraform.tfvars.example` — template for `terraform.tfvars`

See the [provider reference](../docs/protocols.md) for a description of every
block, and the [main README](../README.md) for the full interface.
