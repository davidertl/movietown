# movietown

<p align="center">
  <img src="https://img.shields.io/badge/docker-compose-blue?logo=docker" alt="Docker Compose">
  <img src="https://img.shields.io/badge/variant-mediastack.guide-green" alt="MediaStack Guide Variant">
</p>

A two-site media stack variant inspired by <a href="https://mediastack.guide" target="_blank">mediastack.guide</a>, split into:
- Cloud: central identity (Authentik IdP/SSO), minimal footprint, private-by-default networking
- Home: *ARR automation, download clients, VPN isolation, local/NAS media storage

This repo provides Docker Compose files for both locations, example environment files, and a step-by-step flow.

---

## Overview

- Private-by-default: access over Tailscale; public ports kept minimal
- Two stacks:
  - Cloud: Authentik with PostgreSQL + Valkey, Watchtower, optional containerised Tailscale via tsdproxy
  - Home: Sonarr/Radarr/Readarr/Lidarr/Prowlarr/Bazarr, qBittorrent/SABnzbd, Gluetun (VPN), Tailscale, Watchtower optional
- Clear flow (“red line”):
  1) Deploy cloud stack
  2) Complete Authentik setup
  3) Configure Tailscale and create an auth key
  4) Deploy both stacks using that key

Differences to mediastack.guide:
- Split topology (cloud + home) bridged by Tailscale, rather than single-host
- Authentik SSO included by default
- Favors Tailnet access and VPN isolation over a public reverse proxy
- Minimal, focused compose files and .env samples

---

## What’s included

- cloud-compose.yaml
  - Authentik + worker
  - PostgreSQL and Valkey
  - Watchtower
  - tsdproxy (containerised Tailscale) optional
- home-compose.yaml
  - Gluetun (VPN)
  - *ARR apps and download clients (placeholders in the compose)
  - Optional Watchtower

Example env files:
- cloud.example.env
- home.example.env

Note: Some services in the compose files are placeholders or WIP; adjust to your environment and hardware.

---

## Prerequisites

- Two hosts (e.g., Cloud VPS and Home server/NAS)
- Docker Engine and Docker Compose plugin on both
- Git checkout of this repo on both
- Optional: NAS exports mounted on Home (e.g., NFSv4)
- Firewall rules for any ports you decide to expose

---

## Quick start (the red line)

1) Cloud: copy env and edit
- Copy cloud.example.env to .env on the cloud host and edit values:
  - TIMEZONE, PUID/PGID, FOLDER_FOR_DATA
  - AUTHENTIK_*, POSTGRESQL_*, VALKEY_*
  - TAILSCALE_AUTH_KEY if using containerised Tailscale via tsdproxy

2) Deploy cloud stack
```
docker compose -f cloud-compose.yaml up -d
```
- Wait for PostgreSQL/Valkey healthy and authentik/authentik-worker running

3) Complete Authentik setup
- Open the Authentik UI (use the ports you exposed; defaults in your env)
- Finish bootstrap (admin, base URL, email optional)
- You can integrate services later

4) Create a Tailscale auth key
- In Tailscale admin, create a reusable auth key
- Decide:
  - Containerised (default in cloud via tsdproxy): set TAILSCALE_AUTH_KEY in .env
  - Host-based: install Tailscale on the host and disable tsdproxy in the compose

5) Home: copy env and edit
- Copy home.example.env to .env on the home host and edit values:
  - TIMEZONE, PUID/PGID, UMASK
  - FOLDER_FOR_DATA, FOLDER_FOR_MEDIA
  - Network subnets/gateways for docker networks
  - Service ports (*ARR, qBittorrent, etc.)
  - AUTHENTIK_* (if needed), VPN_* for Gluetun
  - TAILSCALE_AUTH_KEY if using containerised Tailscale

6) Deploy both stacks
```
docker compose -f cloud-compose.yaml up -d
docker compose -f home-compose.yaml up -d
```

7) Verify and next steps
- Access services via Tailnet names/IPs or the exposed ports you configured
- Configure *ARR apps, indexers, and download clients
- Optionally add SSO integrations with Authentik
- Consider Tailscale ACLs for fine-grained access control

---

## Configuration notes

- Environment files:
  - Use cloud.example.env and home.example.env as a base
  - Validate your env before running:
    - Cloud: docker compose -f cloud-compose.yaml --env-file .env config
    - Home:  docker compose -f home-compose.yaml  --env-file .env config
- Networking:
  - Ensure subnets/gateways do not overlap with your LAN/VPN ranges
  - Gluetun enforces a VPN egress for media automation as needed
- Tailscale/tsdproxy:
  - If you use host-based Tailscale on the cloud host, disable/remove tsdproxy from cloud-compose.yaml
  - If you keep tsdproxy, TAILSCALE_AUTH_KEY is required

---

## Services (typical)

- Cloud
  - Authentik (IdP/SSO)
  - PostgreSQL, Valkey
  - Watchtower
  - tsdproxy (optional)
- Home
  - Sonarr, Radarr, Readarr, Lidarr, Prowlarr, Bazarr
  - qBittorrent, SABnzbd
  - Gluetun (VPN)
  - Watchtower (optional)

Adjust ports in your env files; by default *ARR services are not publicly exposed.

---

## Security model

- Private-by-default via Tailscale
- Optional SSO with Authentik for web apps
- Optionally add a reverse proxy and certificates as needed
- Use Tailscale ACLs (tags/groups) to restrict access across devices

---

## Troubleshooting

- Use logs:
  - docker compose -f cloud-compose.yaml logs -f
  - docker compose -f home-compose.yaml logs -f
- Validate env and config:
  - docker compose -f <file> --env-file .env config
- Common issues:
  - Overlapping CIDRs between Docker subnets, LAN, and VPN
  - Missing TAILSCALE_AUTH_KEY when tsdproxy is enabled
  - Incorrect file permissions for host bind mounts (PUID/PGID/UMASK)

---

## Credits

- Based on concepts from mediastack.guide
- Thanks to the upstream projects: Authentik, *ARR suite, Gluetun, Tailscale, Watchtower