#!/usr/bin/env bash
# Sync vendored skills from upstream avifenesh/glide-mq.
# Usage: scripts/sync-upstream.sh [ref]   (default: main)

set -euo pipefail

UPSTREAM_OWNER="avifenesh"
UPSTREAM_REPO="glide-mq"
SKILLS=("glide-mq" "glide-mq-migrate-bullmq" "glide-mq-migrate-bee")
REF="${1:-main}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v gh >/dev/null 2>&1; then
  echo "[ERROR] gh CLI required" >&2
  exit 1
fi

echo "[INFO] Resolving ref '$REF' on $UPSTREAM_OWNER/$UPSTREAM_REPO..."
SHA=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/commits/$REF" -q .sha 2>/dev/null)
DATE=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/commits/$REF" -q .commit.author.date 2>/dev/null)
VERSION=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/package.json?ref=$SHA" -q .content 2>/dev/null \
  | base64 -d | grep -oE '"version"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | cut -d'"' -f4)

if [ -z "$SHA" ]; then
  echo "[ERROR] Could not resolve ref '$REF'" >&2
  exit 1
fi

echo "[INFO] Syncing to $SHA ($DATE, v$VERSION)"

# Sync each skill SKILL.md and references/*
for s in "${SKILLS[@]}"; do
  echo "[INFO] $s/SKILL.md"
  gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/skills/$s/SKILL.md?ref=$SHA" -q .content 2>/dev/null \
    | base64 -d > "skills/$s/SKILL.md"

  ref_files=$(gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/skills/$s/references?ref=$SHA" -q '.[] | select(.type=="file") | .name' 2>/dev/null || true)
  if [ -n "$ref_files" ]; then
    mkdir -p "skills/$s/references"
    # Remove stale references not in upstream
    for existing in "skills/$s/references"/*; do
      [ -f "$existing" ] || continue
      base=$(basename "$existing")
      if ! grep -qx "$base" <<< "$ref_files"; then
        echo "  [REMOVE] references/$base (no longer upstream)"
        rm -f "$existing"
      fi
    done
    for f in $ref_files; do
      gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/skills/$s/references/$f?ref=$SHA" -q .content 2>/dev/null \
        | base64 -d > "skills/$s/references/$f"
      echo "  [OK] references/$f"
    done
  fi
done

# Sync LICENSE
gh api "repos/$UPSTREAM_OWNER/$UPSTREAM_REPO/contents/LICENSE?ref=$SHA" -q .content 2>/dev/null \
  | base64 -d > LICENSE

# Update UPSTREAM.md tracker table
TODAY=$(date -u +%Y-%m-%d)
TRACKER="skills/UPSTREAM.md"
if [ -f "$TRACKER" ]; then
  python - <<PY
import re, sys
path = "$TRACKER"
with open(path, "r", encoding="utf-8") as f:
    s = f.read()
s = re.sub(r"\| Upstream SHA \| \`[^\`]+\` \|", f"| Upstream SHA | \`$SHA\` |", s)
s = re.sub(r"\| Upstream date \| \`[^\`]+\` \|", f"| Upstream date | \`$DATE\` |", s)
s = re.sub(r"\| Upstream version \| \`[^\`]+\` \|", f"| Upstream version | \`v$VERSION\` |", s)
s = re.sub(r"\| Synced on \| \`[^\`]+\` \|", f"| Synced on | \`$TODAY\` |", s)
with open(path, "w", encoding="utf-8") as f:
    f.write(s)
print("[OK] UPSTREAM.md updated")
PY
fi

echo ""
echo "[DONE] Sync complete. Review with: git diff --stat"
echo "[NEXT] Commit with: sync: glide-mq skills to v$VERSION ($SHA)"
