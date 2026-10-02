package main

import rego.v1

# Custom policy (not a TFLint port): the module's protocol test suites must
# cover every protocol in the `protocol` enum, in both engines, and the
# Terraform and OpenTofu suites must declare the same run labels.
#
# conftest parses *.tftest.hcl and *.tofutest.hcl with the HCL2 parser, so a run
# block appears in the raw input as:
#   contents.run = { "<label>": [ { "variables": [ { "protocol": "oauth2" } ] } ] }
# The shared `docs` helper filters to *.tf, so test documents are read from
# `input` directly here rather than through `docs`.

is_test_path(path) if endswith(path, ".tftest.hcl")
is_test_path(path) if endswith(path, ".tofutest.hcl")

suite_file_docs := [doc |
	is_array(input)
	some doc in input
	is_object(doc)
	is_test_path(object.get(doc, "path", ""))
]

# Files belonging to a suite, e.g. suite_docs("protocols", "tftest.hcl").
suite_docs(prefix, ext) := [doc |
	some doc in suite_file_docs
	endswith(object.get(doc, "path", ""), sprintf("%s.%s", [prefix, ext]))
]

run_labels(prefix, ext) := {label |
	some doc in suite_docs(prefix, ext)
	some label in object.keys(object.get(contents_of(doc), "run", {}))
}

covered_protocols(prefix, ext) := {p |
	some doc in suite_docs(prefix, ext)
	runs := object.get(contents_of(doc), "run", {})
	some label in object.keys(runs)
	some body in runs[label]
	some vars in object.get(body, "variables", [])
	p := object.get(vars, "protocol", "")
	p != ""
}

# The protocol enum is the `contains([...], var.protocol)` validation on the
# `protocol` variable. conftest renders the expression as an opaque string, so
# the literals are recovered from it; the digit-inclusive class matters because
# one protocol is `oauth2`.
protocol_enum := {p |
	some doc in docs
	object.get(doc, "path", "") == "variables.tf"
	some body in object.get(variable_blocks(doc), "protocol", [])
	some rule in object.get(body, "validation", [])
	cond := object.get(rule, "condition", "")
	contains(cond, "contains([")
	contains(cond, "var.protocol")
	some match in regex.find_all_string_submatch_n("\"([a-z0-9_]+)\"", cond, -1)
	p := match[1]
}

engines := {
	"tftest.hcl": "Terraform",
	"tofutest.hcl": "OpenTofu",
}

deny contains msg if {
	some ext, name in engines
	missing := protocol_enum - covered_protocols("protocols", ext)
	count(missing) > 0
	msg := sprintf(
		"tests/protocols.%s: %s protocol suite must cover every protocol in the `protocol` enum; missing run(s) for: %s",
		[ext, name, concat(", ", sort([p | some p in missing]))],
	)
}

deny contains msg if {
	some prefix in ["protocols", "validation"]
	tf := run_labels(prefix, "tftest.hcl")
	tofu := run_labels(prefix, "tofutest.hcl")
	diff := (tf - tofu) | (tofu - tf)
	count(diff) > 0
	msg := sprintf(
		"tests/%s.{tftest,tofutest}.hcl: Terraform and OpenTofu suites must declare the same run labels; they differ on: %s",
		[prefix, concat(", ", sort([l | some l in diff]))],
	)
}
