# Release Image =============================================================
FROM alpine:latest as build

COPY entrypoint.sh /entrypoint.sh

RUN apk add jq bash 

ENTRYPOINT ["/entrypoint.sh"]

