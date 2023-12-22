# Release Image =============================================================
FROM alpine:latest as build

COPY entrypoint.sh /entrypoint.sh

RUN apk add jq bash 

ENTRYPOINT ["/entrypoint.sh"]

# Develop Image =============================================================
FROM release_image as dev

COPY tests /tests

RUN apk add git

ENTRYPOINT ["/entrypoint.sh"]
