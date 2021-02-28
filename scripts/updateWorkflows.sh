#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

# files not currently tracked by the repository
verbose="false"
dry="false"
debug="false"
verboseArg=""
dryArg=""
debugArg=""
actionName="jq-action"
rc=0

tempFile="$(mktemp)"
stderrTempFile="$(mktemp)"

while [ $# -gt 0 ]; do
    case $1 in
        -n|--name)
            shift
            actionName="$1"
            shift
            ;;
        -f|--file)
            shift
            if [ -z "${workflowFiles}" ]; then
                workflowFiles="$1"
            else
                workflowFiles="${workflowFiles}
$1"
            fi
            shift
            ;;
        --workflowFiles)
            shift
            workflowFiles="$(
                echo "$1" | \
                sed -E 's/\.yml /.yml\n/g'
            )"
            shift
            ;;
        -c|--commit)
            shift
            commit="$1"
            shift
            ;;
        -v|--verbose)
            verbose="true"
            shift
            ;;
        -d|--dry)
            shift
            dry="true"
            ;;
        -rootDir|--rootDir)
            shift
            rootDir="$1"
            shift
            ;;
        -workflowDir|--workflowDir)
            shift
            workflowDir="$1"
            shift
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
if [ -z "${rootDir}" ] || [ ! -d "${rootDir}" ]; then
    rootDir="$(dirname "$0")/.."
fi
if [ -z "${workflowDir}" ] || [ ! -d "${workflowDir}" ]; then
    workflowDir="${rootDir}/.github/workflows"
fi
if [ -z "${commit}" ]; then
    commit="$(git rev-parse --abbrev-ref HEAD)"
fi
if [ "${verbose}" = "true" ]; then
    verboseArg="--verbose"
fi
if [ "${dry}" = "true" ]; then
    dryArg="--dry"
fi
if [ "${#workflowFiles}" -eq 0 ]; then 
    workflowFiles="$(ls -1 "${workflowDir}" )"
fi
excluded="$(cd ${rootDir} && git ls-files --others --exclude-standard)"
if [ "${debug}" = "true" ]; then
    debugArg="--debug"
    echo "updateWorkflows.sh Arguments:"
    echo "
    rootDir \"${rootDir}\"
    workflowDir \"${workflowDir}\"
    verbose \"${verbose}\"
    dry \"${dry}\"
    actionName \"${actionName}\"
    commit \"${commit}\"
    debugArg \"${debugArg}\"
    " | \
    column -t | \
    indent >&2

    echo "\nworkflowFiles: \n$(
            echo "${workflowFiles}" | \
            indent
        )
        \nFiles excluded from repository: \n$(
            echo "${excluded}" | \
            indent
        )
        "
fi

echo "${workflowFiles}" >"${tempFile}"
while read file; do
    isExcluded="$( echo "$excluded" | egrep -o "$file" | wc -m )"
    if [ "${isExcluded}" -gt 0 ]; then
        stderr "'$file' is not tracked by git"
        if [ -f "${tempFile}" ]; then
            rm "${tempFile}"
        fi
        if [ -f "${tempFile}" ]; then
            rm "${stderrTempFile}"
        fi
        exit 1    
    else
        printf "Updating '%s'..." "${file}"
        
        # if [ "${debug}" = "false" ]; then
        #     # reset the workflow file
        #     git checkout -- "${workflowDir}/${file}"

        #     rc="$?"
        #     if [ "$rc" -gt 0 ]; then
        #         stderr "Failed to reset ${workflowDir}/${file}"
        #         return "$rc"
        #     fi
        # fi
        editContent="$(
            "$(dirname "$0")/../scripts/editFile.sh" \
                "${verboseArg}" \
                "${dryArg}" \
                "${debugArg}" \
                --file "${file}" \
                --dir "${workflowDir}" \
                --pattern "s/(${actionName}@)(.+)/\1${commit}/g" \
                --highlight "-B1 \"$actionName\"" 2>${stderrTempFile}
        )"
        rc="$?"

        changesMade="$(
            git status | \
            egrep "${file}"
        )"
        if [ "${#changesMade}" -eq 0 ]; then 
            echo "\tNo changes made."
        elif [ "${verbose}" = "false" ] && [ "$rc" -eq 0 ]; then 
            echo "\tSuccess!"
        else
            printf '\n'
        fi
        
        # visually separate its output from this one
        cat "${stderrTempFile}" | enclose -i 8


        if [ "${dry}" = "true" ]; then
            # show what the new file would look like
            echo "${editContent}" | \
                enclose | \
                grep -A1 -B1 --color=always "${actionName}@${commit}"
        elif [ "${verbose}" = "true" ]; then
            # show explicitly what was changed
            git diff -- "${workflowDir}/${file}"
        else
            # breifly show the change
            echo "${editContent}" | \
                indent | \
                grep -B1 "${actionName}@${commit}"
        fi
        
        if [ "$rc" -gt 0 ]; then
            # don't do the other files if this file failed
           break
        fi
    fi
done <"${tempFile}"

if [ -f "${tempFile}" ]; then
    rm "${tempFile}"
fi
if [ -f "${tempFile}" ]; then
    rm "${stderrTempFile}"
fi
if [ "$rc" -gt 0 ]; then
    exit $rc
fi

