#!/bin/bash

function test_bash(){
	local get_values="$(cat<<EOF
def values:
	to_entries |
	map(
		.value
	)
;
values
EOF
)"
    jq "${get_values}" ./tests/sample.json
}
test_bash | jq -sc 'add'