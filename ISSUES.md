# Known Issues

## Authentik Initial Setup Fails
**Date:** 2026-02-01
**Status:** Pending Investigation
**Environment:** Cloud server (138.201.204.29)

### Symptoms
- Authentik starts successfully but initial setup/bootstrap fails when accessing the web UI
- Database and worker services are running and healthy

### Next Steps
- Investigate Authentik logs for specific error messages
- May need to configure reverse proxy before initial setup
- Consider if database permissions or environment variables need adjustment

### Related
- Added Traefik reverse proxy to secure data and provide SSL/TLS termination
