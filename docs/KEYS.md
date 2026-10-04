# Supplying keys

Runtime does **not** read `cloud/secrets/*.json`. Those files are optional local
stashes only (gitignored).

## Cloudflare Worker

```bash
cd cloud/edge_worker
wrangler secret put OPENAI_API_KEY --env production
wrangler secret put SUPABASE_JWT_SECRET --env production
wrangler secret put SUPABASE_ANON_KEY --env production
```

Or from `cloud/secrets/`: run `setup.ps1` (same three puts).

## Flutter

Defaults in `packages/geoapp/lib/config/env_config.dart` are empty / placeholders.
Pass real values with `--dart-define`:

```bash
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=GOOGLE_CLIENT_ID=... --dart-define=GOOGLE_CLIENT_SECRET=... \
  --dart-define=GITHUB_CLIENT_ID=... --dart-define=GITHUB_CLIENT_SECRET=...
```

## Strapi

```bash
cp strapi/.env.example strapi/.env   # fill values
```

Optional local JSON under `cloud/secrets/` is gitignored and not read by the app.
