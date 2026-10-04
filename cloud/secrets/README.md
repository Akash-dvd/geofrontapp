# Local secrets (optional)

JSON files under this directory are an **optional local stash only**.

They are **not loaded by application runtime code**. Production Cloudflare Worker
secrets are set with Wrangler:

```bash
cd cloud/edge_worker
wrangler secret put OPENAI_API_KEY --env production
wrangler secret put SUPABASE_JWT_SECRET --env production
wrangler secret put SUPABASE_ANON_KEY --env production
```

Or run `setup.ps1` from this folder (same Wrangler puts, including `OPENAI_API_KEY`).

Copy examples if you want a personal local reference:

```bash
cp openai_key.json.example openai_key.json   # edit locally; gitignored
```

Do not commit real `*.json` secret files.
