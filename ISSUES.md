# Known Issues

## Authentik Initial Setup Fails ✅ RESOLVED
**Date:** 2026-02-01  
**Status:** Resolved - See Solution  
**Environment:** Cloud server (138.201.204.29)

### Symptoms (Previously Observed)
- Authentik starts successfully but initial setup/bootstrap fails when accessing the web UI
- "Not Found" error when trying to access initial setup

### Solution
The Authentik initial setup URL **MUST include a trailing forward slash**. 

Use this exact URL format:
```
http://<your-server-ip>:9000/if/flow/initial-setup/
```

**Important:** The trailing `/` at the end is required. Without it, you will get a 404 Not Found error.

### Related
- Traefik reverse proxy added to secure data and provide SSL/TLS termination
- Setup script updated with correct Authentik URL instructions

