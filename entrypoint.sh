#!/bin/bash
# print the output and errors, but also send them to files to be read later
((eval "${INPUT_CMD}" | tee /tmp/output && echo "${PIPESTATUS[0]}" > /tmp/exit_code) 3>&1 1>&2 2>&3 | tee /tmp/error)
echo "::set-output name=stderr::\"$(echo -n $(cat /tmp/error | sed -E 'a\
\\n') )\""
echo "::set-output name=stdout::\"$(echo -n $(cat /tmp/output | sed -E 'a\
\\n') )\""
echo "::set-output name=exit_code::$(cat /tmp/exit_code)"
exit "$(cat /tmp/exit_code)"