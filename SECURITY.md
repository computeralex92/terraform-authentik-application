# Security Policy

## Reporting a Vulnerability

This is a community Terraform module. If you find a security issue, please report it privately rather than opening a public issue.

**How to report:**

1. Open a **private security advisory** at: <https://github.com/computeralex92/terraform-authentik-application/security/advisories/new>
2. Or email the maintainer directly (see the repository owner profile for contact details).

Please include:

- A description of the issue and its impact
- The affected version(s) / commit(s)
- Steps to reproduce (where applicable)
- Any suggested fix (optional)

You will receive an acknowledgement within a few business days. Please do not disclose the issue publicly until it has been triaged and (where relevant) addressed.

## Supported Versions

Only the latest tagged release (semver) is actively maintained. Older versions may receive security fixes on a best-effort basis. The module's provider requirement is a lower bound (`>= 2026.4.0`) — always pin the provider version to the Authentik server you target, per the README.

## Security Scope

This module wraps the `goauthentik/authentik` Terraform provider. Security-relevant practices for **users** of this module:

- Authenticate the provider via `AUTHENTIK_URL` / `AUTHENTIK_TOKEN` environment variables; never hardcode tokens in code or state.
- Secrets (OAuth client secrets, RADIUS shared secrets, Entra client secrets, SCIM tokens) are stored in Terraform state. Restrict access to state files and backends.
- The module runs with the privileges of the Authentik token used; scope the token to a superuser account with the least access required for your workflow.
- Treat the module's outputs marked `sensitive = true` as sensitive (they are not shown in plan/apply output).

## Security Checks in Place

- GitHub **Secret Scanning** and **Push Protection** on this repository
- **Dependabot alerts** for vulnerable dependencies
- **Renovate** for automated dependency updates (grouped PRs)
- CI runs `terraform fmt`, `terraform validate`, `tflint`, and pre-commit hooks on every PR
- GitHub Actions are **pinned to commit SHAs**

## Acknowledgment

We aim to respond to and resolve security reports in a timely manner.
