FROM oven/bun:alpine

ENV LANG=C.UTF-8

WORKDIR /app

# Installa Bitwarden CLI, openssl (crittografia), curl (webhook), jq (JSON parsing), unzip (bws install)
RUN apk add --no-cache openssl curl jq unzip \
    && bun install -g @bitwarden/cli

# Installa Bitwarden Secrets Manager CLI (bws)
ARG BWS_VERSION=2.1.0
RUN wget -q "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${BWS_VERSION}/bws-x86_64-unknown-linux-musl-${BWS_VERSION}.zip" -O /tmp/bws.zip \
    && unzip /tmp/bws.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/bws \
    && rm /tmp/bws.zip

COPY backup.sh /app/backup.sh

RUN chmod +x /app/backup.sh

ENTRYPOINT ["/app/backup.sh"]