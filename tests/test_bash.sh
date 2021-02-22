#!/bin/bash

function test_bash(){
    echo '{"foo":"bar"}' | 
    jq 'keys'

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
test_bash 