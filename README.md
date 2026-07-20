# Bitwarden Backup

Backup automatico e sicuro del vault Bitwarden in container Docker, con crittografia AES-256, notifiche webhook e supporto per l'esecuzione tramite n8n.

## Funzionalità

- **Export automatico** del vault Bitwarden in formato JSON
- **Crittografia AES-256** opzionale del backup con chiave da variabile d'ambiente
- **Notifica webhook** opzionale su successo o fallimento
- **Login via API key** (`BW_CLIENTID` / `BW_CLIENTSECRET`), senza esporre la password master in rete
- **Rotazione automatica** degli ultimi 30 backup con eliminazione dei più vecchi
- **Server auto-osped** supportato tramite variabile `BW_SERVER`

## Variabili d'ambiente

| Variabile | Obbligatoria | Descrizione |
|-----------|-------------|-------------|
| `BW_PASSWORD` | Sì | Password master del vault Bitwarden |
| `BW_CLIENTID` | Sì | Client ID dell'API key (da `Impostazioni → Chiavi API`) |
| `BW_CLIENTSECRET` | Sì | Client Secret dell'API key |
| `BW_SERVER` | No | URL del server Bitwarden (default: `https://vault.bitwarden.com`) |
| `ENCRYPTION_KEY` | No | Chiave per crittografia AES-256 del backup (se omessa, backup in chiaro) |
| `WEBHOOK_URL` | No | URL del webhook per notifiche (POST JSON con `status`, `message`, `date`) |

## Utilizzo

```bash
cp .env.example .env
# modifica .env con i tuoi dati
docker compose up -d
```

Il container esegue il backup, si ferma e Docker lo riavvia secondo la policy `restart: unless-stopped`.

### n8n

Il container esegue lo script una sola volta e poi esce, quindi è compatibile con n8n. Usa un nodo **Docker** in n8n per eseguire `docker run bitwarden-backup` su base schedulata. Il webhook può essere usato come trigger per ricevere l'esito.

### Decrittografia del backup

```bash
KEY_HASH=$(printf '%s' "$ENCRYPTION_KEY" | sha256sum | cut -d' ' -f1)
openssl enc -d -aes-256-cbc -pbkdf2 \
    -in backup.json.enc \
    -out backup.json \
    -pass pass:"$KEY_HASH"
```

```powershell
# Windows (PowerShell)
$KEY_HASH = (Get-FileHash -Algorithm SHA256 -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($env:ENCRYPTION_KEY)))).Hash.ToLower()
openssl enc -d -aes-256-cbc -pbkdf2 -in backup.json.enc -out backup.json -pass "pass:$KEY_HASH"
```

Verifica integrità:

```bash
sha256sum -c backup.json.enc.sha256
```

```powershell
# Windows (PowerShell)
$hash = (Get-FileHash -Algorithm SHA256 backup.json.enc).Hash.ToLower()
$expected = (Get-Content backup.json.enc.sha256).Split(' ')[0]
if ($hash -eq $expected) { "OK" } else { "FAILED: hash mismatch" }
```

## Sicurezza

- La password master viene usata **solo localmente** per sbloccare il vault, mai trasmessa in rete
- L'autenticazione avviene tramite API key (revocabili e ruotabili indipendentemente)
- La chiave di crittografia viene normalizzata con SHA-256 prima dell'uso, evitando problemi di encoding tra sistemi diversi
- Il file `.env` con le credenziali **non deve** essere incluso nel controllo versione

## Crediti

Progetto sviluppato con il supporto dell'intelligenza artificiale tramite [opencode.ai](https://opencode.ai).
