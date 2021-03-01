#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

dir=""
file=""
pattern=""
highlight=""
verbose="false"
dry="false"
debug="false"
spareArgs=""


while [ $# -gt 0 ]; do
    case $1 in
        -d|--dir)
            shift
            dir="$1"
            shift
            ;;
        -f|--file)
            shift
            file="$1"
            shift
            ;;
        -p|--pattern)
            shift
            pattern="$1"
            shift
            ;;
        -h|--highlight)
            shift
            highlight="$1"
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
            if [ "${#spareArgs}" -eq 0 ]; then
                spareArgs="$1"
            else
                spareArgs+=" $1"
            fi
            shift
            ;;
    esac
done

if [ "${#spareArgs}" -gt 0 ]; then
    stderr "Unrecognized arguments: ${spareArgs}"
    exit 1
fi

if [ "${debug}" = "true" ]; then
    echo "editFile.sh Arguments:" >&2
    echo "
        dir '${dir}'
        file '${file}'
        pattern '$( echo "${pattern}" | sed -E 's/ / /g' )'
        highlight '$( echo "${highlight}" | sed -E 's/ / /g' )'
        verbose '${verbose}'
        dry '${dry}'
    " | \
    column -t | \
    indent  >&2
fi

file="${dir}/${file}"

# # if this is not a dry run, 
# if [ "${debug}" = "true" ]; then
#     # reset the file
#     git checkout -- "${dir}/${file}"

#     rc="$?"
#     if [ "$rc" -gt 0 ]; then
#         stderr "Failed to reset ${dir}/${file}"
#         exit "$rc"
#     fi
# fi

# modify the file content
content="$(
    sed -E "
        # replace what we've been asked to replace
        ${pattern};
        # escape backslash notation that we would otherwise be undoing
        s/\\\\/\\\\\\\\/g;
    " "${file}" 2>&1 )"
rc="$?"
if [ "$rc" -gt 0 ]; then
    echo "$content" >&2
    exit "$rc"
fi
if [ "${dry}" = "true" ] || [ "${verbose}" = "true" ]; then
    # report what the new content is
    echo "${content}"
fi
if [ "${dry}" = "false" ]; then
    # save the changes to the file
    echo "${content}" > "${file}"
    exit $?
fi

