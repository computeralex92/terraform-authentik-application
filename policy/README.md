# Terraform policies (conftest)

Terraform linting is handled by [conftest](https://www.conftest.dev) (Open Policy
Agent / Rego) instead of TFLint. The policies in this directory are a port of
the TFLint built-in rules this module enabled. conftest is run against the
repository root with `--combine`, so cross-file policies see each module
directory as a whole; the policies themselves filter out everything that is not
`*.tf`.

| Policy | Replaces | Checks |
| --- | --- | --- |
| `naming_convention.rego` | `terraform_naming_convention` | `snake_case` for resources, variables, outputs, locals, modules, data sources, checks |
| `typed_variables.rego` | `terraform_typed_variables` | every `variable` declares a `type` |
| `unused_declarations.rego` | `terraform_unused_declarations` | variables, locals, data sources, and provider aliases that are declared but never referenced |
| `standard_module_structure.rego` | `terraform_standard_module_structure` | `main.tf`/`variables.tf`/`outputs.tf` exist; variables and outputs live in the matching file |

## Rules that are not ported

`terraform_deprecated_interpolation` and `terraform_deprecated_index` cannot be
ported faithfully. conftest's HCL2 parser normalizes every expression to a
`${...}` string, so `type = string` and `type = "${string}"` are
indistinguishable, and the parser does not preserve enough structure to detect
deprecated index syntax. `tofu fmt` catches most of these in practice.

## Usage

```bash
# Apply the policies (what the conftest_terraform pre-commit hook runs).
conftest test --policy policy --combine --no-color --ignore '[.]terraform' .
conftest verify --policy policy      # policy unit tests (policy/*_test.rego)
conftest fmt --check policy          # check Rego formatting
```

Requires `conftest` on `PATH` (`brew install conftest`). CI installs a pinned,
checksum-verified release (see `.github/workflows/validate.yml`).
