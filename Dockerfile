FROM alpine:latest

COPY entrypoint.sh /entrypoint.sh
COPY encode.sh /encode.sh

RUN apk add jq bash

ENTRYPOINT ["/entrypoint.sh"]
