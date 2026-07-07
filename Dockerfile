FROM oven/bun:alpine

WORKDIR /app

# Installa Bitwarden CLI, openssl (crittografia) e curl (webhook)
RUN apk add --no-cache openssl curl \
    && bun install -g @bitwarden/cli

COPY backup.sh /app/backup.sh

RUN chmod +x /app/backup.sh

ENTRYPOINT ["/app/backup.sh"]