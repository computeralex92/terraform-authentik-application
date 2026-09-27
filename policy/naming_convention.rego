package main

import rego.v1

# Port of TFLint's terraform_naming_convention rule (format = "snake_case"),
# which TFLint applies to resources, input variables, output values, local
# values, modules, data sources, and checks.
snake_case := "^[a-z][a-z0-9]*(_[a-z0-9]+)*$"

naming_deny(path, kind, name) := msg if {
	not regex.match(snake_case, name)
	msg := sprintf("%s: %s name `%s` must match the following format: snake_case (terraform_naming_convention)", [path, kind, name])
}

deny contains msg if {
	some doc in docs
	some name in object.keys(variable_blocks(doc))
	msg := naming_deny(doc.path, "variable", name)
}

deny contains msg if {
	some doc in docs
	some name in object.keys(output_blocks(doc))
	msg := naming_deny(doc.path, "output", name)
}

deny contains msg if {
	some doc in docs
	some name in object.keys(module_blocks(doc))
	msg := naming_deny(doc.path, "module", name)
}

deny contains msg if {
	some doc in docs
	some _, names in resource_blocks(doc)
	some name in object.keys(names)
	msg := naming_deny(doc.path, "resource", name)
}

deny contains msg if {
	some doc in docs
	some _, names in data_blocks(doc)
	some name in object.keys(names)
	msg := naming_deny(doc.path, "data", name)
}

deny contains msg if {
	some doc in docs
	some block in locals_blocks(doc)
	some name in object.keys(block)
	msg := naming_deny(doc.path, "local value", name)
}

deny contains msg if {
	some doc in docs
	some name in object.keys(check_blocks(doc))
	msg := naming_deny(doc.path, "check", name)
}
