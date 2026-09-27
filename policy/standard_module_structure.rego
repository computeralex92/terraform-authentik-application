package main

import rego.v1

# Port of TFLint's terraform_standard_module_structure rule: a module should
# have main.tf, variables.tf, and outputs.tf, and variable/output blocks should
# live in the matching file.
#
# Each directory containing *.tf files is treated as an independent module
# (the root module and each example), matching how TFLint ran per directory.

deny contains msg if {
	some dir in module_dirs
	not file_in(dir, "main.tf")
	msg := sprintf("%s: module should include a main.tf file as the primary entrypoint (terraform_standard_module_structure)", [dir_display(dir)])
}

deny contains msg if {
	some dir in module_dirs
	not file_in(dir, "variables.tf")
	not any_variables(dir)
	msg := sprintf("%s: module should include an empty variables.tf file (terraform_standard_module_structure)", [dir_display(dir)])
}

deny contains msg if {
	some dir in module_dirs
	not file_in(dir, "outputs.tf")
	not any_outputs(dir)
	msg := sprintf("%s: module should include an empty outputs.tf file (terraform_standard_module_structure)", [dir_display(dir)])
}

deny contains msg if {
	some doc in docs
	some name in object.keys(variable_blocks(doc))
	base_of(doc.path) != "variables.tf"
	msg := sprintf("%s: variable %q should be moved from %s to variables.tf (terraform_standard_module_structure)", [doc.path, name, base_of(doc.path)])
}

deny contains msg if {
	some doc in docs
	some name in object.keys(output_blocks(doc))
	base_of(doc.path) != "outputs.tf"
	msg := sprintf("%s: output %q should be moved from %s to outputs.tf (terraform_standard_module_structure)", [doc.path, name, base_of(doc.path)])
}
