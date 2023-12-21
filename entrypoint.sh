#!/bin/bash
# print the output and errors, but also send them to files to be read later
((eval "${INPUT_CMD}" | tee /tmp/output && echo "${PIPESTATUS[0]}" > /tmp/exit_code) 3>&1 1>&2 2>&3 | tee /tmp/error)
echo "exit_code=$(cat /tmp/exit_code)"  >> $GITHUB_OUTPUT
echo "stderr=$(cat /tmp/error | jq -sRr @uri )"  >> $GITHUB_OUTPUT
echo "stdout=$(cat /tmp/output | jq -sRr @uri )"  >> $GITHUB_OUTPUT
exit "$(cat /tmp/exit_code)"