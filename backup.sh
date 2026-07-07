#!/bin/sh
set -eu

BW_SERVER="${BW_SERVER:-https://vault.bitwarden.com}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
ENCRYPTION_KEY="${ENCRYPTION_KEY:-}"

: "${BW_PASSWORD:?BW_PASSWORD non impostata}"
: "${BW_CLIENTID:?BW_CLIENTID non impostata}"
: "${BW_CLIENTSECRET:?BW_CLIENTSECRET non impostata}"

ERROR_LOG=$(mktemp /tmp/backup_error.XXXXXX)
exec 2>"$ERROR_LOG"

send_webhook() {
    status="$1"
    message="$2"
    if [ -n "$WEBHOOK_URL" ]; then
        body=$(printf '{"status":"%s","message":"%s","date":"%s"}' \
            "$status" "$message" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")")
        curl -s --connect-timeout 10 --max-time 30 \
            -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "$body" || true
    fi
}

error_handler() {
    exit_code=$?
    error_msg=$(tail -3 "$ERROR_LOG" 2>/dev/null | tr '\n' ' ' || true)
    send_webhook "error" "Backup fallito: ${error_msg}(exit: ${exit_code})"
}

trap error_handler ERR
trap 'bw lock 2>/dev/null || true; bw logout 2>/dev/null || true; rm -f "$ERROR_LOG"' EXIT

echo ""
echo "Configurazione server..."
bw config server "$BW_SERVER"

echo ""
echo "Login con API key..."
bw login --apikey

echo ""
echo "Sblocco vault..."
BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
export BW_SESSION

echo ""
echo "Sincronizzazione vault..."
bw sync

DATE=$(date +"%Y-%m-%d_%H-%M")
FILENAME="bitwarden_${DATE}"
OUTPUT_FILE="/backups/${FILENAME}.json"

echo ""
echo "Export vault..."
bw export \
    --format json \
    --output "$OUTPUT_FILE"

echo ""
echo "Backup completato: ${FILENAME}.json"

if [ -n "$ENCRYPTION_KEY" ]; then
    echo ""
    echo "Crittografia AES-256..."
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$OUTPUT_FILE" \
        -out "${OUTPUT_FILE}.enc" \
        -pass env:ENCRYPTION_KEY
    openssl dgst -sha256 "${OUTPUT_FILE}.enc" > "${OUTPUT_FILE}.enc.sha256"
    rm -f "$OUTPUT_FILE"
    echo "Backup crittografato: ${FILENAME}.json.enc"
    ls -t /backups/*.json.enc 2>/dev/null | tail -n +31 | xargs -r rm -f || true
    ls -t /backups/*.json.enc.sha256 2>/dev/null | tail -n +31 | xargs -r rm -f || true
else
    echo ""
    echo "Backup non crittografato"
    ls -t /backups/*.json 2>/dev/null | tail -n +31 | xargs -r rm -f || true
fi

send_webhook "success" "Backup completato con successo!"
echo ""
echo "Fine"
