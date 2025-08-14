diff --git a/README.md b/README.md
# movietown

<p align="center">
	<img src="https://img.shields.io/badge/docker-compose-blue?logo=docker" alt="Docker Compose">
	<img src="https://img.shields.io/badge/mediastack-guide-green" alt="MediaStack Guide">
</p>

Repository für meinen Media-Stack, basierend auf [mediastack.guide](https://mediastack.guide). Enthält Docker Compose-Dateien für Cloud- und Heim-Umgebung.

---

## :building_construction: Architektur

### :cloud: Cloud @ Hetzner

- **Auth-Stack:** Authentik inkl. PostgreSQL & Valkey
- **Medien:** Jellyfin & Plex (über Ports erreichbar)
- **Automatisches Update:** Watchtower
- **Netzwerk:** Verbindung zum Heimnetz via Tailscale

> **Konfiguration:** [`cloud-compose.yaml`](cloud-compose.yaml)

### :house: Heimserver "PMS"

- Zentrale *ARR-Dienste (Sonarr, Radarr, Readarr, SABnzbd, qBittorrent ...)
- Medienablage auf Synology NAS
- Verbindung zum Hetzner-Server via Tailscale
- Nur Jellyfin, Plex & Authentik von außen erreichbar

> **Konfiguration:** [`home-compose.yaml`](home-compose.yaml)

---

## :rocket: Nutzung

1. `.env` Datei mit allen Variablen anlegen (siehe Kommentare in den Compose-Dateien)
2. Umgebung starten:
	 ```bash
	 docker compose -f cloud-compose.yaml up -d
	 docker compose -f home-compose.yaml up -d
	 ```
3. Beide Server via Tailscale verbinden

---

## :information_source: Hinweise

- Dieses Repository enthält **nur** Compose-Dateien; Secrets & Domain-Konfigurationen werden extern verwaltet.
- Für Fragen oder weitere Planung siehe [mediastack.guide](https://mediastack.guide).

---

## 🧭 Schritt-für-Schritt Installation

Ziel: Zuerst Cloud-Stack deployen und Authentik einrichten, anschließend Tailscale konfigurieren. Mit dem Tailscale Auth-Key beide Stacks (Cloud und Home) deployen.

### 0) Voraussetzungen

- Docker und Docker Compose auf beiden Servern (Cloud bei Hetzner und Heimserver „PMS“)
- DNS/Firewall passend konfiguriert (mind. die in den Compose-Dateien exponierten Ports)
- Ein Git-Checkout dieses Repos auf beiden Servern

### 1) Cloud-Server vorbereiten (.env)

Lege auf dem Cloud-Server eine `.env` im Repo-Verzeichnis an. Beispiel:

```dotenv
# Allgemein
TIMEZONE=Europe/Berlin
PUID=1000
PGID=1000
FOLDER_FOR_DATA=/srv/movietown/data

# Netzwerk (cloud-compose)
CLOUD_EXTERNAL_SUBNET=10.10.0.0/24
CLOUD_EXTERNAL_GATEWAY=10.10.0.1

# Authentik / Datenbanken (cloud)
AUTHENTIK_VERSION=latest
AUTHENTIK_SECRET_KEY=change-me-very-secret
AUTHENTIK_DATABASE=authentik
POSTGRESQL_USERNAME=authentik
POSTGRESQL_PASSWORD=change-me-postgres
VALKEY_PORT=6379

# Ports (cloud)
WEBUI_PORT_AUTHENTIK=9000
COMPOSE_PORT_HTTPS=9443

# Optional: Für Tailscale im Container (tsdproxy) 
# Bleibt vorerst auskommentiert
# TAILSCALE_AUTH_KEY=tskey-xxxxxxxxxxxxxxxx
```


### 2) Cloud-Stack deployen (Authentik)

```bash
docker compose -f cloud-compose.yaml up -d
```

Warte, bis `postgresql` und `valkey` healthy sind und `authentik`/`authentik-worker` laufen.

Optional prüfen:

```bash
docker compose -f cloud-compose.yaml ps
docker compose -f cloud-compose.yaml logs -f authentik
```

### 3) Authentik einrichten

- Öffne `https://<CLOUD-HOST>:9443` (oder `http://<CLOUD-HOST>:9000`), folge dem Setup-Wizard
- Admin-User anlegen, Basis-URL und E-Mail-Konfiguration setzen (optional)
- Spätere Integration mit Diensten (Jellyfin, Plex, *ARR) ist möglich, aber hier optional

### 4) Tailscale einrichten und Auth-Key erstellen

1. Bei Tailscale mit eigenem OAuth anmelden.
2. Im Tailscale Admin einen „Reusable Auth Key“ erzeugen
3. Zwei Optionen zur Nutzung des Auth Keys:
	- Host-basiert : Tailscale auf Heimserver installieren und mit dem Auth Key joinen
	- Container-basiert: `tsdproxy` nutzen. Dafür in `.env` `TAILSCALE_AUTH_KEY` setzen und den `tsdproxy`-Service aktivieren (so in der Cloud genutzt, da wir dort auch über die PublicIP:Port zugreifen wollen

### 5) Heimserver vorbereiten (.env)

Befülle die .env Datei auf dem Heimserver:

Beispiel:

```dotenv
# Allgemein
TIMEZONE=Europe/Berlin
PUID=1000
PGID=1000
FOLDER_FOR_DATA=/srv/movietown/data
FOLDER_FOR_MEDIA=/mnt/media

# Dienste (home-compose)
POSTGRESQL_PORT=5432
VALKEY_PORT=6379
GLUETUN_CONTROL_PORT=8000
WEBUI_PORT_QBITTORRENT=8200
TP_THEME=organizr-dark

# Für Tailscale im Container (tsdproxy)
TAILSCALE_AUTH_KEY=tskey-xxxxxxxxxxxxxxxx
```


### 6) Beide Stacks mit Tailscale deployen

- Cloud .env 

ssh root@cloudserver
```bash
docker compose -f cloud-compose.yaml up -d
#zum überprüfen
docker compose -f cloud-compose.yaml ps
```

- Home:

```bash
docker compose -f home-compose.yaml up -d
#zum überprüfen
docker compose -f home-compose.yaml ps
```

Prüfen:

```bash
docker compose -f home-compose.yaml ps
```

### 7) Verifizieren & nächste Schritte

- Prüfe, dass Dienste reachable sind (über Tailscale-IP/Name und die freigegebenen Ports)
- Watchtower aktualisiert Images automatisch (Cloud bereits label-basiert konfiguriert)
- Dienste nach Bedarf an Authentik anbinden (SSO), DNS/Reverse Proxy einrichten, Backups planen (leider noch ein großer Haufen Arbeit)


