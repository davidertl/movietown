+# movietown
+
+Dieses Repository enthält die Compose-Dateien für meinen Media-Stack. Grundlage ist [mediastack.guide](https://mediastack.guide) und bildet sowohl die Cloud- als auch die lokale Heim-Umgebung ab.
+
+## Architektur
+
+### Cloud @ Hetzner
+
+- **Auth-Stack**: Authentik inklusive PostgreSQL und Valkey.
+- **Medien**: Jellyfin und Plex laufen hier und sind über geöffnete Ports erreichbar.
+- **Automatisches Update**: Watchtower hält die Container aktuell.
+- **Netzwerk**: Die Verbindung zum Heimnetz erfolgt über Tailscale.
+
+Konfiguration: `cloud-compose.yaml`.
+
+### Heimserver "PMS"
+
+- Läuft lokal und ist der zentrale Host für die *ARR-Dienste (Sonarr, Radarr, Readarr, SABnzbd, qBittorrent usw.).
+- Alle Medien werden auf einem Synology NAS abgelegt.
+- Die Kommunikation zum Hetzner-Server erfolgt über Tailscale.
+- Nur Jellyfin, Plex und Authentik sind von außen erreichbar.
+
+Konfiguration: `home-compose.yaml`.
+
+## Nutzung
+
+1. Lege eine `.env` Datei mit allen Variablen an (siehe Kommentare in den Compose-Dateien).
+2. Starte die Umgebung:
+   ```bash
+   docker compose -f cloud-compose.yaml up -d
+   docker compose -f home-compose.yaml up -d
+   ```
+3. Verbinde beide Server via Tailscale.
+
+## Hinweise
+
+- Das Repository enthält nur die Compose-Dateien; Secrets und Domain-Konfigurationen werden extern verwaltet.
+- Bei Fragen oder zur weiteren Planung siehe die Dokumentation auf mediastack.guide.
+
 
EOF
)