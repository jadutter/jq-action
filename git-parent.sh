#!/bin/bash

function git-parent(){
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

# execute if not being sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then 
    git-parent $@
fi