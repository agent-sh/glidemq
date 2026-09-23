#!/usr/bin/env bash
# Check if vendored skills have drifted from upstream.
# Reads the recorded SHA from skills/UPSTREAM.md and compares it to upstream main.
# Only changes under skills/glide-mq*/ and LICENSE count as drift.
# Exit code 0 = up to date, 1 = drift detected, 2 = error.

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

# Upstream main moves for library changes too; only the vendored trees count.
# Compare git object SHAs of skills/glide-mq*/ and LICENSE at both refs.
vendored_shas() {
  gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/skills?ref=$1" \
    -q '.[] | select(.name | startswith("glide-mq")) | "skills/\(.name) \(.sha)"' || return 1
  gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/LICENSE?ref=$1" -q '"LICENSE \(.sha)"' || return 1
}
OLD=$(vendored_shas "$RECORDED_SHA" 2>/dev/null) || { echo "[ERROR] Could not list vendored files at $RECORDED_SHA" >&2; exit 2; }
NEW=$(vendored_shas "$UPSTREAM_SHA" 2>/dev/null) || { echo "[ERROR] Could not list vendored files at $UPSTREAM_SHA" >&2; exit 2; }
CHANGED=$(diff <(sort <<< "$OLD") <(sort <<< "$NEW") | sed -n 's/^[<>] \([^ ]*\) .*/\1/p' | sort -u || true)
BEHIND=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/compare/$RECORDED_SHA...$UPSTREAM_SHA" -q .ahead_by 2>/dev/null || echo "?")

if [ -z "$CHANGED" ]; then
  echo "[OK] Upstream is $BEHIND commits ahead, none touching vendored skills or LICENSE ($RECORDED_VERSION, $RECORDED_SHA)"
  exit 0
fi

echo "[DRIFT] Vendored skills are behind upstream"
echo "  Recorded:  $RECORDED_VERSION ($RECORDED_SHA)"
echo "  Upstream:  v$UPSTREAM_VERSION ($UPSTREAM_SHA)"
echo "  Behind by: $BEHIND commits (as of $UPSTREAM_DATE)"
echo "  Changed:"
sed 's/^/    /' <<< "$CHANGED"
echo ""
echo "Run: ./scripts/sync-upstream.sh"
exit 1
