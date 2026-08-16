<!--
  Thank you for reporting! Please fill in this template so the bug can be triaged quickly.
  A plan/apply requires a live Authentik instance — that is expected, not a bug.
-->

## Describe the bug

<!-- What happened? What did you expect instead? -->

## Reproduction

<!-- A minimal module invocation that triggers the bug. -->

```hcl
module "app" {
  source   = "computeralex92/authentik-application/authentik"
  version  = "x.y.z"
  name     = "example"
  slug     = "example"
  protocol = "oauth2"

  oauth2 = {
    # ...
  }
}
```

## Environment

- Module version: <!-- e.g. v1.2.3, or commit SHA if on main -->
- Terraform / OpenTofu version: <!-- e.g. OpenTofu 1.12.x -->
- `goauthentik/authentik` provider version: <!-- e.g. 2026.5.1 -->
- Authentik server version: <!-- e.g. 2026.5 -->
- Protocol(s) in use: <!-- oauth2, saml, proxy, ldap, radius, ws_federation, microsoft_entra, google_workspace, rac, ssf, scim -->

## Error output

<!-- Paste the relevant plan/apply output or provider error, redacting any secrets. -->

## Expected behavior

## Additional context

<!-- Any other details that might help — logs, related issues, etc. -->
