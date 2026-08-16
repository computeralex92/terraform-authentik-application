# Minimal example

A single OAuth2 application — the bare minimum to get started with the module.

## What it does

- Creates one Authentik OAuth2 application (`module.minimal`)
- Outputs the `application_id` and the OAuth2 `client_id`

## Prerequisites

- A reachable Authentik instance and a superuser token
- `AUTHENTIK_URL` and `AUTHENTIK_TOKEN` set in the environment
- OpenTofu (or Terraform >= 1.9)

## Running it

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in the client secret
tofu init
tofu apply
```

The created application shows up in the Authentik admin UI under
**Applications**. See the [main README](../README.md) for the full interface
and the [provider reference](../docs/protocols.md) for all available inputs.

## Files

- `main.tf` — provider + module invocation
- `variables.tf` — `client_secret` input
- `outputs.tf` — `application_id`, `client_id`
- `terraform.tfvars.example` — template for `terraform.tfvars`
