FROM alpine:latest

COPY ./tests /tests
COPY ./tests/sample.json /tests/sample.json
COPY ./tests/test_bash.sh /tests/test_bash.sh
COPY ./tests/test_jq.jq /tests/test_jq.jq
COPY entrypoint.sh /entrypoint.sh

RUN apk add jq bash

ENTRYPOINT ["/entrypoint.sh"]