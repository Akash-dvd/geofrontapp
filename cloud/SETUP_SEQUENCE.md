# Edge Gateway Setup Sequence

This guide assumes the Flutter web bundle will be deployed to Cloudflare Pages and that the Ubuntu solver host exposes your private backend.

## 1. Prepare Supabase

1. Export a Postgres connection string with row-level security enabled:
   ```bash
   export SUPABASE_DB_URL="postgres://postgres:[password]@db.[project].supabase.co:5432/postgres"
   ```
2. Reset the `problems` table (drops any legacy `images`/`problems` schema and recreates it with Supabase-native RLS, presets, and column grants):
   ```bash
   ./scripts/reset_problems_schema.sh
   ```
3. (Optional) Apply the sample `posts` table policies if you need the demo content referenced in docs:
   ```bash
   ./scripts/apply_supabase_policies.sh
   ```
   This creates the `posts` table (if missing), enforces `auth.uid()` policies, and grants access to the `authenticated` role.

## 2. Configure the Cloudflare Tunnel (Ubuntu solver host)

1. Install dependencies:
   ```bash
   sudo apt update && sudo apt install -y cloudflared jq
   ```
2. Set the hostname you want to expose and optional overrides:
   ```bash
   export TUNNEL_HOSTNAME="solver.example.com"
   export LOCAL_SERVICE_URL="http://localhost:8000"
   export TUNNEL_NAME="solver-edge"   # optional
   ```
3. Run the helper:
   ```bash
   ./scripts/configure_tunnel.sh
   ```
   The script logs into Cloudflare (if needed), creates the tunnel, and writes a config under `~/.cloudflared/`.
4. Start the tunnel as a foreground process to verify connectivity:
   ```bash
   cloudflared tunnel run "${TUNNEL_NAME:-solver-edge}"
   ```
   Once confirmed, you can create a systemd service to keep it running.

## 3. Configure Worker Secrets

Run these commands from the `edge_worker` directory after authenticating with Wrangler (`wrangler login`). Replace the placeholder values with your project secrets.

```bash
wrangler secret put SUPABASE_JWT_SECRET
wrangler secret put OPENAI_API_KEY
```

If your Supabase GraphQL endpoint or tunnel URL differs from the defaults in `wrangler.toml`, update the `[vars]` section before deployment.

## 4. Deploy the Cloudflare Worker

1. Install Node.js 18+ and Wrangler (`npm i -g wrangler`).
2. From the project root:
   ```bash
   ./scripts/deploy_worker.sh
   ```
   The script installs npm dependencies (if needed) and runs `wrangler deploy --env production` using the configuration in `edge_worker/wrangler.toml`.
3. Verify the routes are returning expected responses:
   * `GET https://api.example.com/graphql` → expects 401 without Supabase token.
   * `POST https://api.example.com/llm` → proxies to OpenAI with Worker-managed key.
   * `POST https://api.example.com/solver` → proxies to the tunnel endpoint.

## 5. Frontend Updates

1. Update the Flutter web app to use the new API base URL (e.g., `https://api.example.com`).
2. Exchange Firebase Auth for Supabase Auth in the client. Ensure the Supabase access token is attached to `/graphql` requests as `Authorization: Bearer <token>`.
3. Redeploy the Flutter build to Cloudflare Pages or your hosting platform.

## 6. Validation Checklist

- [ ] Supabase policies return expected rows for different users.
- [ ] Tunnel hostname resolves and proxies traffic securely.
- [ ] Worker routes enforce authentication only on `/graphql`.
- [ ] LLM and solver integrations respond successfully end-to-end.
- [ ] Monitoring and logging are enabled (Cloudflare Worker analytics, Supabase logs).

Once all boxes are checked, the edge-first architecture is live. Maintain the scripts under `cloud/scripts/` for repeatable setup on new environments.
