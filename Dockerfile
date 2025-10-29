FROM alpine:latest

RUN apk add bash curl jq git coreutils

WORKDIR /app
COPY bin/jsonld-parser.sh .
RUN chmod +x jsonld-parser.sh
ENTRYPOINT ["./jsonld-parser.sh"]
