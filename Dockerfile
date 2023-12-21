FROM alpine:latest

COPY entrypoint.sh /entrypoint.sh
COPY encode.sh /encode.sh
COPY decode.sh /decode.sh

RUN apk add jq bash git

ENTRYPOINT ["/entrypoint.sh"]
