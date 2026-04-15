#!/usr/bin/env bash
# Check if vendored skills have drifted from upstream.
# Reads recorded SHA from skills/UPSTREAM.md and compares to upstream main.
# Exit code 0 = up to date, 1 = drift detected.

set -euo pipefail

UPSTREAM_OWNER="avifenesh"
UPSTREAM_REPO="glide-mq"
TRACKER="skills/UPSTREAM.md"

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] gh CLI required" >&2
  exit 2
fi

if [ ! -f "$TRACKER" ]; then
  echo "[ERROR] $TRACKER not found" >&2
  exit 2
fi

RECORDED_SHA=$(grep -oE '`[a-f0-9]{40}`' "$TRACKER" | head -1 | tr -d '`')
RECORDED_VERSION=$(grep -oE '`v[0-9]+\.[0-9]+\.[0-9]+`' "$TRACKER" | head -1 | tr -d '`')

UPSTREAM_SHA=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/commits/main" -q .sha 2>/dev/null)
UPSTREAM_DATE=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/commits/main" -q .commit.author.date 2>/dev/null)
UPSTREAM_VERSION=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/package.json?ref=$UPSTREAM_SHA" -q .content 2>/dev/null \
  | base64 -d | grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)

if [ "$RECORDED_SHA" = "$UPSTREAM_SHA" ]; then
  echo "[OK] Vendored skills are at upstream HEAD (v$RECORDED_VERSION, $RECORDED_SHA)"
  exit 0
fi

# Count commits behind
BEHIND=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/compare/$RECORDED_SHA...$UPSTREAM_SHA" -q .ahead_by 2>/dev/null || echo "?")

echo "[DRIFT] Vendored skills are behind upstream"
echo "  Recorded:  $RECORDED_VERSION ($RECORDED_SHA)"
echo "  Upstream:  v$UPSTREAM_VERSION ($UPSTREAM_SHA)"
echo "  Behind by: $BEHIND commits (as of $UPSTREAM_DATE)"
echo ""
echo "Run: ./scripts/sync-upstream.sh"
exit 1
