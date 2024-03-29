#!/bin/sh

function escape(){
    cat | sed -E 's/("|\\|\$|\/)/\\\1/g'
}

function indentation(){
    local quantity
    local character
    local spareArgs=()
    while [ $# -gt 0 ]; do
        case "$1" in
            -q|--quantity) 
                shift
                quantity="$(echo -en "$1" | egrep -o '\d+' )"
                shift
                ;;
            -c|--character) 
                shift
                character="$1"
                shift
                ;;
            *) 
                spareArgs+=("$1")
                shift
                ;;
        esac
    done
    if [[ "${#character}" -eq 0 ]]; then
        character=" "
    fi
    if [[ "${#quantity}" -eq 0 ]]; then
        quantity=4
    fi

    if [[ "${#quantity}" -gt 0 ]]; then 
        if [[ "${quantity}" -eq 1 ]]; then 
            printf "${character}"
        else
            printf "%0.0s${character}" $(seq 1 "${quantity}" )
        fi
    fi
}
function indent(){
    whitespace="$(indentation $@)"
    cat | sed -E "s/(^|\n)/\1${whitespace}/g"
}

edit_file() {
    local dir=""
    local file=""
    local pattern=""
    local highlight=""
    local verbose="false"
    local dry="false"
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
            *)
                shift
                ;;
        esac
    done
    # if [ "${verbose}" == "true" ]; then
    #     echo "
    #         dir '${dir}'
    #         file '${file}'
    #         pattern '$( echo "${pattern}" | sed -E 's/ / /g' )'
    #         highlight '$( echo "${highlight}" | sed -E 's/ / /g' )'
    #         verbose '${verbose}'
    #         dry '${dry}'
    #         " | \
    #         column -t | \
    #         sed -E 's/^/    /g' >&2
    # fi
    file="${dir}/${file}"
    if [ "${dry}" == "false" ]; then
        # reset the file
        git checkout -- "${file}"
        rc="$?"
        if [[ "$rc" -gt 0 ]]; then
            return "$rc"
        fi
    fi
    # modify the file content
    content="$(sed -E "${pattern}" "${file}" )"
    rc="$?"
    if [[ "$rc" -gt 0 ]]; then
        return "$rc"
    fi
    if [[ "${dry}" == "true" || "${verbose}" == "true"  ]]; then
        # report what the new content is
        echo "${content}"
    fi
    if [ "${dry}" == "false" ]; then
        # save the changes to the file
        echo "${content}" > "${file}"
        rc="$?"
        if [[ "$rc" -gt 0 ]]; then
            return "$rc"
        fi        
        git add "${file}"
        rc="$?"
        if [[ "$rc" -gt 0 ]]; then
            return "$rc"
        fi
    fi
}
update_workflows() {
    local root_dir="$(dirname "$0")/.."
    local workflow_dir="$root_dir/.github/workflows"
    # files not currently tracked by the repository
    local excluded="$(cd ${root_dir} && git ls-files --others --exclude-standard)"
    local verbose="false"
    local dry="false"
    local verbose_arg=""
    local dry_arg=""
    local action_name="jq-action"
    local commit="$(git rev-parse HEAD)"
    local workflow_files=()
    while [ $# -gt 0 ]; do
        case $1 in
            -n|--name)
                shift
                action_name="$1"
                shift
                ;;
            -f|--file)
                shift
                workflow_files+=("$1")
                shift
                ;;
            --workflow_files)
                shift
                workflow_files=( $1 )
                shift
                ;;
            -c|--commit)
                shift
                commit="$1"
                shift
                ;;
            -v|--verbose)
                shift
                verbose="true"
                ;;
            -d|--dry)
                shift
                dry="true"
                ;;
            *)
                shift
                ;;
        esac
    done
    if [ "${verbose}" == "true" ]; then
        verbose_arg="--verbose"
    fi
    if [ "${dry}" == "true" ]; then
        dry_arg="--dry"
    fi
    if [ "${verbose}" == "true" ]; then
        echo "
            root_dir \"${root_dir}\"
            workflow_dir \"${workflow_dir}\"
            verbose \"${verbose}\"
            dry \"${dry}\"
            action_name \"${action_name}\"
            commit \"${commit}\"
            " | column -t 
        echo "\nworkflow_files: \n$(
                echo "${workflow_files[@]}" | \
                sed -E 's/ /\\n/g' | \
                sed -E 's/(^|\\n)/\1    /g;'
            )
            \nexcluded:       \n$(
                echo "${excluded}" | \
                sed -E 's/^/    /g' 
            )
            "
    fi
    if [ "${#workflow_files[@]}" -eq 0 ]; then 
        workflow_files=( $(ls -1 "${workflow_dir}") )
    fi
    # local workflow_files=( $(ls -1 "${workflow_dir}") )
    for file in ${workflow_files[@]}; do
        is_excluded="$( echo "$excluded" | egrep -o "$file" | wc -m )"
        if [ "${is_excluded}" -eq 0 ]; then
            # if [ "${verbose}" == "true" ]; then
            #     echo "Updating $file"
            # fi
            echo "Updating $file"
            
            
            # edit_file \
            #     "${verbose_arg}" \
            #     "${dry_arg}" \
            #     --file "${file}" \
            #     --dir "${workflow_dir}" \
            #     --pattern "s/(${action_name}@)(.+)/\1${commit}/g" \
            #     --highlight "-B1 \"$action_name\"" 
            # echo "edited"
            # rc="$?"
            # echo "$rc"
            if [[ "${dry}" == "true" || "${verbose}" == "true"  ]]; then
                edit_content="$(
                    edit_file \
                        "${verbose_arg}" \
                        "${dry_arg}" \
                        --file "${file}" \
                        --dir "${workflow_dir}" \
                        --pattern "s/(${action_name}@)(.+)/\1${commit}/g" \
                        --highlight "-B1 \"$action_name\""
                )"
                rc="$?"
                # echo "${edit_content}" | \
                #     sed -E 's/^/    /g' | \
                #     grep -B1 "$action_name"
                git diff -- "${workflow_dir}/${file}"
                if [[ "$rc" -gt 0 ]]; then
                    return "$rc"
                fi
            else
                edit_content="$(
                    edit_file \
                        "${verbose_arg}" \
                        --verbose \
                        "${dry_arg}" \
                        --file "${file}" \
                        --dir "${workflow_dir}" \
                        --pattern "s/(${action_name}@)(.+)/\1${commit}/g" \
                        --highlight "-B1 \"$action_name\""
                )"
                rc="$?"
                # echo "not dry and not verbose $edit_content"
                echo "${edit_content}" | \
                    sed -E 's/^/    /g' | \
                    grep -B1 "$action_name"
                if [[ "$rc" -gt 0 ]]; then
                    return "$rc"
                fi
            fi
            

            # file="${workflow_dir}/${file}"
            # if [ "${dry}" == "false" ]; then
            #     # reset the workflow file
            #     git checkout -- "${file}"
            # fi
            # # modify the file to use the current hash when running tests
            # content="$(sed -E "s/(${action_name}@)(.+)/\1${commit}/g" "${file}" )"
            # if [[ "${dry}" == "true" || "${verbose}" == "true"  ]]; then
            #     echo "${content}" | \
            #     sed -E 's/^/    /g' | \
            #     grep -B1 "$action_name"
            # fi
            # if [ "${dry}" == "false" ]; then
            #     echo "${content}" > "${file}"
            # fi

        fi
    done
}
remove_tests(){
    local verbose="false"
    local dry="false"
    local verbose_arg=""
    local dry_arg=""
    local root_dir=""
    local tests_dir=""
    local pattern="/COPY.+\/tests/d"
    local file="Dockerfile"
    while [ $# -gt 0 ]; do
        case $1 in
            -r|--root|--root_dir)
                shift
                root_dir="$1"
                shift
                ;;
            -t|--tests|--tests_dir)
                shift
                tests_dir="$1"
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
            *)
                shift
                ;;
        esac
    done
    if [ "${verbose}" == "true" ]; then
        verbose_arg="--verbose"
    fi
    if [ "${dry}" == "true" ]; then
        dry_arg="--dry"
    fi

    if [ "${verbose}" == "true" ]; then
        echo "
            root_dir '${root_dir}'
            tests_dir '${tests_dir}'
            file '${file}'
            pattern '$( echo "${pattern}" | sed -E 's/ / /g' )'
            verbose '${verbose}'
            dry '${dry}'
            " | \
            column -t | \
            sed -E 's/^/    /g' >&2
    fi

    echo "Edit Dockerfile"
    if [ "${dry}" == "false" ]; then
        git checkout -- "${root_dir}/${file}"
    fi
    # Edit the Dockerfile so that it no longer copies the tests directory
    edit_content="$(
        edit_file \
            "${verbose_arg}" \
            "${dry_arg}" \
            --file "${file}" \
            --dir "${root_dir}" \
            --pattern "${pattern}"
    )"
    rc="$?"
    if [[ "$rc" -gt 0 ]]; then
        echo -e "$edit_content"
        return "$rc"
    fi
    if [[ "${dry}" == "false" ]]; then
        git diff -- "${root_dir}/${file}" | \
        indent -q 4
    else
        local temp=$(mktemp)
        echo -en "$edit_content">"$temp"

        local TEMP_PATTERN="$(echo "$temp" | escape )"
        git diff --no-index "${root_dir}/${file}" "$temp" | \
        sed  -E "s/${TEMP_PATTERN}/\/TEMP_FILE/g" | \
        indent -q 4

        rm "$temp"
    fi
    # remove the tests directory (if present); the release branch does not need them
    if [[ -d "${tests_dir}" ]]; then
        rm_cmd="rm -r \"${tests_dir}\""
        if [[ "${dry}" == "true" || "${verbose}" == "true"  ]]; then
            echo "${rm_cmd}"
        fi
        if [ "${dry}" == "false" ]; then
            eval "${rm_cmd}"
            rc="$?"
            if [[ "$rc" -gt 0 ]]; then
                return "$rc"
            fi
        fi
    fi
}
main(){
    local root_dir="$(dirname "$0")/.."
    local workflow_dir="$root_dir/.github/workflows"
    local tests_dir="$root_dir/tests"
    local dockerfile="$root_dir/Dockerfile"
    local branch_name="$(git rev-parse --abbrev-ref HEAD)"
    
    local is_release="$(echo "${branch_name}" | egrep -o "^release" | wc -m )"
    local is_develop="$(echo "${branch_name}" | egrep -o "^develop" | wc -m )"
    
    # # reset the workflow directory from a previous execution of pre-push
    # git checkout -- "${workflow_dir}"

    # only the release branch should use the release workflow
    update_workflows --file "test-release.yml" -c "release" $@
    rc="$?"
    if [[ "$rc" -gt 0 ]]; then
        return "$rc"
    fi
    
    # all branches should use the 'all' workflow
    update_workflows --file "test-all.yml" -c "${branch_name}" $@
    rc="$?"
    if [[ "$rc" -gt 0 ]]; then
        return "$rc"
    fi

    # feature branches that would merge into develop, should pass the develop workflow
    # develop branch should pass the develop workflow
    # release branch should never run the develop workflow, because of the 'on' triggers
    update_workflows --file "test-develop.yml" -c "${branch_name}" $@

    rc="$?"
    if [[ "$rc" -gt 0 ]]; then
        return "$rc"
    fi

    if [[ "${is_release}" -gt 0 ]]; then
        echo "working on release"
        # # reset the tests directory and Dockerfile from a previous execution of pre-push
        # git checkout -- "${tests_dir}" "${root_dir}/Dockerfile"
        
        # remove tests directory from Dockerfile and repository
        remove_tests --root "${root_dir}" --tests "${tests_dir}" $@
        rc="$?"
        if [[ "$rc" -gt 0 ]]; then
           return "$rc"
        fi
    elif [[ "${is_develop}" -gt 0 ]]; then
        echo "working on develop"
    else
        echo "working on other branch, ${branch_name}"
    fi
    
    is_dry="$(echo "$@" | grep -o '\b(-d|--dry)\b' | wc -m )"
    
    if [[ "${is_dry}" -eq 0 ]]; then
        # list staged files
        echo "commiting changes to files"

        # commit changes 
        git commit -m "pre-push git hook changes"
        
        rc="$?"
        if [[ "$rc" -gt 0 ]]; then
            # undo changes we made...?
           return "$rc"
        fi
    fi
}

# TODO:
#     * stash files before making changes
#     * unstash it after commit
#     * unstash after error
#     * merge errors...?

# main --verbose 
# rc="$?"
# if [[ "$rc" -gt 0 ]]; then
#     exit "$rc"
# fi


# THIS_DIRECTORY="${0%/*}"
# DIR="${0%/*}"
# echo "$PATH/style.sh"
# source "./style.sh"


if [[ "${FUNCNAME[1]}" != "source" ]]; then
    test-build "$@"
fi

