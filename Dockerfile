FROM golang:1.19

LABEL "com.github.actions.name"="Go Release Action"
LABEL "com.github.actions.description"="Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions."
LABEL "com.github.actions.icon"="package"
LABEL "com.github.actions.color"="blue"

LABEL name="Go Release Action"
LABEL description="Automate publishing Go build binary artifacts to GitHub releases through GitHub Actions."
LABEL version="v0.5.0"
LABEL repository="https://github.com/likexian/go-release-action"
LABEL homepage="https://github.com/likexian/go-release-action"
LABEL maintainer="https://www.likexian.com"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
    bash curl wget git tar zip jq sed ca-certificates build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/sbin/entrypoint.sh

ENTRYPOINT ["/usr/sbin/entrypoint.sh"]
