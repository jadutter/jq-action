#!/bin/bash
# print the output and errors, but also send them to files to be read later
((eval $INPUT_CMD | tee /tmp/output) 3>&1 1>&2 2>&3 | tee /tmp/error)
EXIT_CODE="$?"
echo "::set-output name=stderr::$(cat /tmp/error)"
echo "::set-output name=stdout::$(cat /tmp/output)"
echo "::set-output name=exit_code::$EXIT_CODE"
