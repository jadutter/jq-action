FROM alpine:latest

COPY ./tests/ /tests/
COPY entrypoint.sh /entrypoint.sh

RUN apk add jq bash

ENTRYPOINT ["/entrypoint.sh"]