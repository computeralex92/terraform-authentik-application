package main

import rego.v1

# Shared helpers for the Terraform policy suite.
#
# The suite is always run with `conftest test --combine` against the repository
# root, so `input` is a list of { "path": ..., "contents": ... } documents, one
# per parsed file — not only Terraform. The policies therefore filter to *.tf
# paths in `docs` below.
#
# conftest's HCL2 parser represents `block "label" { ... }` as
# contents.block = { "label": [ { ... } ] }. Expressions are rendered as opaque
# strings (e.g. `var.foo` becomes "${var.foo}"), which is why reference checks
# below are token searches rather than AST lookups.

# docs is every Terraform document in the (combined) input.
docs := [doc |
	is_array(input)
	some doc in input
	is_object(doc)
	endswith(object.get(doc, "path", ""), ".tf")
]

contents_of(doc) := object.get(doc, "contents", {})

# dir_of("examples/minimal/main.tf") == "examples/minimal"; the repository root
# is "" (paths are normalized to be relative without a leading "./").
dir_of(path) := concat("/", array.slice(parts, 0, count(parts) - 1)) if {
	parts := split(path, "/")
}

base_of(path) := parts[count(parts) - 1] if {
	parts := split(path, "/")
}

dir_display(dir) := "." if dir == ""
dir_display(dir) := dir if dir != ""

docs_in(dir) := [doc |
	some doc in docs
	dir_of(doc.path) == dir
]

module_dirs := {dir | some doc in docs; dir := dir_of(doc.path)}

file_in(dir, name) if {
	some doc in docs
	dir_of(doc.path) == dir
	base_of(doc.path) == name
}

# Block accessors. `kind` is the HCL block type.
blocks(doc, kind) := object.get(contents_of(doc), kind, {})

variable_blocks(doc) := blocks(doc, "variable")
output_blocks(doc) := blocks(doc, "output")
resource_blocks(doc) := blocks(doc, "resource")
data_blocks(doc) := blocks(doc, "data")
module_blocks(doc) := blocks(doc, "module")
provider_blocks(doc) := blocks(doc, "provider")
check_blocks(doc) := blocks(doc, "check")

# `locals` is a list of objects, one per locals block, mapping name -> value.
locals_blocks(doc) := object.get(contents_of(doc), "locals", [])

any_variables(dir) if {
	some doc in docs_in(dir)
	count(variable_blocks(doc)) > 0
}

any_outputs(dir) if {
	some doc in docs_in(dir)
	count(output_blocks(doc)) > 0
}

# Every string anywhere in a module's parsed trees. HCL expressions are opaque
# strings, so "is it referenced" is a token search over these. This can
# over-approximate (a mention inside a description counts as a reference) but
# never under-reports a real reference in the constructs this module uses.
strings_in_module(dir) := {s |
	some doc in docs_in(dir)
	walk(contents_of(doc), [_, value])
	is_string(value)
	s := value
}

token_pattern(token) := sprintf("\\b%s\\b", [replace(token, ".", "\\.")])

references(dir, token) if {
	some s in strings_in_module(dir)
	regex.match(token_pattern(token), s)
}
