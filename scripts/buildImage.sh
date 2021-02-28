#!/bin/sh

. "$(dirname "$0")/../scripts/common.sh"

image_name="jq-action"

while [ $# -gt 0 ]; do
    case $1 in
        -i|--image)
            shift;
            image_name="$1"
            shift;
            ;;
    esac
done

echo "Building image..."
docker image build -t "${image_name}" .  | indent
return $?
