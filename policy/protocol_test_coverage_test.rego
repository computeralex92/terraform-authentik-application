package main

import rego.v1

# Unit tests for protocol_test_coverage.rego. Fixtures mirror conftest's
# combined input shape; only this policy's messages are asserted on, so the
# generic policies in the suite are ignored here.

enum_variables := {
	"path": "variables.tf",
	"contents": {"variable": {"protocol": [{
		"type": "${string}",
		"validation": [{
			"condition": "${contains([\"oauth2\", \"saml\"], var.protocol)}",
			"error_message": "bad protocol",
		}],
	}]}},
}

protocols(ext, labels) := {
	"path": sprintf("tests/protocols.%s", [ext]),
	"contents": {"run": {label: [{"variables": [{"protocol": label}]}] | some label in labels}},
}

validation(ext) := {
	"path": sprintf("tests/validation.%s", [ext]),
	"contents": {"run": {"negative": [{"variables": [{"protocol": "oauth2"}]}]}},
}

full_input := [
	enum_variables,
	protocols("tftest.hcl", {"oauth2", "saml"}),
	protocols("tofutest.hcl", {"oauth2", "saml"}),
	validation("tftest.hcl"),
	validation("tofutest.hcl"),
]

missing_protocol_input := [
	enum_variables,
	protocols("tftest.hcl", {"oauth2"}),
	protocols("tofutest.hcl", {"oauth2"}),
	validation("tftest.hcl"),
	validation("tofutest.hcl"),
]

label_drift_input := [
	enum_variables,
	protocols("tftest.hcl", {"oauth2", "saml"}),
	protocols("tofutest.hcl", {"oauth2", "saml", "extra"}),
	validation("tftest.hcl"),
	validation("tofutest.hcl"),
]

is_coverage_msg(msg) if contains(msg, "protocol suite must cover")
is_coverage_msg(msg) if contains(msg, "same run labels")

coverage_msgs(inp) := {msg |
	some msg in deny with input as inp
	is_coverage_msg(msg)
}

test_full_coverage_passes if {
	count(coverage_msgs(full_input)) == 0
}

test_missing_protocol_is_denied if {
	some msg in coverage_msgs(missing_protocol_input)
	contains(msg, "saml")
}

test_label_drift_is_denied if {
	some msg in coverage_msgs(label_drift_input)
	contains(msg, "extra")
}
