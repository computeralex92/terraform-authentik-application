package main

import rego.v1

# Unit tests for the Terraform policies, run with `conftest verify`.
#
# Each fixture mirrors conftest's combined input shape: a list of
# { "path": ..., "contents": ... } documents, where contents matches the
# HCL2 parser's representation of a module directory.

valid_module := [
	{"path": "main.tf", "contents": {"resource": {"null_resource": {"this": [{}]}}}},
	{"path": "variables.tf", "contents": {"variable": {"used": [{"type": "${string}"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "${var.used}"}]}}},
]

cross_file_module := [
	{"path": "main.tf", "contents": {"resource": {"null_resource": {"this": [{"triggers": {"x": "${var.used}"}}]}}}},
	{"path": "variables.tf", "contents": {"variable": {"used": [{"type": "${string}"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "static"}]}}},
]

untyped_variable_module := [
	{"path": "main.tf", "contents": {}},
	{"path": "variables.tf", "contents": {"variable": {"bad_name": [{"default": "x"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "${var.bad_name}"}]}}},
]

badly_named_variable_module := [
	{"path": "main.tf", "contents": {}},
	{"path": "variables.tf", "contents": {"variable": {"badName": [{"type": "${string}"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "${var.badName}"}]}}},
]

unused_variable_module := [
	{"path": "main.tf", "contents": {}},
	{"path": "variables.tf", "contents": {"variable": {"unused": [{"type": "${string}"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "static"}]}}},
]

unused_local_module := [
	{"path": "main.tf", "contents": {"locals": [{"unused": "x"}]}},
	{"path": "variables.tf", "contents": {}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "static"}]}}},
]

unused_data_source_module := [
	{"path": "main.tf", "contents": {"data": {"null_data_source": {"unused": [{}]}}}},
	{"path": "variables.tf", "contents": {}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "static"}]}}},
]

missing_main_module := [
	{"path": "variables.tf", "contents": {"variable": {"used": [{"type": "${string}"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "${var.used}"}]}}},
]

misplaced_variable_module := [
	{"path": "main.tf", "contents": {"variable": {"used": [{"type": "${string}"}]}}},
	{"path": "outputs.tf", "contents": {"output": {"out": [{"value": "${var.used}"}]}}},
]

test_valid_module_passes if {
	msgs := deny with input as valid_module
	count(msgs) == 0
}

test_cross_file_reference_counts_as_use if {
	msgs := deny with input as cross_file_module
	count(msgs) == 0
}

test_untyped_variable_is_denied if {
	some msg in deny with input as untyped_variable_module
	contains(msg, "has no type")
}

test_badly_named_variable_is_denied if {
	some msg in deny with input as badly_named_variable_module
	contains(msg, "variable name `badName`")
}

test_unused_variable_is_denied if {
	some msg in deny with input as unused_variable_module
	contains(msg, `variable "unused" is declared but not used`)
}

test_unused_local_is_denied if {
	some msg in deny with input as unused_local_module
	contains(msg, "local.unused is declared but not used")
}

test_unused_data_source_is_denied if {
	some msg in deny with input as unused_data_source_module
	contains(msg, `data "null_data_source" "unused" is declared but not used`)
}

test_missing_main_file_is_denied if {
	some msg in deny with input as missing_main_module
	contains(msg, "should include a main.tf file")
}

test_variable_in_main_is_denied if {
	some msg in deny with input as misplaced_variable_module
	contains(msg, "should be moved from main.tf to variables.tf")
}
