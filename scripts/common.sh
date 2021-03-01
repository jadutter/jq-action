#!/bin/bash

stderr() {
    echo "$@" >&2
}

escape() {
    cat | sed -E 's/("|\\|\$|\/)/\\\1/g'
}

divider() {
    local character="-"
    local quantity=32

    while [ $# -gt 0 ]; do
        case "$1" in
            -q|--quantity) 
                shift
                quantity="$(echo "$1" | egrep -o '[0-9]+' )"
                shift
                ;;
            -c|--character) 
                shift
                character="$1"
                shift
                ;;
        esac
    done
    if [ "${#character}" -eq 0 ]; then
        character="-"
    fi
    if [ "${#quantity}" -eq 0 ]; then
        quantity=32
    fi
    printf -- "${character}%0.0s" $(seq 1 ${quantity})
    printf '\n' 
}

indentation() {
    local quantity
    local character
    local spareArgs
    while [ $# -gt 0 ]; do
        case "$1" in
            -q|--quantity) 
                shift
                quantity="$(printf "$1" | egrep -o "[0-9]+" )"
                shift
                ;;
            -c|--character) 
                shift
                character="$1"
                shift
                ;;
            *) 
                spareArgs+=" $1"
                shift
                ;;
        esac
    done
    # echo "
    #     quantity '${quantity}'
    #     character '${character}'
    #     spareArgs '${spareArgs}'
    # " | column -t >&2
    if [ "${#character}" -eq 0 ]; then
        character=" "
    fi
    if [ "${#quantity}" -eq 0 ]; then
        quantity=4
    fi

    if [ "${#quantity}" -gt 0 ]; then 
        if [ "${quantity}" -eq 1 ]; then 
            printf "${character}"
        else
            printf "%0.0s${character}" $(seq 1 "${quantity}" )
        fi
    fi
}

indent() {
    local whitespace="$(indentation "$@")"
    # echo "${whitespace}" >&2
    cat | LC_CTYPE=C sed -E "$( echo "s/^/${whitespace}/g")"
}

enclose() {
    # 9532 \u253c
    center="$(printf '\342\224\274' )"
    # 9500 \u251c
    center_left="$(printf '\342\224\234' )"
    # 9508 \u2524
    center_right="$(printf '\342\224\244' )"
    # 9476 \u2504
    horz_dash="$(printf '\342\224\204' )"
    # 9472 \u2500
    horz_solid="$(printf '\342\224\200' )"
    # 9492 \u2514
    lower_left="$(printf '\342\224\224' )"
    # 9496 \u2518
    lower_right="$(printf '\342\224\230' )"
    # 9524 \u2534
    middle_bottom="$(printf '\342\224\264' )"
    # 9516 \u252c
    middle_top="$(printf '\342\224\254' )"
    # 9484 \u250c
    upper_left="$(printf '\342\224\214' )"
    # 9488 \u2510
    upper_right="$(printf '\342\224\220' )"
    # 9478 \u2506
    vert_dash="$(printf '\342\224\206' )"
    # 9474 \u2502
    vert_solid="$(printf '\342\224\202' )"
    local quantity
    local character
    local indentQuantity
    while [ $# -gt 0 ]; do
        case "$1" in
            -q|--quantity) 
                shift
                quantity="$(echo "$1" | egrep -o '[0-9]+' )"
                shift
                ;;
            -i|--indentQuantity) 
                shift
                indentQuantity="$(echo "$1" | egrep -o '[0-9]+' )"
                shift
                ;;
            -c|--character) 
                shift
                character="$1"
                shift
                ;;
        esac
    done
    if [ "${#character}" -eq 0 ]; then
        character=" "
    fi
    if [ "${#quantity}" -eq 0 ]; then
        quantity=32
    fi
    if [ "${#indentQuantity}" -eq 0 ]; then
        indentQuantity=4
    fi
    bar="$(divider --character ${horz_solid} --quantity "${quantity}" )"
    output="$(cat | sed -E "s/(^|\n)/\1${vert_solid} /g")"
    if [ "${#output}" -gt 0 ]; then
        echo "${upper_left}${bar}
$output
${lower_left}${bar}" \
        | indent \
        --quantity "${indentQuantity}" \
        --character "${character}"
    fi
}
