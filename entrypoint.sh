#!/bin/bash
eval $INPUT_CMD > /tmp/error > /tmp/output
local EXIT_CODE="$?"
echo "::set-output name=stderr::$(cat /tmp/error)"
echo "::set-output name=stdout::$(cat /tmp/output)"
echo "::set-output name=exit_code::$EXIT_CODE"