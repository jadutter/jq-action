FROM alpine:latest

RUN mkdir -p /app/

WORKDIR /app

COPY entrypoint.sh /app/entrypoint.sh

RUN apk add jq bash

ENTRYPOINT ["/app/entrypoint.sh"]