#!/usr/bin/jq

def sample_function:
    {
        foo: "bar"
    } | 
    to_entries |
    .[] |
    [ .key, .value ]
;

