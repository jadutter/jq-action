#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

rootDir="$(dirname "$0")/.."
testsDir="$rootDir/tests"
verbose="false"
dry="false"
debug="false"
verboseArg=""
dryArg=""
pattern="/COPY.+\/tests/d"
file="Dockerfile"


tempFile="$(mktemp)"
stderrTempFile="$(mktemp)"

while [ $# -gt 0 ]; do
    case $1 in
        -r|--root|--rootDir)
            shift
            rootDir="$1"
            shift
            ;;
        -t|--tests|--testsDir)
            shift
            testsDir="$1"
            shift
            ;;
        -v|--verbose)
            shift
            verbose="true"
            ;;
        --debug)
            shift
            debug="true"
            ;;
        --dry)
            shift
            dry="true"
            ;;
        *)
            shift
            ;;
    esac
done
if [ "${verbose}" = "true" ]; then
    verboseArg="--verbose"
fi
if [ "${dry}" = "true" ]; then
    dryArg="--dry"
fi
if [ "${debug}" = "true" ]; then
    debugArg="--debug"
fi

if [ "${debug}" = "true" ]; then
    echo "removeTests.sh Arguments:"
    echo "
        rootDir '${rootDir}'
        testsDir '${testsDir}'
        file '${file}'
        pattern '$( echo "${pattern}" | sed -E 's/ / /g' )'
        verbose '${verbose}'
        dry '${dry}'
        " | \
        column -t | \
        indent >&2
fi

echo "Removing 'tests' directory from Dockerfile..."

if [ "${debug}" = "true" ]; then
    git checkout -- "${rootDir}/${file}"
    rc="$?"
    if [ "$rc" -gt 0 ]; then
        stderr "Failed to reset ${rootDir}/${file}"
        return "$rc"
    fi
    git checkout -- "${testsDir}"
    rc="$?"
    if [ "$rc" -gt 0 ]; then
        stderr "Failed to reset ${testsDir}"
        return "$rc"
    fi
fi

# Edit the Dockerfile so that it no longer copies the tests directory
editContent="$(
    "$(dirname "$0")/../scripts/editFile.sh" \
        "${verboseArg}" \
        "${dryArg}" \
        "${debugArg}" \
        --file "${file}" \
        --dir "${rootDir}" \
        --pattern "${pattern}" 2>${stderrTempFile}
)"
rc="$?"

# visually separate its output from this one
cat "${stderrTempFile}" | enclose -i 8 >&2

if [ "$rc" -gt 0 ]; then
    stderr "Failed to edit Dockerfile (${rootDir}/${file})"
    if [ -f "${tempFile}" ]; then
        rm "${tempFile}"
    fi
    if [ -f "${tempFile}" ]; then
        rm "${stderrTempFile}"
    fi
    exit $rc
fi

if [ "${dry}" = "false" ]; then
    git diff -- "${rootDir}/${file}" | \
    enclose
else
    echo "$editContent">"$temp"

    git diff --no-index "${rootDir}/${file}" "$temp" | \
    
    # clean up/simplify the temp file name 
    tempPattern="$(echo "$temp" | escape )"
    sed  -E "s/${tempPattern}/\/TEMP_FILE/g" | \
    enclose
fi

# # remove the tests directory (if present); the release branch does not need them
# if [ -d "${testsDir}" ]; then
#     echo "Removing 'tests' directory..."
#     rmCmd="rm -r \"${testsDir}\""
#     if [ "${dry}" = "true" ] || [ "${verbose}" = "true"  ]; then
#         echo "${rmCmd}"
#     fi
#     if [ "${dry}" = "false" ]; then
#         eval "${rmCmd}"
#         rc="$?"
#     fi
# elif [ "${verbose}" = "true"  ]; then
#     echo "'${testsDir}' has already been removed."
# fi


if [ -f "${tempFile}" ]; then
    rm "${tempFile}"
fi
if [ -f "${tempFile}" ]; then
    rm "${stderrTempFile}"
fi
if [ "$rc" -gt 0 ]; then
    exit $rc
fi
echo "Done!"
