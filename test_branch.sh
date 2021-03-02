#!/bin/sh
# . "$(dirname "$0")/_/husky.sh"


# true=1
# false=0

getBranchName()
{
    echo $(git rev-parse --abbrev-ref HEAD)
}

isNewBranch()
{   
    local logQuery=$(
        git log --all --not \
            $(
                git rev-list --no-walk \
                --exclude=refs/heads/$(getBranchName) \
                --exclude=HEAD \
                --all
            )
        )  
    if [ -z $logQuery ]; then 
        echo true
    else
        echo false
    fi  
}

# git show-ref --head | egrep heads

# # commits=($(git rev-list --no-walk --all))
# # for c in ${commits[@]}; do git name-rev --name-only $c; done


# 47399dcdd7ac85ac285504f575d8996f7eaff705 refs/heads/alpine
# b6cae60d000dfba629d47cf06358eab12a977c33 refs/heads/debian
# 445b824cfbeeb3a505e248ce25d9874cc8b8ff38 refs/heads/develop
# 172889265485dbb4cc195b368aefaa811910a0ae refs/heads/foo
# 8a82109ebbc119a8b09f919730ba4fbb3d33a783 refs/heads/release
# 0fffae14d5ff5f5197af51f097ba36ccc2809bbd refs/heads/test-workflow
# 172889265485dbb4cc195b368aefaa811910a0ae refs/heads/test-workflows

# 172889265485dbb4cc195b368aefaa811910a0ae
# 8a82109ebbc119a8b09f919730ba4fbb3d33a783
# 445b824cfbeeb3a505e248ce25d9874cc8b8ff38
# 47399dcdd7ac85ac285504f575d8996f7eaff705
# b6cae60d000dfba629d47cf06358eab12a977c33
# 0fffae14d5ff5f5197af51f097ba36ccc2809bbd

# git diff-tree --no-commit-id --name-only -r <SHA1>
# # or
# git ls-tree -d --name-only -r <SHA1>


# git show-ref --verify --quiet refs/heads/foo && echo "true" || echo "false"


# function lint-branch(){ 
#     # the name of git branch we are currently on
#     currentBranch="$(git rev-parse --abbrev-ref HEAD)"

#     # the name of git branch we derived the current branch from
#     parentBranch="$( git show-branch | grep '*' | grep -v "$currentBranch" | head -n1 | sed -E 's/^.+\[|\].+$//g' )"

#     # the common ancestor commit between the two branches
#     commonCommit="$(git merge-base "$parentBranch" HEAD)"

#     # files that were added or changed since the current branch diverged from 'develop'
#     changedFiles=( $(git diff --name-only HEAD "$commonCommit" | egrep -v '.releaserc.js' | egrep -e '\.(jsx?)$' ) )

#     echo "Linting"
#     printf -- '    %s\n' ${changedFiles[@]}

#     npx eslint ${changedFiles[@]}
# }


(
cd ~/Documents/Github/jq-action-2
# cd ~/Documents/Github/paypal-messaging-components
function created(){
    local BRANCH="$1"
    shift 1
    local ALL_BRANCHES="$@"

    function remove_dup_move(){
        cat | egrep -v 'checkout: moving from (.+) to \1'
        # sed -E '/checkout: moving from (.+) to \1$/d'
    }
    function replace_msg(){
        cat | sed -E 's/checkout: moving from (.+) to (.+)$/\1 \2/g'
    }
    function replace_from(){
        cat | sed -E "s/checkout: moving from (${BRANCH}) to (.+)$/to   \2/g"
    }
    function replace_to(){
        cat | sed -E "s/checkout: moving from (.+) to (${BRANCH})$/from \1/g"
    }
    function find_checkouts(){
        cat | egrep "checkout: moving from" 
    }
    function find_named_branches(){
        cat | egrep "from (${ALL_BRANCHES}) to (${ALL_BRANCHES})"
    }
    function find_current_branch(){
        cat | grep "to ${BRANCH}" 
    }
    function pull_timestamp(){
        # from reflog selector
        cat |  sed -E 's/.+@\{(.+)\}/\1/g'
    }
    # git reflog --date=local | \
    # | \
        # grep checkout: | \
        # grep checkout: | \
        # grep "$1" | \
        # tail -1 | \
        # cut -d'{' -f2 | \
        # cut -d'}' -f1
    
    local reflog_selector='%gD' # contains timestamp when --date is used
    local committer_date='%ci'
    local author_date='%ai'
    local commit_notes='%s'
    local tree_hash='%t'
    local commit_hash='%H'
    local tree_hash='%t'
    local sign_msg="%gs"
    local pretty=(
        "${reflog_selector}"
        # "${committer_date}"
        # "${author_date}"
        # "${commit_notes}"
        # "${tree_hash}"
        "${commit_hash}"
        "${sign_msg}"
        # "%s"
        # "%N"
        # "%gd"
        # "%gD"
    )
    pretty="${pretty[*]}"
    # echo "${ALL_BRANCHES}"
    # git reflog  \
    #     --date=local \
    #     | find_current_branch \
    #     | find_named_branches
        # | grep "checkout: to $1" \
    # -S="checkout"
    # --grep="checkout"
    # echo ${get_pretty}
    git reflog \
        --date="iso-strict" \
        --pretty="${pretty}" \
        | find_current_branch \
        | find_checkouts \
        | find_named_branches \
        | pull_timestamp \
        | remove_dup_move \
        # | replace_msg
        # | replace_from \
        # | replace_to


    # git reflog --date=local \
    #     | egrep "checkout.+?$1" \
    # echo "${pretty}"
}

# all local branches
branches=( $(
        git branch -v | \
        sed -e 's/*/ /' | \
        awk '{print $1}' \
        # | grep 'DTCRCMERC-647'

    )
)

for branch in "${branches[@]}"; do
    if [ -z $all ]; then 
        all=$branch
    else
        all+="|$branch"
    fi
done
for branch in "${branches[@]}"; do
    # branch='DTCRCMERC-745-font-feature'
    printf "\n%s\n" $branch
    echo "$(
        # column -t |
        created "$branch" "${all}" | \
        sed -E 's/.+from(.+)to.+/\1/g' |
        tail -n 1 

        # | \
        # sort --reverse
    )"
    printf "%0.0s-" $(seq 1 10)
    printf "\n"
    # break
    # echo "$(created $branch) $branch $(git rev-parse "$branch")"
done 
# | sort -t- 

# git reflog \
#     --date=local \
    # --pretty="%ci %ai %H %gs" \
#     | find_current_branch \
#     | find_checkouts \
#     | find_named_branches \
)



    # | find_current_branch \
get_parent_branch(){
    branch="${1:-HEAD}"
    branch="$( git rev-parse --abbrev-ref "${branch}" )"
    if [[ "${#branch}" -eq 0 ]]; then
        echo "Please specify a valid branch">&2
        return 1
    fi
    # 1) %gD can give us the timestamp of when a git event happened, 
    # but the argument --date needs to be supplied for it to use a date instead
    # of the index number
    # 2) "iso-strict" is to prevent spacing, and make it easier to ensure the entries are sorted
    # 3) %gs gives us a description of the git event
    # 4) the first sed command extracts just the timestamp from %gD (dont ask me why there isnt a pretty format for this field)
    # 5) the second and third sed commands ensure we only use events with actual branch names instead of a hash
    # 6) the fourth sed command pulls the branch we jumped from, to reach the current branch, and prints the line
    # 7) the egrep command is because macOS sed wouldnt cooperate with a backreference in the match pattern
    # 8) the tail command pulls the oldest reference; presumably the ancestor the current branch spawned from
    git reflog \
        --date="iso-strict" \
        --pretty="%gD %gs" \
        | sed -nE "
            s/.+@\{(.+)\}/\1/g; 
            /from [a-d0-9]{40}/d;
            /to [a-d0-9]{40}/d;
            s/.+checkout: moving from (.+) to ${branch}/\1/gp;
        " \
        | egrep -v 'checkout: moving from (\w+) to \1' \
        | tail -n 1
}

get_parent_branch "test-workflows"


# uppercaseLetters=( $( echo "$(printf "\\\x%x " $(seq 65 90))" ) )
# lowercaseLetters=( $( echo "$(printf "\\\x%x " $(seq 97 122))" ) )
# letters=(
#     "${uppercaseLetters[@]}"
#     "${lowercaseLetters[@]}"
# )
# for letter in ${letters[@]}; do 
#     echo $letter
# done 
# printf "\\\x%x " $(seq 65 90))

# for form in {a..z}{A..Z}; do
#     output=""
#     form="%${form}"
#     output="$(git reflog -1 --pretty="${form}" --date=iso)"
#     if [[ "${#output}" -gt "${#form}" ]]; then
#         echo "${form} ${output}"
#     fi
# done

# git reflog -1 --date=iso-strict | sed -E 's/.+\{(.+)\}:/\1/g'
# echo " checkout: moving from develop to develop" | sed -E '/checkout: moving from (.+) to \1$/d'

# H
# P
# T


# 
# git merge-base --fork-point bar foo

# # parent
# git show-branch | \
#     grep '*' | \
#     grep -v \"$(git rev-parse --abbrev-ref HEAD)\" | \
#     head -n1 | \
#     perl -pE 's/^.+?\\[([^\\]]+).+$/\\1/g'

# # hash
# git rev-parse HEAD

# # name
# git rev-parse --abbrev-ref HEAD

