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
  <a href="https://github.com/haveagitgat/tdarr">
    <img src="https://img.shields.io/badge/Transcoding-Tdarr-3B82F6" alt="Tdarr">
  </a>
  <a href="https://github.com/flaresolverr/flaresolverr">
    <img src="https://img.shields.io/badge/Utility-Flaresolverr-4F46E5" alt="Flaresolverr">
  </a>
  <a href="https://github.com/ajnart/homarr">
    <img src="https://img.shields.io/badge/Dashboard-Homarr-F97316" alt="Homarr">
  </a>
  <a href="https://github.com/jellyfin/jellyfin">
    <img src="https://img.shields.io/badge/Media-Jellyfin-00a4dc?logo=jellyfin&logoColor=white" alt="Jellyfin">
  </a>
  <a href="https://github.com/plexinc/pms-docker">
    <img src="https://img.shields.io/badge/Media-Plex-e5a00d?logo=plex&logoColor=white" alt="Plex">
  </a>
</p>


**A mediastack.guide-inspired media stack** with a privacy-first split architecture. This repository contains Docker Compose files for both cloud and home environments, optimized for Tailscale-based networking and data sovereignty.

## Inspiration & Attribution

This project is inspired by [**mediastack.guide**](https://mediastack.guide) by [@geekau](https://github.com/geekau/mediastack). We leverage their excellent research into *ARR automation, media server setup, and Docker best practices. Visit their [GitHub repository](https://github.com/geekau/mediastack) and [documentation](https://mediastack.guide) for the comprehensive single/multi-host reference implementation.

## Why this variant

While mediastack.guide is a fantastic all-in-one reference, I wanted a privacy-first approach:
- **Data sovereignty**: All media and downloads stay on home hardware; only identity provider and public media servers in the cloud
- **Tailscale-first**: Rather than exposing *ARR services via reverse proxy, they're private to the Tailnet by default
- **Split topology**: Separates concerns (cloud: auth + media serving; home: automation + storage) for better flexibility
- **Minimal exposure**: No need for public DNS/DDNS or reverse proxies for internal services

---
### Project summary
- Two-site media stack connected via Tailscale: storage and *ARR at home, public entry point in the cloud.
  - Cloud: Authentik (IdP/SSO) with PostgreSQL and Valkey, Watchtower, optional containerized Tailscale (tsdproxy), and media servers (Jellyfin + Plex).
  - Home: *ARR apps (Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr), qBittorrent and SABnzbd, traffic routed through Gluetun (VPN); media can be stored either directly on the home server or on a local NAS mounted via NFSv4. Authentik runs only in the cloud; home runs an Authentik worker.
- Private-by-default: *ARR services are reachable over the Tailnet; Jellyfin/Plex are exposed from the cloud host.
- Install guide: Deploy the cloud stack and complete Authentik setup → configure Tailscale and create an auth key → deploy both stacks using that key → integrate SSO as needed.

### How movietown differs from mediastack.guide

| Aspect | movietown | mediastack.guide |
|--------|-----------|------------------|
| **Topology** | Split cloud + home via Tailscale | Single/multi-host; monolithic or separated |
| **Public Access** | Minimal (media servers only) | Reverse proxy (Traefik) + Nginx optional |
| **Internal Services** | Private via Tailnet ACLs | Internal/home network or reverse proxy |
| **Data Storage** | Home-only (sovereignty) | Flexible; typically central |
| **VPN Approach** | Full/mini/custom Gluetun config | Full/mini/no-download-vpn templates |
| **Overlay Network** | Tailscale + tsdproxy (containerized) | Optional Headscale or native Tailscale |
| **Authentication** | Authentik (mandatory) | Optional; Cloudflare, etc. |
| **Tailscale Model** | Public Tailscale (simpler) | **Headscale option** (self-hosted) |
| **Database** | PostgreSQL/Valkey for Authentik | Same, but optional |
| **Scope** | Focused two-site architecture | Comprehensive reference |

**When to use each:**
- **movietown**: Privacy-conscious users, home lab, wanting Tailnet-first access, data stored at home
- **mediastack.guide**: Public media server, family access via reverse proxy, single/multi-host flexibility, comprehensive guides

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
# Clone this repository (replace 'yourusername' with your GitHub username)
git clone https://github.com/yourusername/movietown.git
cd movietown

# Make the setup script executable
chmod +x setup.sh

# Run the setup script
./setup.sh
```

The script will:
- Install Git if needed
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

## :information_source: References & Resources

- **mediastack.guide**: [Documentation](https://mediastack.guide) | [GitHub](https://github.com/geekau/mediastack)
  - Comprehensive guide for all-in-one media stack setup
  - Detailed per-service configuration guides
  - Network security models (full/mini/no-VPN)
  - Original inspiration for this variant

- This repository contains **compose files optimized for privacy-first two-site setup**; secrets and domain configurations are managed via `.env` files.

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
AUTHENTIK_STORAGE__MEDIA_ROOT=/data/media
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
6. Optional: Set up **Homarr** dashboard for unified service management.

Notes:

- The *ARR apps are by default **not** publicly exposed in the home stack. Access is local or via Tailscale/VPN.
- Authentik (SSO) integration can be added after basic setup.
- **Tdarr** enables automatic video transcoding and optimization (CPU-intensive; optional).
- **Flaresolverr** bypasses Cloudflare protection on torrent/usenet indexers; configured in Prowlarr settings.
- **Homarr** provides a beautiful dashboard to manage and monitor all services from one UI.

---

## :lock: Security & Best Practices

### Database Security (PostgreSQL)

- **Default passwords**: Change `POSTGRESQL_PASSWORD` from `change-me-postgres` to a strong random value
- **Access control**: PostgreSQL is only accessible from within the Tailnet; cloud-only (not exposed)
- **Backups**: Regularly backup `/srv/movietown/data/postgres` directory (persistent volume)
  ```bash
  sudo docker exec postgres pg_dump -U authentik authentik > backup-$(date +%Y%m%d).sql
  ```

### VPN & Network Privacy

- **Gluetun firewall**: All *ARR and download services route through Gluetun VPN
  - If VPN connection drops, traffic stops (fail-safe)
  - Verify VPN status: `docker exec gluetun /bin/sh -c "wget -qO- ifconfig.io"`
- **Local subnet**: Ensure `LOCAL_SUBNET` in `.env` matches your home LAN (e.g., `192.168.0.0/16`)
- **Kill switch**: Gluetun enforces outbound firewall rules; no leaks if VPN dies

### Authentik & SSO Security

- **Secret key**: Keep `AUTHENTIK_SECRET_KEY` unique and secure (32+ chars, random)
- **Admin user**: Create a strong password during initial setup
- **MFA**: Enable Multi-Factor Authentication for all Authentik users (TOTP recommended)
- **Session timeout**: Configure session policies in Authentik to auto-logout after inactivity

### Tailscale ACLs & Access Control

- **Default deny**: Set ACLs to deny by default; explicitly allow access to services
- **Tag devices**: Use tags (e.g., `tag:admin`, `tag:family`) for granular control
- **Example restrictive policy**:
  ```json
  {
    "ACLs": [
      {
        "Action": "accept",
        "Users": ["group:admins"],
        "Ports": ["tag:movietown-cloud:9443", "tag:movietown-home:8989"]
      },
      {
        "Action": "accept",
        "Users": ["group:family"],
        "Ports": ["tag:movietown-cloud:8096"]  // Jellyfin only
      }
    ]
  }
  ```

### Container Security

- **Run as non-root**: All services run with `PUID/PGID` (1000:1000); never use root
- **Read-only volumes**: Consider marking config volumes read-only after setup
- **Update strategy**: Watchtower auto-updates images; disable with `WATCHTOWER_LABEL_ENABLE=true` if preferred

### Backup & Disaster Recovery

- **What to backup**:
  - `/srv/movietown/data` (configs, databases, Authentik credentials)
  - `/mnt/media` (media library)
  - `.env` files (encrypted or secure storage)

- **Recovery steps**:
  1. Restore `/srv/movietown/data` on new host
  2. Set `.env` values
  3. Run `docker compose -f cloud-compose.yaml up -d`
  4. Verify Authentik login works

- **Automated backups**: Use `restic`, `duplicacy`, or NAS snapshots for incremental backups

### Optional: CrowdSec Integration (Advanced)

For production cloud deployments with public exposure, consider adding **CrowdSec** (DDoS/intrusion detection):

- See [mediastack.guide CrowdSec guide](https://mediastack.guide/config/crowdsec-introduction/) for detailed setup
- Integrates with Traefik bouncer plugin to block malicious IPs
- Requires CrowdSec account enrollment

### Monitoring (Optional)

For operational visibility, consider adding:
- **Prometheus + Grafana**: Metrics collection and visualization
- **Loki**: Centralized log aggregation
- **Portainer**: Docker container management UI

Reference: [mediastack.guide monitoring options](https://mediastack.guide)

---


## :globe_with_meridians: Networking: Tailscale vs. Headscale (Self-Hosted)

movietown uses **public Tailscale** by default for simplicity. However, for self-hosted alternatives:

### Tailscale (Default)
- ✅ **Pros**: Zero setup, OIDC support, official app updates, mobile clients, relay infrastructure
- ❌ **Cons**: Depends on Tailscale infrastructure, account required, privacy concerns for some
- **Setup**: Get an auth key from [tailscale.com](https://tailscale.com), set `TAILSCALE_AUTH_KEY` in `.env`

### Headscale (Self-Hosted Alternative)
- ✅ **Pros**: Full control, no external service dependency, privacy-focused, air-gapped capable
- ❌ **Cons**: More complex setup, maintenance required, fewer features than Tailscale
- **Reference**: See [Headscale documentation](https://headscale.net/) and [mediastack.guide Headscale section](https://mediastack.guide/config/headscale-configuration/)
- **Integration**: Would replace `tsdproxy` service config to point to self-hosted Headscale server

**Recommendation**: Start with public Tailscale for ease; migrate to Headscale if you have operational capacity or strict privacy requirements.

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

---

## :gear: Configuration Notes

- **Environment files**: Use `cloud.env.example` and `home.env.example` as templates, then copy to `.env` on each host
  - Validate your env before running: `docker compose -f <file> --env-file .env config`
  
- **Networking**:
  - Ensure subnets/gateways do not overlap with your LAN/VPN ranges
  - Gluetun enforces a VPN egress for *ARR services
  
- **Authentik worker** (home): Set `AUTHENTIK_REDIS__HOST` and `AUTHENTIK_POSTGRESQL__HOST` to the cloud host or tsdproxy names

- **Tailscale/tsdproxy**:
  - If using host-based Tailscale on cloud, disable/remove tsdproxy from cloud-compose.yaml
  - If keeping tsdproxy, `TAILSCALE_AUTH_KEY` is required

---

## 📋 What's Included

**Docker Compose Files:**
- `cloud-compose.yaml` - Authentik, PostgreSQL, Valkey, Jellyfin, Plex, Watchtower, tsdproxy
- `home-compose.yaml` - Gluetun, *ARR apps, download clients, Tdarr, Flaresolverr, Homarr, Authentik worker

**Setup & Configuration:**
- `setup.sh` - Automated installation script for fresh Debian/Ubuntu servers
- `cloud.env.example` - Cloud stack environment template
- `home.env.example` - Home stack environment template
- `.gitignore` - Prevents committing sensitive `.env` files

**Configuration Files:**
- `traefik.yaml` - Reverse proxy configuration (optional; for cloud public access)
- `traefik-config.yaml` - Dynamic routing template (optional)

---

## 🚀 Services Included

**Cloud Stack:**
- Authentik (IdP/SSO) + worker + PostgreSQL + Valkey
- Jellyfin (media server)
- Plex (media server, optional)
- Traefik (reverse proxy, optional)
- Watchtower (auto-updates)
- tsdproxy (containerized Tailscale)

**Home Stack:**
- Gluetun (VPN client with kill switch)
- Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr (*ARR automation)
- qBittorrent (torrent client)
- SABnzbd (usenet client)
- Jellyseerr (media request interface)
- Filebot (media file automation)
- Mylar (comic automation)
- Tdarr (video transcoding)
- Flaresolverr (Cloudflare bypass)
- Homarr (service dashboard)
- Authentik worker (connects to cloud)
- Watchtower (auto-updates, optional)

---

## 🔧 Troubleshooting

- **Check logs**: 
  ```bash
  docker compose -f cloud-compose.yaml logs -f
  docker compose -f home-compose.yaml logs -f
  ```

- **Validate configuration**:
  ```bash
  docker compose -f <file> --env-file .env config
  ```

- **Common issues**:
  - Overlapping CIDRs between Docker subnets, LAN, and VPN
  - Missing `TAILSCALE_AUTH_KEY` when tsdproxy is enabled
  - Incorrect file permissions (check `PUID`/`PGID`/`UMASK`)
  - PostgreSQL volume mount path (must be `/var/lib/postgresql` not `/var/lib/postgresql/data`)

---

## 📖 Further Reading

- [mediastack.guide documentation](https://mediastack.guide) - Comprehensive reference guide
- [Authentik docs](https://docs.goauthentik.io/) - Identity provider setup
- [Tailscale docs](https://tailscale.com/kb/) - VPN & networking
- [Gluetun docs](https://github.com/qdm12/gluetun/wiki) - VPN client configuration
- [*ARR project wikis](https://wiki.servarr.com/) - Media automation setup

---

## 📝 License

This project is provided as-is for personal use. Refer to individual project licenses for component-specific terms.

## 🙏 Credits

- Based on concepts and best practices from [mediastack.guide](https://mediastack.guide) by [@geekau](https://github.com/geekau)
- Built with: Authentik, *ARR suite, Gluetun, Jellyfin, Plex, Tailscale, Traefik, Watchtower, and many other fantastic open-source projects
