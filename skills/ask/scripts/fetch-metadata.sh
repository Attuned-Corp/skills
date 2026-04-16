#!/usr/bin/env bash
# Fetch Span API metadata and cache it locally.
# Requires: curl, jq, and a valid auth token in $SPAN_DIR/auth.json.

set -euo pipefail

SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
CLIENT_META=$(cat "$(dirname "$0")/../VERSION")
HEADERS_FILE=$(mktemp)
trap 'rm -f "$HEADERS_FILE"' EXIT

# SECURITY: Token is read inline via jq and passed through a process substitution
# so it never appears as a shell variable or in the process argument list.
curl -s -D "$HEADERS_FILE" -X GET "https://api.span.app/next/metadata/assets" \
  -K <(printf 'header = "Authorization: Bearer %s"' "$(jq -r '.token' "$SPAN_DIR/auth.json")") \
  -H "Content-Type: application/json" \
  -H "x-span-client-meta: $CLIENT_META" > "$SPAN_DIR/metadata-cache.json"

# Cache the API version from response headers for compatibility checking.
API_VERSION=$(grep -i '^Span-Version:' "$HEADERS_FILE" | tr -d '\r' | awk '{print $2}')
if [ -n "$API_VERSION" ]; then
  echo "$API_VERSION" > "$SPAN_DIR/api-version-detected"
fi

echo "Metadata cached to $SPAN_DIR/metadata-cache.json"
