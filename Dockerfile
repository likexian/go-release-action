FROM golang:1.18-alpine

LABEL "com.github.actions.name"="Go Release Action"
LABEL "com.github.actions.description"="Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions."
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="blue"

LABEL name="Go Release Action"
LABEL description="Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions."
LABEL version="v0.2.0"
LABEL repository="https://github.com/likexian/go-release-action"
LABEL homepage="https://github.com/likexian/go-release-action"
LABEL maintainer="https://www.likexian.com"

RUN apk update && apk add --no-cache curl sed jq git bash tar zip build-base

COPY entrypoint.sh /usr/sbin/entrypoint.sh

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
