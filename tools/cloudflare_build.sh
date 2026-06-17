#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
else
  export PATH="$(dirname "$(command -v flutter)"):$PATH"
fi

flutter --version
flutter config --enable-web
flutter pub get

flutter build web --release \
  --dart-define=FIREBASE_WEB_API_KEY="${FIREBASE_WEB_API_KEY:-}" \
  --dart-define=FIREBASE_WEB_APP_ID="${FIREBASE_WEB_APP_ID:-}" \
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID="${FIREBASE_WEB_MESSAGING_SENDER_ID:-}" \
  --dart-define=FIREBASE_WEB_PROJECT_ID="${FIREBASE_WEB_PROJECT_ID:-}" \
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN="${FIREBASE_WEB_AUTH_DOMAIN:-}" \
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET="${FIREBASE_WEB_STORAGE_BUCKET:-}"
