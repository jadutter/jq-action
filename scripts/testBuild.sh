#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

image_name="jq-action"
cmd="jq -n '{foo:\"bar\"}|keys' " 
expectation="[%0A\t\"foo\"%0A]"
test_result=""
pass=""

while [ $# -gt 0 ]; do
    case $1 in
        -i|--image)
            shift;
            image_name="$1"
            shift;
            ;;
        -c|--cmd)
            shift;
            cmd="$1"
            shift;
            ;;
        -e|--expectation)
            shift;
            expectation="$1"
            shift;
            ;;
    esac
done

echo "Testing build..."
test_result="$(
    INPUT_CMD="${cmd}" docker run --rm -e INPUT_CMD "${image_name}" 2>&1
)"
pass="$(
    echo "${test_result}" | \
    egrep -o "${expectation}"
)"
echo "${test_result}" | indent 
if [ "${#pass}" -gt 0 ]; then
    echo "Success!"
else
    echo "Failure:\n${test_result}">&2
    exit 1
fi 
