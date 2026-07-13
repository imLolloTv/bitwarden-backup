# Bitwarden Backup

Backup automatico e sicuro del vault Bitwarden in container Docker, con crittografia AES-256, notifiche webhook e recupero password tramite Bitwarden Secrets Manager.

## Funzionalità

- **Export automatico** del vault Bitwarden in formato JSON
- **Crittografia AES-256** opzionale del backup con chiave da variabile d'ambiente
- **Notifica webhook** opzionale su successo o fallimento
- **Login via API key** (`BW_CLIENTID` / `BW_CLIENTSECRET`), senza esporre la password master in rete
- **Password master da Secrets Manager** — nessuna password in chiaro nel file `.env`
- **Rotazione automatica** degli ultimi 30 backup con eliminazione dei più vecchi
- **Server self-hosted** supportato tramite variabile `BW_SERVER`

## Variabili d'ambiente

| Variabile | Obbligatoria | Descrizione |
|-----------|-------------|-------------|
| `BW_CLIENTID` | Sì | Client ID dell'API key (da *Impostazioni → Chiavi API*) |
| `BW_CLIENTSECRET` | Sì | Client Secret dell'API key |
| `BWS_ACCESS_TOKEN` | Sì | Access token del machine account Secrets Manager |
| `BW_SECRET_ID` | Sì | UUID del secret contenente la master password |
| `SM_BASE_URL` | No | URL del server Secrets Manager (default: Bitwarden cloud) |
| `BW_SERVER` | No | URL del server Bitwarden (default: `https://vault.bitwarden.com`) |
| `ENCRYPTION_KEY` | No | Chiave per crittografia AES-256 del backup (se omessa, backup in chiaro) |
| `WEBHOOK_URL` | No | URL del webhook per notifiche (POST JSON con `status`, `message`, `date`) |

## Setup

### 1. Configura Secrets Manager su Bitwarden

1. Nel Web Vault, vai su **Secrets Manager → Project → New Project** (es. `bitwarden-backup`)
2. Crea un **Machine Account** e copia l'**Access Token** (mostrato solo una volta)
3. Assegna il Machine Account al Project con permessi **Read Only**
4. Nel Project, crea un **Secret**: Key = libera (es. `MASTER_PASSWORD`), Value = la tua master password
5. Copia l'**UUID** del Secret (visibile nella lista secrets)

### 2. Configura il container

```bash
cp .env.example .env
# compila .env con i tuoi dati
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

Verifica integrità:

```bash
sha256sum -c backup.json.enc.sha256
```

## Sicurezza

- La password master **non viene mai salvata** nel file `.env` — viene recuperata al volo da Secrets Manager e rimossa dalla memoria dopo l'uso (`unset`)
- L'autenticazione avviene tramite API key (revocabili e ruotabili indipendentemente)
- L'access token di Secrets Manager viene letto da variabile d'ambiente, mai passato come argomento CLI (evita esposizione in `ps`)
- La chiave di crittografia viene normalizzata con SHA-256 prima dell'uso, evitando problemi di encoding tra sistemi diversi
- Il file `.env` con le credenziali **non deve** essere incluso nel controllo versione

## Crediti

Progetto sviluppato con il supporto dell'intelligenza artificiale tramite [opencode.ai](https://opencode.ai).
