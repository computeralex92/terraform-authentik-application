# Terragrunt

This is a plain Terraform module, so it can be consumed from [Terragrunt](https://terragrunt.gruntwork.io) just like any other module: point a `terragrunt.hcl` at the module source and pass the inputs. Terragrunt runs the module with the underlying `terraform` or `tofu` binary, so the module itself needs no Terragrunt-specific files. Use one `terragrunt.hcl` (directory) per application:

```hcl
# terragrunt.hcl (one per application, in the consuming repo)
terraform {
  source = "git::https://github.com/computeralex92/terraform-authentik-application.git?ref=v1.0.0"

  # optional: use OpenTofu instead of Terraform
  # terraform_binary = "tofu"
}

inputs = {
  base_url = "https://auth.example.com"

  name     = "Grafana"
  slug     = "grafana"
  protocol = "oauth2"

  oauth2 = {
    client_id             = "grafana"
    allowed_redirect_uris = ["https://grafana.example.com/login/generic_oauth"]
  }
}
```

Notes for Terragrunt users:

- Auth is unchanged: set `AUTHENTIK_URL` and `AUTHENTIK_TOKEN` in the environment — Terragrunt passes them through to OpenTofu/Terraform.
- The module's `required_version` and provider constraints are enforced by the underlying binary; pin the provider to the Authentik server version as usual.
- Terragrunt fetches the module source into its `.terragrunt-cache`; the module is stateless, so running from cache needs no extra hooks or files.
- The module commits no `.terraform.lock.hcl`; the consuming repo manages its own lock files (`terraform.lock.hcl` and, for newer Terragrunt, `terragrunt.lock.hcl`) as normal.
