#!/bin/bash
# print the output and errors, but also send them to files to be read later
sed_command='
    :nextLine;
    {
        # add the next line to the pattern space
        N;
    }
    # if not the end of the file
    $!{
        # grab another line
        b nextLine;
    }
    # esape newline characters
    s/\n/%0A/g;
    s/\r/%0D/g;
    # escape characters that would interfere with the `echo ":::set-output...`
    s/("|\\|\$)/\\\1/g;
    # escape percentage sign
    s/%/%25/g;
    # escape whitespace 
    s/	/%09/g;
    s/ /%20/g;
'
((eval "${INPUT_CMD}" | tee /tmp/output && echo "${PIPESTATUS[0]}" > /tmp/exit_code) 3>&1 1>&2 2>&3 | tee /tmp/error)
echo "::set-output name=stderr::$(cat /tmp/error | sed -E "${sed_command}" )"
echo "::set-output name=stdout::$(cat /tmp/output | sed -E "${sed_command}" )"
echo "::set-output name=exit_code::$(cat /tmp/exit_code)"
exit "$(cat /tmp/exit_code)"