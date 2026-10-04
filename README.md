# geofrontapp

A new Flutter project.

## Supplying keys

See [docs/KEYS.md](docs/KEYS.md) for Cloudflare Worker (`wrangler secret put`),
Flutter (`--dart-define`), and Strapi (`.env`) setup. Optional JSON under
`cloud/secrets/` is gitignored and **not** read by runtime.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.



## Development

### Run in Cloud Mode (Hasura + Supabase)
```bash
flutter run --dart-define=USE_DIRECTUS=false -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

### Run in Local Mode (Directus)
```bash
flutter run --dart-define=USE_DIRECTUS=true -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

### SSH Tunnel (for remote development)
```bash
ssh -L 8081:localhost:8081 -L 9100:localhost:9100 akash@192.168.1.3
```

### Run with Chrome
```bash
flutter run -d chrome --web-port=8081 --web-hostname=0.0.0.0 --web-renderer=html
```

## Deployment

### Build and Deploy to Firebase
```powershell
.\firebase\build-and-deploy.ps1
```

### Build Only
```powershell
.\firebase\build-web.ps1
```

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete deployment guide.

## Test Credentials

- Email: test@example.com
- Password: password123