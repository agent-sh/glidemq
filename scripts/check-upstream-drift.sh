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

# grep finding nothing must not trip pipefail here; the empty check below reports it.
RECORDED_SHA=$(grep -oE '`[a-f0-9]{40}`' "$TRACKER" | head -1 | tr -d '`' || true)
RECORDED_VERSION=$(grep -oE '`v[0-9]+\.[0-9]+\.[0-9]+`' "$TRACKER" | head -1 | tr -d '`' || true)

fail() {
  echo "[ERROR] $1" >&2
  exit 2
}

[ -n "$RECORDED_SHA" ] || fail "no upstream SHA recorded in $TRACKER"
UPSTREAM_SHA=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/commits/main" -q .sha 2>/dev/null) || fail "could not read upstream main"
UPSTREAM_DATE=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/commits/main" -q .commit.author.date 2>/dev/null) || fail "could not read upstream main"
UPSTREAM_VERSION=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/package.json?ref=$UPSTREAM_SHA" -q .content 2>/dev/null \
  | base64 -d | grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4) || fail "could not read upstream package.json"

if [ "$RECORDED_SHA" = "$UPSTREAM_SHA" ]; then
  echo "[OK] Vendored skills are at upstream HEAD ($RECORDED_VERSION, $RECORDED_SHA)"
  exit 0
fi

# Upstream main moves for library changes too; only the vendored trees count.
# Compare git object SHAs of skills/glide-mq*/ and LICENSE at both refs.
vendored_shas() {
  gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/skills?ref=$1" \
    -q '.[] | select(.name | startswith("glide-mq")) | "skills/\(.name) \(.sha)"' || return 1
  gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/LICENSE?ref=$1" -q '"LICENSE \(.sha)"' || return 1
}
OLD=$(vendored_shas "$RECORDED_SHA" 2>/dev/null) || fail "could not list vendored files at $RECORDED_SHA"
NEW=$(vendored_shas "$UPSTREAM_SHA" 2>/dev/null) || fail "could not list vendored files at $UPSTREAM_SHA"
CHANGED=$(diff <(sort <<< "$OLD") <(sort <<< "$NEW") | sed -n 's/^[<>] \([^ ]*\) .*/\1/p' | sort -u || true)
COMPARE=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/compare/$RECORDED_SHA...$UPSTREAM_SHA" -q '"\(.status) \(.ahead_by) \(.merge_base_commit.sha)"' 2>/dev/null) \
  || fail "could not compare $RECORDED_SHA with upstream main"
read -r COMPARE_STATUS BEHIND MERGE_BASE <<< "$COMPARE"

if [ -z "$CHANGED" ]; then
  echo "[OK] Vendored skills and LICENSE match upstream main ($RECORDED_VERSION, $RECORDED_SHA; main is $BEHIND commits ahead)"
  if [ "$COMPARE_STATUS" != "ahead" ]; then
    echo "  The recorded SHA is not on main (compare status: $COMPARE_STATUS). Re-sync to record a main commit: ./scripts/sync-upstream.sh"
  fi
  exit 0
fi

# A recorded SHA that is not on main (for example the head of an unmerged
# upstream PR) differs from main by design, and syncing to main would revert
# it. That is only safe to call pending while main's vendored files are still
# what they were where the pinned commit branched off. Once main changes them
# (the PR merged, or anything else), it is drift.
if [ "$COMPARE_STATUS" = "diverged" ] || [ "$COMPARE_STATUS" = "behind" ]; then
  BASE=$(vendored_shas "$MERGE_BASE" 2>/dev/null) || fail "could not list vendored files at $MERGE_BASE"
  if [ "$(sort <<< "$BASE")" = "$(sort <<< "$NEW")" ]; then
    echo "[PENDING] Recorded SHA $RECORDED_SHA is not on upstream main (compare status: $COMPARE_STATUS),"
    echo "  and main has not changed the vendored files since that commit branched off."
    echo "  It is probably an unmerged upstream PR. Once it merges, sync to the merge commit:"
    echo "  ./scripts/sync-upstream.sh <merge sha>"
    exit 0
  fi
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
