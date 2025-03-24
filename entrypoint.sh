#!/bin/bash
# print the output and errors, but also send them to files to be read later
echo "0">/tmp/exit_code
echo "${INPUT_CMD}" >/tmp/input

((eval "$(cat /tmp/input)" 1>/tmp/output 2>/tmp/error; echo "$?" > /tmp/exit_code) )

cat /tmp/output
cat /tmp/error >&2

echo 'stdout<<EOF_STDOUT'>>$GITHUB_OUTPUT
cat /tmp/output >>$GITHUB_OUTPUT
if [[ ! "$(cat /tmp/output | tail -c 1)" == "$(printf '\n')" ]]; then 
    printf '\n' >>$GITHUB_OUTPUT
fi
printf 'EOF_STDOUT\n' >>$GITHUB_OUTPUT

echo 'stderr<<EOF_STDERR'>>$GITHUB_OUTPUT
cat /tmp/error >>$GITHUB_OUTPUT
if [[ ! "$(cat /tmp/error | tail -c 1)" == "$(printf '\n')" ]]; then 
    printf '\n' >>$GITHUB_OUTPUT
fi
printf 'EOF_STDERR\n' >>$GITHUB_OUTPUT

if [[ "$(cat /tmp/exit_code|tr -dc '[:digit:]')" -lt 1 ]]; then
    echo "0">/tmp/exit_code
fi

echo "exit_code=$(cat /tmp/exit_code)" >> $GITHUB_OUTPUT
exit "$(cat /tmp/exit_code)"