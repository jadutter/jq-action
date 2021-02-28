#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

file=""
stashName="jq-action-stash"
undoStash="false"
verbose="false"
dry="false"
debug="false"

while [ $# -gt 0 ]; do
    case $1 in
        -f|--file)
            shift
            file="$1"
            shift
            ;;
        -s|--stashName)
            shift
            stashName="$1"
            shift
            ;;
        -u|--undoStash)
            undoStash="true"
            shift
            ;;
        -v|--verbose)
            shift
            verbose="true"
            ;;
        --dry)
            shift
            dry="true"
            ;;
        --debug)
            shift
            debug="true"
            ;;
        *)
            shift
            ;;
    esac
done

if [ "${debug}" = "true" ]; then
    echo "stashFile.sh Arguments:" >&2
    echo "
        file '${file}'
        stashName '${stashName}'
        undoStash '${undoStash}'
        verbose '${verbose}'
        dry '${dry}'
        " | \
        column -t | \
        indent >&2
fi
if [ "${undoStash}" = "true" ]; then
    # find the stash we want
    stashIndex="$(
        git stash list | \
        egrep "${stashName}" | \
        egrep -o 'stash@\{[0-9]+\}' | \
        head -n 1 
    )"
    if [ "${#stashIndex}" -eq 0 ]; then
        stderr "Couldn't find a stash to match '${stashName}'"
        git stash list | indent >&2
        exit 1
    else
        git stash pop "${stashIndex}"
        return $?
    fi
else
    if [ "${#file}" -gt 0 ]; then
        if [ -f "${file}" ]; then
            git stash push -m "${stashName}" -- "${file}"
            return $?
        else
            stderr "File does not exist: '${file}'"
            exit 1
        fi
    else
        git stash push -m "${stashName}" 
        return $?
    fi
fi

# git stash -- "${file}"

# git stash apply stash^{/${file}}
# git stash pop stash^{/${file}}

# git stash pop stash^{/jq-action-stash}
