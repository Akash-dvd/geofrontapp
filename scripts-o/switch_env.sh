#!/usr/bin/env bash
# Environment switcher for GeoFront hybrid backend
# Usage:
#   ./scripts/switch_env.sh local run    - Switch to local Directus and run
#   ./scripts/switch_env.sh cloud run    - Switch to cloud Hasura+Supabase and run
#   ./scripts/switch_env.sh local build web  - Build for web with local config
#   ./scripts/switch_env.sh cloud build apk  - Build APK with cloud config

set -e

MODE=$1
ACTION=$2
BUILD_TARGET=$3

if [[ "$MODE" != "local" && "$MODE" != "cloud" ]]; then
  echo "❌ Usage: $0 {local|cloud} {run|build} [build_target]"
  echo "Examples:"
  echo "  $0 local run"
  echo "  $0 cloud run"
  echo "  $0 cloud build web"
  echo "  $0 cloud build apk --release"
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 Switching to $MODE mode..."

# Copy appropriate env file
if [[ "$MODE" == "local" ]]; then
  if [[ ! -f ".env.local" ]]; then
    echo "❌ .env.local not found. Create it first with your local Directus config."
    exit 1
  fi
  cp .env.local .env
  USE_DIRECTUS="true"
  echo "✅ Copied .env.local → .env (USE_DIRECTUS=true)"
else
  if [[ ! -f ".env.cloud" ]]; then
    echo "❌ .env.cloud not found. Create it first with your Hasura+Supabase config."
    exit 1
  fi
  cp .env.cloud .env
  USE_DIRECTUS="false"
  echo "✅ Copied .env.cloud → .env (USE_DIRECTUS=false)"
fi

# Run pub get to refresh dependencies
echo "📦 Running flutter pub get..."
flutter pub get

# Execute requested action
if [[ "$ACTION" == "run" ]]; then
  echo "🚀 Running app with USE_DIRECTUS=$USE_DIRECTUS..."
  flutter run --dart-define=USE_DIRECTUS=$USE_DIRECTUS
elif [[ "$ACTION" == "build" ]]; then
  if [[ -z "$BUILD_TARGET" ]]; then
    echo "❌ Build target required. Example: build web, build apk, build ios"
    exit 1
  fi
  echo "🏗️  Building $BUILD_TARGET with USE_DIRECTUS=$USE_DIRECTUS..."
  # For production builds, always force USE_DIRECTUS=false regardless of mode
  if [[ "$MODE" == "cloud" ]]; then
    flutter build $BUILD_TARGET --dart-define=USE_DIRECTUS=false ${@:4}
  else
    flutter build $BUILD_TARGET --dart-define=USE_DIRECTUS=$USE_DIRECTUS ${@:4}
  fi
  echo "✅ Build complete!"
else
  echo "❌ Unknown action: $ACTION. Use 'run' or 'build'."
  exit 1
fi
