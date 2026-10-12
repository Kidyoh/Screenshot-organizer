#!/usr/bin/env bash
# Recreates the Android release signing files from environment secrets, so any
# fresh checkout or CI run signs with the same key (in-place updates depend on
# it). Does nothing if the secrets aren't set.
#
#   ANDROID_KEYSTORE_BASE64    base64 of the .jks keystore
#   ANDROID_KEYSTORE_PASSWORD  store and key password
#   ANDROID_KEY_ALIAS          key alias (default: snapsort)
set -euo pipefail
cd "$(dirname "$0")/../android"

if [ -z "${ANDROID_KEYSTORE_BASE64:-}" ] || [ -z "${ANDROID_KEYSTORE_PASSWORD:-}" ]; then
  echo "No signing secrets set; builds will use the debug key."
  exit 0
fi

echo "$ANDROID_KEYSTORE_BASE64" | base64 -d > snapsort-release.jks
cat > key.properties <<PROPS
storeFile=../snapsort-release.jks
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyPassword=$ANDROID_KEYSTORE_PASSWORD
keyAlias=${ANDROID_KEY_ALIAS:-snapsort}
PROPS
echo "Release signing configured."
