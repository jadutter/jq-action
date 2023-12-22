#!/bin/bash
# print the output and errors, but also send them to files to be read later
# echo "${INPUT_CMD}" | sed -E 's,([$]),\\$1,g;' >/tmp/input
echo "${INPUT_CMD}" >/tmp/input
((eval "$(cat /tmp/input)" | tee /tmp/output && echo "${PIPESTATUS[0]}" > /tmp/exit_code) 3>&1 1>&2 2>&3 | tee /tmp/error)
echo "exit_code=$(cat /tmp/exit_code)"  >> $GITHUB_OUTPUT
(
    echo 'stderr<<EOF'
    cat /tmp/error
    echo 'EOF'
)  >> $GITHUB_OUTPUT
(
    echo 'stdout<<EOF'
    cat /tmp/output
    echo 'EOF'
)  >> $GITHUB_OUTPUT
exit "$(cat /tmp/exit_code)"