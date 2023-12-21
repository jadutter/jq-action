#!/bin/bash
function encode(){
    sed -E '
        :nextLine;
        # if not the end of the file
        $!{
          # add the next line to the pattern space
          N;
          # grab another line
          b nextLine;
        }
        # escape backslash characters
        s/\\/\\\\/g;

        # escape percentage sign
        s/%/%25/g;

        # esape newline characters
        s/\n/%0A/g;
        s/\r/%0D/g;

        # escape double quotes
        s/\"/\\\"/g;

        # escape dollar sign
        s/\$/\\$/g;
    '
}
# print the output and errors, but also send them to files to be read later
((eval "${INPUT_CMD}" | tee /tmp/output && echo "${PIPESTATUS[0]}" > /tmp/exit_code) 3>&1 1>&2 2>&3 | tee /tmp/error)
echo "exit_code=$(cat /tmp/exit_code)"  >> $GITHUB_OUTPUT
echo "stderr=$(cat /tmp/error | encode )"  >> $GITHUB_OUTPUT
echo "stdout=$(cat /tmp/output | encode )"  >> $GITHUB_OUTPUT
exit "$(cat /tmp/exit_code)"