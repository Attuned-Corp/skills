#!/usr/bin/env bash
# Check if the Span skill is configured with a valid auth token.
# Also checks API version compatibility if metadata has been fetched.
#
# Outputs one of:
#   "not configured"
#   "configured"
#   "configured | api version mismatch (expected: X, detected: Y) — update the skill"
#
# SECURITY: This script's output is injected into the LLM prompt via
# dynamic context injection (!`command`). It must NEVER output the token
# or any sensitive data. We use jq 'has()' to check for the key's
# existence without reading its value.

SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if ! [ -f "$SPAN_DIR/auth.json" ] || ! jq -e 'has("token")' "$SPAN_DIR/auth.json" > /dev/null 2>&1; then
  echo "not configured"
  exit 0
fi

# Check API version compatibility
EXPECTED=$(tr -d '[:space:]' < "$SCRIPT_DIR/api-version" 2>/dev/null || echo "")
DETECTED=$(tr -d '[:space:]' < "$SPAN_DIR/api-version-detected" 2>/dev/null || echo "")

if [ -n "$DETECTED" ] && [ "$EXPECTED" != "$DETECTED" ]; then
  echo "configured | api version mismatch (expected: $EXPECTED, detected: $DETECTED) — update the skill"
else
  echo "configured"
fi
