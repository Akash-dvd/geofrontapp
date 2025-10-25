# Solver End-to-End Setup (Ubuntu → Cloudflare Tunnel → Worker → Flutter App)

This guide assumes:
- Ubuntu server with the Python solver listening on `http://localhost:5000`
- `cloudflared`, `jq`, `npm`, and `wrangler` installed
- You control the domain `akshara-intelligence.com`
- This repository is checked out at `~/Project/flutter/geofrontapp`

All commands are shown exactly as executed; run them in order.

---

## 1. Prepare the Ubuntu Host

```bash
# Update packages and install prerequisites
sudo apt update && sudo apt install -y cloudflared jq

# Verify solver is running locally
curl http://localhost:5000/graphql -d '{"query":"{ solverStatus { online version } }"}' -H 'Content-Type: application/json'
```

## 2. Authenticate Cloudflared (only once per machine)

```bash
# Launch browser login; select akshara-intelligence.com
cloudflared login
```

If a certificate already exists at `~/.cloudflared/cert.pem`, `cloudflared` will reuse it and warn before overwriting—no further action needed.

## 3. Create/Configure the Tunnel

```bash
# Create the named tunnel once; note the printed UUID (should match the default below)
cloudflared tunnel create solver-tunnel

# Use the project helper script to generate /etc/cloudflared/config.yml with the baked-in values
~/Project/flutter/geofrontapp/cloud/scripts/configure_tunnel.sh
```

ingress:
The script writes:
```yaml
tunnel: 0602f008-c8f8-4bf7-abb5-a558c3c34363
credentials-file: /home/akash/.cloudflared/0602f008-c8f8-4bf7-abb5-a558c3c34363.json

ingress:
  - hostname: solver.aksharaintelligence.com
    service: http://localhost:5000
  - service: http_status:404
```

Map DNS to the tunnel:
```bash
cloudflared tunnel route dns solver-tunnel solver.aksharaintelligence.com
```

## 4. Install and Start the Cloudflared Service

```bash
sudo cloudflared service install
sudo systemctl enable --now cloudflared
sudo systemctl status cloudflared --no-pager
```

Validate the public endpoint:
```bash
curl https://solver.akshara-intelligence.com/graphql \
  -d '{"query":"{ solverStatus { online version } }"}' \
  -H 'Content-Type: application/json'
```

## 5. Point the Cloudflare Worker at the Tunnel

Update `cloud/edge_worker/wrangler.toml` (already tracked in git) so both `vars` blocks contain:
```toml
SOLVER_TUNNEL_URL = "https://solver.akshara-intelligence.com/graphql"
```

Deploy the worker using the Windows PowerShell script:
```powershell
Set-Location -Path "C:\Users\skdwi\OneDrive\Documents\Project\flutter\geofrontapp\cloud\scripts"
.\deploy_worker.ps1 -Env production
```

Confirm the worker proxies correctly:
```bash
curl https://edge-gateway-production.akshara-intelligence.workers.dev/solver \
  -d '{"query":"{ solverStatus { online version } }"}' \
  -H 'Content-Type: application/json'
```

## 6. Run the Flutter App in Cloud Mode

```bash
cd ~/Project/flutter/geofrontapp
flutter run \
  --dart-define=USE_DIRECTUS=false \
  --dart-define=EDGE_SOLVER_ENDPOINT=https://edge-gateway-production.akshara-intelligence.workers.dev/solver
```

Inside the app, use the **Run solver** button to send proofs through the worker/tunnel path.

---

### Troubleshooting Snapshot
- Tunnel status: `cloudflared tunnel info solver-tunnel`
- Worker logs: `npx wrangler tail --env production`
- Flutter config printout: `flutter run ... --dart-define=PRINT_CONFIG=true` (if you wire it up)
