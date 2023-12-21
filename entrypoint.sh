#!/bin/bash
# print the output and errors, but also send them to files to be read later
((eval $INPUT_CMD | tee /tmp/out) 3>&1 1>&2 2>&3 | tee /tmp/err)
EXIT_CODE="$?"
echo "exit_code=$EXIT_CODE" >> $GITHUB_OUTPUT
echo "stderr=$( cat /tmp/err | jq -sRr @uri )" >> $GITHUB_OUTPUT
echo "stdout=$( cat /tmp/out | jq -sRr @uri )" >> $GITHUB_OUTPUT

