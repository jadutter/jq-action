FROM alpine:latest

COPY ./tests tests
COPY ./entrypoint.sh entrypoint.sh

RUN apk add jq bash git

ENTRYPOINT ["/entrypoint.sh"]
