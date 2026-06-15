#!/usr/bin/env bash
#
# THE PERSISTENCE CHECKPOINT.
#
# Build + sign Tertius.app TWICE with the same identity and assert that the
# codesign designated requirement (DR) is byte-identical. A stable DR is exactly
# what makes the macOS Accessibility (TCC) grant survive `brew upgrade`: TCC
# keys the grant to the DR, so identical DR ⇒ "same app" ⇒ grant persists.
#
# Usage:  SIGN_IDENTITY="Tertius Self-Signed" [KEYCHAIN=...] scripts/verify-dr-stability.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${SIGN_IDENTITY:?set SIGN_IDENTITY (the self-signed cert CN)}"
EXPECT_ID="io.github.realgarit.tertius"

A="$ROOT/dist/dr-a/Tertius.app"
B="$ROOT/dist/dr-b/Tertius.app"

# Two independent clean builds with the same identity. Native arch is enough —
# the DR depends on the cert + bundle id, not the slice count.
ARCHS=native APP_OUTPUT="$A" "$ROOT/scripts/package-app.sh" >/dev/null
ARCHS=native APP_OUTPUT="$B" "$ROOT/scripts/package-app.sh" >/dev/null

DRA="$(codesign -d --requirements - "$A" 2>&1 | sed -n 's/^designated => //p')"
DRB="$(codesign -d --requirements - "$B" 2>&1 | sed -n 's/^designated => //p')"

echo "Build A designated requirement:"
echo "  $DRA"
echo "Build B designated requirement:"
echo "  $DRB"
echo

if [ -z "$DRA" ]; then
  echo "❌ Could not read a designated requirement (is the app signed?)."
  exit 1
fi

if [ "$DRA" = "$DRB" ] && printf '%s' "$DRA" | grep -q "$EXPECT_ID" && printf '%s' "$DRA" | grep -q "certificate leaf"; then
  echo "✅ DR is STABLE and cert-pinned across builds."
  echo "   The Accessibility grant will persist across brew upgrade."
else
  echo "❌ DR is NOT stable (or not cert-pinned). The grant would break on upgrade."
  exit 1
fi
