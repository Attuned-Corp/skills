#!/usr/bin/env bash
# Check if a newer version of the skill is available on GitHub.
#
# Outputs one of:
#   "version: <local>  (up to date)"
#   "version: <local>  (update available: <remote>)"
#   "version: <local>  (unable to check for updates)"
#
# Uses the GitHub raw content URL to fetch the latest VERSION file.
# Requires curl. Timeout is kept short (5s) so this never blocks long.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REPO_RAW_URL="https://raw.githubusercontent.com/Attuned-Corp/skills/main/skills/ask/VERSION"

LOCAL_VERSION=$(tr -d '[:space:]' < "$SKILL_DIR/VERSION" 2>/dev/null || echo "unknown")

if [ "$LOCAL_VERSION" = "unknown" ]; then
  echo "version: unknown  (VERSION file missing)"
  exit 0
fi

REMOTE_VERSION=$(curl -sf --max-time 5 "$REPO_RAW_URL" 2>/dev/null | tr -d '[:space:]')

if [ -z "$REMOTE_VERSION" ]; then
  echo "version: $LOCAL_VERSION  (unable to check for updates)"
  exit 0
fi

if [ "$LOCAL_VERSION" = "$REMOTE_VERSION" ]; then
  echo "version: $LOCAL_VERSION  (up to date)"
else
  echo "version: $LOCAL_VERSION  (update available: $REMOTE_VERSION)"
fi
