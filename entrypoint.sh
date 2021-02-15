#!/bin/bash
eval $INPUT_CMD > /tmp/output > /tmp/error
EXIT_CODE="$?"
echo "::set-output name=stderr::$(cat /tmp/error)"
echo "::set-output name=stdout::$(cat /tmp/output)"
echo "::set-output name=exit_code::$EXIT_CODE"
