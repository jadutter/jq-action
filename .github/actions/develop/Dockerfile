FROM alpine:latest

COPY entrypoint.sh /entrypoint.sh

RUN apk add jq bash git

ENTRYPOINT ["/entrypoint.sh"]

