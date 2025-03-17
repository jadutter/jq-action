#!/bin/bash
dir="${0%/*}/"
name="jq"
docker image build $dir -t "$name" 
docker run -it --entrypoint /bin/bash "$name"
