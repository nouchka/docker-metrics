FROM debian:stable-slim
LABEL maintainer="Jean-Avit Promis docker@katagena.com"
LABEL org.label-schema.vcs-url="https://github.com/nouchka/docker-metrics"
LABEL version="latest"

ENV HUB_USER nouchka
##ENV GITHUB_TOKEN

COPY metrics.sh /metrics

RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get -yq --no-install-recommends install curl=* jq=* ca-certificates=* && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
	chmod +x /metrics

ENTRYPOINT [ "/metrics" ]
