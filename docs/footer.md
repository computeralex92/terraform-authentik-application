## Notes & Gotchas

- `plan`/`apply` require a live, reachable Authentik instance — there is no offline path. `terraform validate` does not need one.
- Flow slugs in `authorization_flow`, `invalidation_flow`, and `authentication_flow` are resolved via the `authentik_flow` data source and must exist before `plan`.
- Authentik's API is eventually consistent and resources depend on each other (provider → application, property mappings → provider). These ordering constraints are captured by implicit references; do not remove them.
- Property mapping names must be unique in Authentik. Inline mappings default their name to `scope_name`/`saml_name`; set an explicit `name` if you need to disambiguate.
- The SAML `metadata_url` output is only populated when `base_url` is set.
- Secrets (OAuth `client_secret`, SCIM `token`) are managed in state. Restrict access to state files and never log the `applications` output.

## Development

Keep the generated tables in `README.md` in sync after changing code:

```bash
terraform-docs markdown .        # regenerate README.md
terraform fmt -recursive
terraform validate
tflint
prek run --all-files            # everything above, plus trailing-whitespace/EOF/secret checks
```
