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

> **Configuration:** [`cloud-compose.yaml`](cloud-compose.yaml)

### :house: Home server "PMS"

- Central *ARR services (Sonarr, Radarr, Readarr, SABnzbd, qBittorrent …)
- Media storage on a NAS (NFSv4 mount)
- Connection to the Hetzner server via Tailscale

> **Configuration:** [`home-compose.yaml`](home-compose.yaml)

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
- Mount NAS Drive via NFS (best with fstab, so it automatically mounts on boot)

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
POSTGRESQL_PORT=5432
VALKEY_PORT=6379
GLUETUN_CONTROL_PORT=8000
WEBUI_PORT_QBITTORRENT=8200
TP_THEME=organizr-dark

# Authentik DB settings (used by authentik-worker/postgres)
AUTHENTIK_VERSION=latest
AUTHENTIK_SECRET_KEY=change-me-very-secret
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
- Watchtower updates images automatically (already label-configured in the cloud).
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