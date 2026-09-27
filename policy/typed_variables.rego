package main

import rego.v1

# Port of TFLint's terraform_typed_variables rule: every input variable must
# declare a type.

has_type(body) if {
	type := body.type
	not is_null(type)
	type != ""
}

deny contains msg if {
	some doc in docs
	some name, bodies in variable_blocks(doc)
	some body in bodies
	not has_type(body)
	msg := sprintf("%s: `%s` variable has no type (terraform_typed_variables)", [doc.path, name])
}
