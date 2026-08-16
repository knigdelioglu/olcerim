#!/usr/bin/env bash
set -euo pipefail

if ! command -v dart >/dev/null 2>&1; then
  echo "Dart CLI bulunamadı." >&2
  exit 1
fi

if [[ ! -f assets/brand/olcerim-app-icon.png ]]; then
  echo "Canonical app icon bulunamadı: assets/brand/olcerim-app-icon.png" >&2
  exit 1
fi

for platform_dir in android ios macos; do
  if [[ ! -d "$platform_dir" ]]; then
    echo "$platform_dir runner bulunamadı. Önce ./tool/bootstrap_platforms.sh çalıştırın." >&2
    exit 1
  fi
done

dart run flutter_launcher_icons

echo "Android, iOS ve macOS launcher iconları canonical kaynaktan üretildi."
