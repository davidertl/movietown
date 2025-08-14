diff --git a/README.md b/README.md
# movietown

<p align="center">
	<img src="https://img.shields.io/badge/docker-compose-blue?logo=docker" alt="Docker Compose">
	<img src="https://img.shields.io/badge/mediastack-guide-green" alt="MediaStack Guide">
</p>

Repository for my media stack, based on [mediastack.guide](https://mediastack.guide). It contains Docker Compose files for both cloud and home environments.

---

## :building_construction: Architecture

### :cloud: Cloud @ Hetzner

- **Auth stack:** Authentik incl. PostgreSQL & Valkey
- **Media:** Jellyfin & Plex (exposed via ports)
- **Automatic updates:** Watchtower
- **Networking:** Connection to the home network via Tailscale

> **Konfiguration:** [`cloud-compose.yaml`](cloud-compose.yaml)

### :house: Home server "PMS"

- Central *ARR services (Sonarr, Radarr, Readarr, SABnzbd, qBittorrent ...)
- Media storage on a Synology NAS
- Connection to the Hetzner server via Tailscale
- Only Jellyfin, Plex & Authentik are exposed publicly

> **Konfiguration:** [`home-compose.yaml`](home-compose.yaml)

---

## :rocket: Usage

1. Create a `.env` file with all required variables (see comments in the compose files)
2. Start the environment:
	 ```bash
	 docker compose -f cloud-compose.yaml up -d
	 docker compose -f home-compose.yaml up -d
	 ```
3. Connect both servers via Tailscale

---

## :information_source: Notes

- This repository contains **only** compose files; secrets and domain configurations are managed externally.
- For questions or further planning, see [mediastack.guide](https://mediastack.guide).

---

## 🧭 Step-by-step installation

Goal: First deploy the cloud stack and set up Authentik, then configure Tailscale. Use the Tailscale auth key to deploy both stacks (cloud and home).

### 0) Prerequisites

- Docker and Docker Compose on both servers (Hetzner cloud and home server “PMS”)
- DNS/firewall configured appropriately (at least the ports exposed in the compose files)
- A git checkout of this repo on both servers

### 1) Prepare the cloud server (.env)

Create a `.env` file in the repo directory on the cloud server. Example:

```dotenv
# General
TIMEZONE=Europe/Berlin
PUID=1000
PGID=1000
FOLDER_FOR_DATA=/srv/movietown/data

# Network (cloud-compose)
CLOUD_EXTERNAL_SUBNET=10.10.0.0/24
CLOUD_EXTERNAL_GATEWAY=10.10.0.1

# Authentik / databases (cloud)
AUTHENTIK_VERSION=latest
AUTHENTIK_SECRET_KEY=change-me-very-secret
AUTHENTIK_DATABASE=authentik
POSTGRESQL_USERNAME=authentik
POSTGRESQL_PASSWORD=change-me-postgres
VALKEY_PORT=6379

# Ports (cloud)
WEBUI_PORT_AUTHENTIK=9000
COMPOSE_PORT_HTTPS=9443

# Optional: For running Tailscale inside a container (tsdproxy)
# If you choose this approach, set the auth key here
# TAILSCALE_AUTH_KEY=tskey-xxxxxxxxxxxxxxxx
```

### 2) Deploy the cloud stack (Authentik)

```bash
docker compose -f cloud-compose.yaml up -d
```

Wait until `postgresql` and `valkey` are healthy and both `authentik`/`authentik-worker` are running.

Optionally check:

```bash
docker compose -f cloud-compose.yaml ps
docker compose -f cloud-compose.yaml logs -f authentik
```

### 3) Set up Authentik

- Open `https://<CLOUD-HOST>:9443` (or `http://<CLOUD-HOST>:9000`) and follow the setup wizard
- Create an admin user; set base URL and email configuration (optional)
- Integration with services (Jellyfin, Plex, *ARR) is possible later but optional here

### 4) Set up Tailscale and create an auth key

1. Sign into Tailscale with your own account.
2. In the Tailscale admin create a “Reusable Auth Key”.
3. Two options to use the auth key:
	- Host-based: Install Tailscale on the home server and join using the auth key.
	- Container-based: Use `tsdproxy`. Set `TAILSCALE_AUTH_KEY` in `.env` and enable the `tsdproxy` service (used this way in the cloud so we can also access via PublicIP:Port).

### 5) Prepare the home server (.env)

Fill the `.env` file on the home server. Example:

```dotenv
# General
TIMEZONE=Europe/Berlin
PUID=1000
PGID=1000
FOLDER_FOR_DATA=/srv/movietown/data
FOLDER_FOR_MEDIA=/mnt/media

# Services (home-compose)
POSTGRESQL_PORT=5432
VALKEY_PORT=6379
GLUETUN_CONTROL_PORT=8000
WEBUI_PORT_QBITTORRENT=8200
TP_THEME=organizr-dark

# For Tailscale in a container (tsdproxy)
TAILSCALE_AUTH_KEY=tskey-xxxxxxxxxxxxxxxx
```

### 6) Deploy both stacks with Tailscale


- Cloud
- Add Tailscale Auth Key to Cloud `.env` file:



```bash
docker compose -f cloud-compose.yaml up -d
# to verify
docker compose -f cloud-compose.yaml ps
```

- Home:

```bash
docker compose -f home-compose.yaml up -d
# to verify
docker compose -f home-compose.yaml ps
```

Check:

```bash
docker compose -f home-compose.yaml ps
```

### 7) Verify & next steps

- Ensure services are reachable (over Tailscale IP/name and the exposed ports).
- Watchtower updates images automatically (already label-configured in the cloud).
- Integrate services with Authentik (SSO) as needed, set up DNS/reverse proxy, and plan backups (still a fair bit of work).


