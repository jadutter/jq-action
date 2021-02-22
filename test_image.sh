#!/bin/bash

function show_help(){
    cat<<EOF
test_image.sh [OPTIONS]
    Options:
        -h  --help                  show this help message and exit
        -n  --name                  the name to be used for the image and container
        -d  --dir                   the directory where the Dockerfile is located
        -s  --shell                 open the container as an interactive bash shell
        -ns --no-shell              run its entrypoint.sh file as if called by github action
            --disable-autoremove    when the container exits, don't automatically remove it
EOF
}

function test_image(){
    local spare_args=()
    local dir="${0%/*}/"
    local auto_remove="true"
    local name="jq-debian"
    local shell="false"
    local entrypoint
    while [ $# -gt 0 ]; do 
        case $1 in
            -h|--help)
                show_help
                return 0
                ;;
            -n|--name)
                shift
                name="$1"
                shift
                ;;
            -d|--dir)
                if [[ -d "$1" ]]; then 
                    shift
                    dir="$1"
                    shift
                else
                    echo "\"$1\" does not appear to be a valid directory" >&2
                    return 1 
                fi
                ;;
            --disable-autoremove)
                auto_remove="false"
                shift
                ;;
            -s|--shell)
                shell="true"
                shift
                ;;
            -ns|--no-shell)
                shell="false"
                shift
                ;;
            *)
                spare_args+="$1"
                shift
                ;;
        esac
    done
    if [[ "${auto_remove}" == "true" ]]; then 
        auto_remove="--rm"
    else 
        auto_remove=""
    fi 
    if [[ "${shell}" == "true" ]]; then 
        shell="-it"
        entrypoint="--entrypoint /bin/bash"
    else 
        shell=""
        entrypoint=""
    fi 
    docker image build \
        "${dir}" \
        -t "${name}" && \
    INPUT_CMD="jq --version" docker run \
        ${auto_remove} \
        ${shell} \
        ${entrypoint} \
        "${name}"
}
test_image