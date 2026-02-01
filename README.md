# movietown

<p align="center">
  <a href="https://docs.docker.com/compose/">
    <img src="https://img.shields.io/badge/docker-compose-blue?logo=docker" alt="Docker Compose">
  </a>
  <a href="https://github.com/geekau/mediastack-guide">
    <img src="https://img.shields.io/badge/variant-mediastack.guide-green" alt="MediaStack Guide Variant">
  </a>
  <br/>
  <!-- Cloud -->
  <a href="https://github.com/goauthentik/authentik">
    <img src="https://img.shields.io/badge/IdP-Authentik-5b8cfa" alt="Authentik">
  </a>
  <a href="https://github.com/postgres/postgres">
    <img src="https://img.shields.io/badge/DB-PostgreSQL-336791?logo=postgresql&logoColor=white" alt="PostgreSQL">
  </a>
  <a href="https://github.com/valkey-io/valkey">
    <img src="https://img.shields.io/badge/Cache-Valkey-d82c20" alt="Valkey">
  </a>
  <a href="https://github.com/containrrr/watchtower">
    <img src="https://img.shields.io/badge/Updates-Watchtower-2f77d0" alt="Watchtower">
  </a>
  <a href="https://github.com/tailscale/tailscale">
    <img src="https://img.shields.io/badge/Overlay-Tailscale-262626?logo=tailscale&logoColor=white" alt="Tailscale">
  </a>
  <a href="https://github.com/almeidapaulopt/tsdproxy">
    <img src="https://img.shields.io/badge/Tailscale-tsdproxy-262626" alt="tsdproxy">
  </a>
  <br/>
  <!-- Home -->
  <a href="https://github.com/qdm12/gluetun">
    <img src="https://img.shields.io/badge/VPN-Gluetun-3776AB" alt="Gluetun">
  </a>
  <a href="https://github.com/Sonarr/Sonarr">
    <img src="https://img.shields.io/badge/Automation-Sonarr-1f8acb" alt="Sonarr">
  </a>
  <a href="https://github.com/Radarr/Radarr">
    <img src="https://img.shields.io/badge/Automation-Radarr-f5c518" alt="Radarr">
  </a>
  <a href="https://github.com/Readarr/Readarr">
    <img src="https://img.shields.io/badge/Automation-Readarr-ff6f61" alt="Readarr">
  </a>
  <a href="https://github.com/Lidarr/Lidarr">
    <img src="https://img.shields.io/badge/Automation-Lidarr-0db7ed" alt="Lidarr">
  </a>
  <a href="https://github.com/Prowlarr/Prowlarr">
    <img src="https://img.shields.io/badge/Automation-Prowlarr-6a5acd" alt="Prowlarr">
  </a>
  <a href="https://github.com/morpheus65535/bazarr">
    <img src="https://img.shields.io/badge/Subtitles-Bazarr-ffcc00" alt="Bazarr">
  </a>
  <a href="https://github.com/qbittorrent/qBittorrent">
    <img src="https://img.shields.io/badge/BT-qBittorrent-2D7DB3" alt="qBittorrent">
  </a>
  <a href="https://github.com/sabnzbd/sabnzbd">
    <img src="https://img.shields.io/badge/NZB-SABnzbd-ffa000" alt="SABnzbd">
  </a>
  <a href="https://github.com/jellyfin/jellyfin">
    <img src="https://img.shields.io/badge/Media-Jellyfin-00a4dc?logo=jellyfin&logoColor=white" alt="Jellyfin">
  </a>
  <a href="https://github.com/plexinc/pms-docker">
    <img src="https://img.shields.io/badge/Media-Plex-e5a00d?logo=plex&logoColor=white" alt="Plex">
  </a>
</p>


Repository for my media stack, based on [mediastack.guide](https://mediastack.guide). It contains Docker Compose files for both cloud and home environments.

## Why this stack
I wanted to deploy mediastack but had privacy concerns. Cloudflared would have been my first choice, but streaming violates their TOS. I ended up using Tailscale instead.

---
### Project summary
- Two-site media stack connected via Tailscale: storage and *ARR at home, public entry point in the cloud.
  - Cloud: Authentik (IdP/SSO) with PostgreSQL and Valkey, Watchtower, optional containerized Tailscale (tsdproxy), and media servers (Jellyfin + Plex).
  - Home: *ARR apps (Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr), qBittorrent and SABnzbd, traffic routed through Gluetun (VPN); media can be stored either directly on the home server or on a local NAS mounted via NFSv4. Authentik runs only in the cloud; home runs an Authentik worker.
- Private-by-default: *ARR services are reachable over the Tailnet; Jellyfin/Plex are exposed from the cloud host.
- Install guide: Deploy the cloud stack and complete Authentik setup → configure Tailscale and create an auth key → deploy both stacks using that key → integrate SSO as needed.

### Differences to mediastack.guide
- Topology: Split into two stacks (cloud + home) bridged by Tailscale, whereas mediastack.guide is primarily single-host oriented.
- SSO: Authentik is included by default, so you can create a login for your family (please check your local laws ;-) )
- Exposure model: Prefers Tailscale/tsdproxy and Gluetun tunneling over a public reverse proxy, reducing open ports.
- Security stance: Tailnet-first with ACLs for fine-grained access control.
- Compose structure: Minimal, split compose files with focused scope vs. a larger, opinionated monolithic stack.

## :building_construction: Architecture

### :cloud: Cloud @ Hetzner

- **Auth stack:** Authentik incl. PostgreSQL & Valkey
- **Media:** Jellyfin & Plex (exposed via ports)
- **Automatic updates:** Watchtower
- **Networking:** Connection to the home network via Tailscale

> **Configuration:** [`cloud-compose.yaml`](cloud-compose.yaml)

### :house: Home server "PMS"

- Central *ARR services (Sonarr, Radarr, Readarr, SABnzbd, qBittorrent …)
- Authentik worker (connects to cloud PostgreSQL/Valkey)
- Media storage on a NAS (NFSv4 mount)
- Connection to the Hetzner server via Tailscale

> **Configuration:** [`home-compose.yaml`](home-compose.yaml)

---

## :rocket: Quick Start

### Automated Installation (Recommended)

Use the automated setup script for easy deployment on fresh Debian/Ubuntu servers:

```bash
# Clone this repository
git clone https://github.com/yourusername/movietown.git
cd movietown

# Make the setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

The script will:
- Install Docker and Docker Compose if needed
- Detect and guide you through cloud or home deployment
- Create and configure your `.env` file with generated secrets
- Set up all required directories
- Validate your configuration
- Optionally start the stack

If you prefer manual setup, see the detailed [step-by-step installation guide](#-step-by-step-installation) below.

1. Create a `.env` file with all required variables (see example files)
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

## 🧭 Step-by-step installation (Manual)

> **💡 Tip:** For faster deployment, use the [automated setup script](#automated-installation-recommended) instead.

Goal: First deploy the cloud stack and set up Authentik, then configure Tailscale. Use the Tailscale auth key to deploy both stacks (cloud and home).

### 0) Prerequisites

- Docker and Docker Compose are installed on both servers 

[Documentation for Docker @ docs.docker.com](https://docs.docker.com/engine/install/debian/) (for reference)

Skip this, if docker is installed!
```
# Uninstall conflicting packages
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

- Firewall configured appropriately (at least the ports exposed in the compose files)
- A git checkout of this repo on both servers
- Mount NAS Drive via NFS on the Home-Server (best with fstab, so it automatically mounts on boot)

### 1) Prepare the cloud server (.env)

Create a `.env` file in the repo directory on the cloud server. Example:

```dotenv
# General
TIMEZONE=Europe/Berlin
PUID=1000
PGID=1000
FOLDER_FOR_DATA=/srv/movietown/data
FOLDER_FOR_MEDIA=/srv/movietown/media

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
WEBUI_PORT_JELLYFIN=8096
WEBUI_PORT_PLEX=32400

# Plex (optional)
PLEX_CLAIM=

# Database ports (cloud)
POSTGRESQL_PORT=5432
VALKEY_PORT=6379

# Tailscale in container (tsdproxy)
# cloud-compose enables tsdproxy by default; this key is REQUIRED unless you remove/disable the service
TAILSCALE_AUTH_KEY=tskey-xxxxxxxxxxxxxxxx
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
  - Host-based: Install Tailscale on the host and join using the auth key. If you choose this for the cloud server, remove or disable the `tsdproxy` service in `cloud-compose.yaml`.
  - Container-based (default in cloud-compose): Use `tsdproxy`. Set `TAILSCALE_AUTH_KEY` in `.env`. This allows access via PublicIP:Port routed through Tailscale.

### 5) Prepare the home server (.env)

Fill the `.env` file on the home server. Example:

```dotenv
# General
TIMEZONE=Europe/Berlin
PUID=1000
PGID=1000
FOLDER_FOR_DATA=/srv/movietown/data
FOLDER_FOR_MEDIA=/mnt/media

# Docker networks (required by home-compose networks)
DOCKER_SUBNET=172.23.0.0/16
DOCKER_GATEWAY=172.23.0.1
INTERNAL_SUBNET=172.24.0.0/16
INTERNAL_GATEWAY=172.24.0.1

# Services (home-compose)
GLUETUN_CONTROL_PORT=8000
WEBUI_PORT_QBITTORRENT=8200
TP_THEME=organizr-dark

# Authentik worker settings (Authentik runs in the cloud)
AUTHENTIK_VERSION=latest
AUTHENTIK_SECRET_KEY=change-me-very-secret
AUTHENTIK_REDIS__HOST=authentik-redis.your-tailnet.ts.net
AUTHENTIK_POSTGRESQL__HOST=authentik-db.your-tailnet.ts.net
AUTHENTIK_DATABASE=authentik
POSTGRESQL_USERNAME=authentik
POSTGRESQL_PASSWORD=change-me-postgres

# For Tailscale in a container (tsdproxy)
TAILSCALE_AUTH_KEY=tskey-xxxxxxxxxxxxxxxx

# Gluetun/VPN (required)
UMASK=002
VPN_SERVICE_PROVIDER=custom
VPN_USERNAME=your_vpn_username
VPN_PASSWORD=your_vpn_password
LOCAL_SUBNET=192.168.0.0/16
#DO NOT FORGET THE OPENVPN config file :-)
```

### 6) Deploy both stacks with Tailscale

- Cloud:
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

### 7) Verify & next steps

- Ensure services are reachable (over Tailscale IP/name and the exposed ports).
- Watchtower updates images automatically (label filtering is disabled by default).
- Integrate services with Authentik (SSO) as needed, set up DNS/reverse proxy, and plan backups.

---

## :gear: Setup of the *ARR apps

The *ARR services (Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr) are available after starting the home compose stack on the ports defined in `home-compose.yaml`.
Detailed setup guidance is available in the [*ARR section on mediastack.guide](https://mediastack.guide) and the respective project docs:

- [Sonarr](https://sonarr.tv/#download)
- [Radarr](https://radarr.video/#download)
- [Readarr](https://readarr.com)
- [Lidarr](https://lidarr.audio)
- [Prowlarr](https://wiki.servarr.com/prowlarr)
- [Bazarr](http://www.bazarr.media/)

Recommended setup order:

1. Configure **Prowlarr** and connect your indexers (Usenet, torrents).
2. Link **Sonarr / Radarr / Readarr / Lidarr** to Prowlarr (sync indexers automatically).
3. Add download clients (qBittorrent, SABnzbd) in the *ARR apps.
4. Configure quality profiles, release profiles, and media paths.
5. Optional: Enable subtitle automation with Bazarr.

Notes:

- The *ARR apps are by default **not** publicly exposed in the home stack. Access is local or via Tailscale/VPN.
- Authentik (SSO) integration can be added after basic setup.

---

## :lock: Tailscale ACLs (tag/group-based)

With Tailscale ACLs you can precisely control which devices and services in your media stack are reachable. This greatly improves security, especially if you have devices in the same tailnet that shouldn’t access the *ARR services.

Suggested steps:

1. In the Tailscale admin, open the **ACL configuration**.
2. Define tags for servers/services (e.g., `tag:home-arr`).
3. Assign these tags to groups (e.g., `group:arr-admins`).
4. Create rules such as:

```json
{
  "ACLs": [
    {
      "Action": "accept",
      "Users": ["group:arr-admins"],
      "Ports": ["tag:home-arr:7878", "tag:home-arr:8989", "tag:home-arr:9696"]
    }
  ],
  "TagOwners": {
    "tag:home-arr": ["group:arr-admins"]
  },
  "Groups": {
    "group:arr-admins": ["device1", "device2"]
  }
}
```

Benefits:
- Access only for defined groups/tags
- Additional protection alongside Authentik and any reverse proxy
- Simple management across multiple sites/networks
