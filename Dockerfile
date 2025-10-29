FROM alpine:latest

RUN apk add bash curl jq git coreutils github-cli

WORKDIR /stemgraph
COPY bin/jsonld-parser.sh .
RUN chmod +x jsonld-parser.sh
ENTRYPOINT ["./jsonld-parser.sh"]
