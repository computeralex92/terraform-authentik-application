package main

import rego.v1

# Port of TFLint's terraform_unused_declarations rule, which reports variables,
# data sources, locals, and provider aliases that are declared but never used.
#
# References are detected by searching the module's expression strings for the
# declaration's address (var.foo, local.foo, data.type.name, provider_alias),
# so the policy evaluates the whole module directory at once (conftest
# --combine), not a single file.

deny contains msg if {
	some doc in docs
	some name in object.keys(variable_blocks(doc))
	not references(dir_of(doc.path), sprintf("var.%s", [name]))
	msg := sprintf(`%s: variable "%s" is declared but not used (terraform_unused_declarations)`, [doc.path, name])
}

deny contains msg if {
	some doc in docs
	some block in locals_blocks(doc)
	some name in object.keys(block)
	not references(dir_of(doc.path), sprintf("local.%s", [name]))
	msg := sprintf("%s: local.%s is declared but not used (terraform_unused_declarations)", [doc.path, name])
}

deny contains msg if {
	some doc in docs
	some dtype, names in data_blocks(doc)
	some name in object.keys(names)
	not references(dir_of(doc.path), sprintf("data.%s.%s", [dtype, name]))
	msg := sprintf(`%s: data "%s" "%s" is declared but not used (terraform_unused_declarations)`, [doc.path, dtype, name])
}

# Provider aliases are only checked when the alias is a literal, matching
# TFLint (an alias computed from an expression cannot be resolved statically).
deny contains msg if {
	some doc in docs
	some ptype, bodies in provider_blocks(doc)
	some body in bodies
	alias := body.alias
	is_string(alias)
	regex.match("^[A-Za-z0-9_]+$", alias)
	not references(dir_of(doc.path), sprintf("%s.%s", [ptype, alias]))
	msg := sprintf(`%s: provider "%s" with alias "%s" is declared but not used (terraform_unused_declarations)`, [doc.path, ptype, alias])
}
