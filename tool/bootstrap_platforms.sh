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
  --org com.knigdelioglu \
  --project-name olcerim \
  --no-pub \
  "$TMP_DIR/olcerim"

for platform in android ios macos; do
  rm -rf "$platform"
  cp -R "$TMP_DIR/olcerim/$platform" "$platform"
done
cp "$TMP_DIR/olcerim/.metadata" .metadata

PRIVACY_MANIFEST='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>NSPrivacyTracking</key><false/>
<key>NSPrivacyTrackingDomains</key><array/>
<key>NSPrivacyCollectedDataTypes</key><array/>
<key>NSPrivacyAccessedAPITypes</key><array/>
</dict></plist>'
printf '%s\n' "$PRIVACY_MANIFEST" > ios/Runner/PrivacyInfo.xcprivacy
printf '%s\n' "$PRIVACY_MANIFEST" > macos/Runner/PrivacyInfo.xcprivacy

if [[ "$(uname -s)" == "Darwin" ]]; then
  for entitlement in macos/Runner/DebugProfile.entitlements macos/Runner/Release.entitlements; do
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.files.user-selected.read-write bool true" "$entitlement" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :com.apple.security.files.user-selected.read-write true" "$entitlement"
    /usr/libexec/PlistBuddy -c "Add :com.apple.security.print bool true" "$entitlement" 2>/dev/null || /usr/libexec/PlistBuddy -c "Set :com.apple.security.print true" "$entitlement"
  done
fi

echo "Android, iOS ve macOS runnerları com.knigdelioglu.olcerim kimliğiyle üretildi."
