# Engine-specific test files for Terraform and OpenTofu

The module ships two native test suites, one per engine — `*.tftest.hcl` for
Terraform and `*.tofutest.hcl` for OpenTofu — rather than a single shared suite.
The engines materialise mocked provider values at different times: OpenTofu
during `plan`, Terraform during `apply`. The flag that would align them
(`override_during = plan`) requires Terraform 1.11+ and is rejected outright by
OpenTofu, so a single file cannot pass under both. OpenTofu gives a same-base
`.tofutest.hcl` precedence over `.tftest.hcl`, and Terraform ignores
`.tofutest.hcl`, so the pair never runs twice on one engine. Both suites are
plan-only; the Terraform file adds `override_during = plan`.

## Considered Options

- **One shared suite** — impossible for the reason above.
- **OpenTofu only** — rejected: the module declares support for Terraform too,
  and the suite is cheap to mirror.
- **`command = apply` for the Terraform file (no `override_during`)** — avoids
  the 1.11 requirement but is slower and semantically differs from the
  OpenTofu plan-only suite. Not chosen.

## Consequences

- Assertions are duplicated between the two suites. A `conftest` policy
  (`protocol_test_coverage.rego`) requires identical run labels, so the copies
  cannot drift apart silently.
- CI runs the suite under both engines across the provider floor/latest matrix.
  The local pre-commit hook runs OpenTofu only: running both there would force a
  re-init between engines, since they resolve the provider from different
  registries. (`.terraform.lock.hcl` is gitignored, so this is a speed and
  convenience trade-off, not a correctness one.)
- Terraform's mock provider needs the application's computed ids pinned
  (`mock_resource "authentik_application"`) so the `application_uuid` assertion
  resolves at plan time; OpenTofu does not, but shares the pins for parity.
