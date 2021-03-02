#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

prepareBranch(){
    rootDir="$(dirname "$0")/.."
    workflowDir="$rootDir/.github/workflows"
    testsDir="$rootDir/tests"
    dockerfile="$rootDir/Dockerfile"
    branchName="$(git rev-parse --abbrev-ref HEAD)"
    verbose="false"
    dry="false"
    debug="false"
    verboseArg=""
    dryArg=""

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
            -w|--work|--workflowDir)
                shift
                workflowDir="$1"
                shift
                ;;
            --dockerfile)
                shift
                dockerfile="$1"
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
    isRelease="$(echo "${branchName}" | egrep -o "^release" )"
    if [ "${isRelease}" ]; then
        isRelease="true"
    else 
        isRelease="false"
    fi
    isDevelop="$(echo "${branchName}" | egrep -o "^develop")"
    if [ "${isDevelop}" ]; then
        isDevelop="true"
    else 
        isDevelop="false"
    fi

    if [ "${debug}" = "true" ]; then
        echo "prepareBranch.sh Arguments:"
        echo "
            rootDir '${rootDir}'
            workflowDir '${workflowDir}'
            testsDir '${testsDir}'
            dockerfile '${dockerfile}'
            branchName '${branchName}'
            verbose '${verbose}'
            dry '${dry}'
            debug '${debug}'
            verboseArg '${verboseArg}'
            dryArg '${dryArg}'
            isRelease '${isRelease}'
            isDevelop '${isDevelop}'
            " | \
            column -t | \
            indent >&2
        # reset changes made during a previous execution 
        git checkout -- "${workflowDir}" "${testsDir}" "${dockerfile}"
        rc="$?"
        if [ "$rc" -gt 0 ]; then
            stderr "Failed to reset"
            exit "$rc"
        fi
    fi


    stashChanges(){
        echo "Stashing uncommited changes"
        "$(dirname "$0")/../scripts/stashFile.sh" \
            "${dryArg}" \
            "${debugArg}" \
            "${verboseArg}" 2>&1 | \
            enclose

        rc="$?"
        if [ "$rc" -gt 0 ]; then
            stderr "Failed to stash changes."
            exit "$rc"
        fi
    }

    restoreChanges(){
        echo "Restoring uncommited changes"
        "$(dirname "$0")/../scripts/stashFile.sh" \
            "${dryArg}" \
            "${debugArg}" \
            "${verboseArg}" \
            --undoStash 2>&1 | \
            enclose


        rc="$?"
        if [ "$rc" -gt 0 ]; then
            stderr "Failed to restore stash."
            exit "$rc"
        fi
    }

    stashChanges

    echo "Updating workflows..."
    # only the release branch should use the release workflow;
    # update test-release.yml to only use the release branch
    "$(dirname "$0")/../scripts/updateWorkflows.sh" \
        "${dryArg}" \
        "${debugArg}" \
        "${verboseArg}" \
        --rootDir "${rootDir}" \
        --workflowDir "${workflowDir}" \
        --workflowFiles "test-release.yml" \
        -c "release" \
        "$@" 2>&1 | enclose

    rc="$?"
    if [ "$rc" -gt 0 ]; then
        stderr "Failed to fix the 'test-release.yml'"
        restoreChanges
        return "$rc"
    fi

    # all branches should use the 'all' workflow
    "$(dirname "$0")/../scripts/updateWorkflows.sh" \
        "${dryArg}" \
        "${debugArg}" \
        "${verboseArg}" \
        --rootDir "${rootDir}" \
        --workflowDir "${workflowDir}" \
        --workflowFiles "test-all.yml" \
        -c "${branchName}" \
        "$@" 2>&1 | enclose

    rc="$?"
    if [ "$rc" -gt 0 ]; then
        stderr "Failed to fix the 'test-all.yml'"
        restoreChanges
        return "$rc"
    fi

    # the develop branch should pass the develop workflow
    # feature branches that would merge into develop, should pass the develop workflow
    # release branch should never run the develop workflow, because of the 'on' triggers
    "$(dirname "$0")/../scripts/updateWorkflows.sh" \
        "${dryArg}" \
        "${debugArg}" \
        "${verboseArg}" \
        --rootDir "${rootDir}" \
        --workflowDir "${workflowDir}" \
        --workflowFiles "test-develop.yml" \
        -c "${branchName}" \
        "$@" 2>&1 | enclose


    rc="$?"
    if [ "$rc" -gt 0 ]; then
        stderr "Failed to fix the 'test-develop.yml'"
        restoreChanges
        return "$rc"
    fi

    if [ "${isRelease}" = "true" ]; then    
        # remove tests directory 
        "$(dirname "$0")/../scripts/removeTests.sh" \
            --root "${rootDir}" --tests "${testsDir}" $@
        rc="$?"
        if [ "$rc" -gt 0 ]; then
            stderr "Failed to remove tests."
            restoreChanges
            return "$rc"
        fi
    # elif [ "${isDevelop}" = "true" ]; then
    #     echo "develop branch is ready."
    # else
    #     echo "${branchName} branch is ready."
    fi


    if [ "${dry}" = "true" ]; then
        # list staged files
        echo "Commiting changes..."
        echo "git add \"${dockerfile}\" \"${testsDir}\" \"${workflowDir}\"
    git commit -m \"workflows updated.\"" | \
        enclose
        
    else
        # list staged files
        echo "Commiting changes..."

        output="$(
            git add "${dockerfile}" "${testsDir}" "${workflowDir}" 2>&1
            # commit changes 
            git commit -m "workflows updated." --no-verify 2>&1
        )"
        echo "${output}"| enclose

        rc="$?"
        if [ "$rc" -gt 0 ]; then
            # undo changes we made...?
            stderr "Failed to commit the changes to ${branchName}."
            restoreChanges
            return "$rc"
        fi
    fi

    restoreChanges
}

prepareBranch $@

# # TODO:
# #     * stash files before making changes
# #     * unstash it after commit
# #     * unstash after error
# #     * merge errors...?

# # main --verbose 
# # rc="$?"
# # if [ "$rc" -gt 0 ]; then
# #     exit "$rc"
# # fi


# # THIS_DIRECTORY="${0%/*}"
# # DIR="${0%/*}"
# # echo "$PATH/style.sh"
# # source "./style.sh"


# if [ "${FUNCNAME[1]}" != "source" ]; then
#     test-build "$@"
# fi

