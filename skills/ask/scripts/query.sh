#!/usr/bin/env bash
# Query the Span API.
# Usage:
#   query.sh <json-file>                    Query from a JSON file
#   echo '{"select":...}' | query.sh -      Query from stdin
#   query.sh <json-file> [limit] [after]    With optional pagination params
#
# Requires: curl, jq, and a valid auth token in $SPAN_DIR/auth.json.

set -euo pipefail

SPAN_DIR="${SPAN_CONFIG_DIR:-$HOME/.spanrc}"
CLIENT_META=$(cat "$(dirname "$0")/../VERSION")

INPUT="${1:--}"
LIMIT="${2:-}"
AFTER="${3:-}"

# Read query JSON from file or stdin
if [ "$INPUT" = "-" ]; then
  QUERY_JSON=$(cat)
else
  QUERY_JSON=$(cat "$INPUT")
fi

# Build query parameters
PARAMS=""
if [ -n "$LIMIT" ]; then
  PARAMS="?limit=$LIMIT"
fi
if [ -n "$AFTER" ]; then
  if [ -n "$PARAMS" ]; then
    PARAMS="${PARAMS}&after=$AFTER"
  else
    PARAMS="?after=$AFTER"
  fi
fi

# SECURITY: Token is read inline via jq and passed through a process substitution
# so it never appears as a shell variable or in the process argument list.
curl -s -X POST "https://api.span.app/next/assets/query${PARAMS}" \
  -K <(printf 'header = "Authorization: Bearer %s"' "$(jq -r '.token' "$SPAN_DIR/auth.json")") \
  -H "Content-Type: application/json" \
  -H "x-span-client-meta: $CLIENT_META" \
  -d "$QUERY_JSON"
