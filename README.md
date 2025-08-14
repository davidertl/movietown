diff --git a/README.md b/README.md
index e69de29bb2d1d6434b8b29ae775ad8c2e48c5391..e05e1a982ae33f22913620253b5fdc8dca86dfb3 100644
--- a/README.md
+++ b/README.md
@@ -0,0 +1,39 @@

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
+
+- Das Repository enthält nur die Compose-Dateien; Secrets und Domain-Konfigurationen werden extern verwaltet.
+- Bei Fragen oder zur weiteren Planung siehe die Dokumentation auf mediastack.guide.
+
