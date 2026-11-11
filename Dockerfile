FROM oven/bun:alpine

ENV LANG=C.UTF-8

WORKDIR /app

RUN apk add --no-cache openssl curl jq unzip \
    && bun install -g @bitwarden/cli

ARG TARGETARCH
ARG BWS_VERSION=2.1.0
RUN case "${TARGETARCH:-amd64}" in \
      "amd64") BWS_ARCH="x86_64" ;; \
      "arm64") BWS_ARCH="aarch64" ;; \
      *) BWS_ARCH="x86_64" ;; \
    esac && \
    wget -q "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${BWS_VERSION}/bws-${BWS_ARCH}-unknown-linux-musl-${BWS_VERSION}.zip" -O /tmp/bws.zip \
    && unzip /tmp/bws.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/bws \
    && rm /tmp/bws.zip

COPY backup.sh /app/backup.sh

# Rimuove eventuale BOM e forza terminatori LF (compatibilita Windows/Linux)
RUN sed -i -e '1s/^\xef\xbb\xbf//' -e 's/\r$//' /app/backup.sh \
    && chmod +x /app/backup.sh

ENTRYPOINT ["/app/backup.sh"]
