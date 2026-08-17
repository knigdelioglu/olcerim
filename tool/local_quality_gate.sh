#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
if [[ -n "$MODE" && "$MODE" != "--full" ]]; then
  echo "Kullanım: bash ./tool/local_quality_gate.sh [--full]" >&2
  exit 2
fi

for command in flutter dart; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "$command CLI bulunamadı." >&2
    exit 1
  fi
done

echo "== Flutter =="
flutter --version

echo "== Platform runnerları =="
bash ./tool/bootstrap_platforms.sh

echo "== Bağımlılıklar =="
flutter pub get

echo "== Launcher iconları =="
bash ./tool/generate_app_icons.sh

echo "== Drift kaynakları =="
dart run build_runner build --delete-conflicting-outputs

echo "== Analyze =="
flutter analyze || dart analyze

echo "== Tests =="
flutter test --reporter expanded

if [[ "$MODE" == "--full" ]]; then
  echo "== Android APK =="
  flutter build apk --release

  echo "== Android App Bundle =="
  flutter build appbundle --release

  echo "== iOS unsigned release =="
  flutter build ios --release --no-codesign

  echo "== macOS release =="
  flutter build macos --release
fi

echo "Local quality gate tamamlandı."
