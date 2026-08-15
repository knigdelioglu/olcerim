#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter CLI bulunamadı." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

flutter create \
  --platforms=android,ios,macos \
  --org com.olcerim \
  --project-name olcerim \
  --no-pub \
  "$TMP_DIR/olcerim"

for platform in android ios macos; do
  rm -rf "$platform"
  cp -R "$TMP_DIR/olcerim/$platform" "$platform"
done

cp "$TMP_DIR/olcerim/.metadata" .metadata

echo "Android, iOS ve macOS runnerları üretildi."
