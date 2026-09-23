# Glide-MQ Skills - Upstream Tracking

The 3 SKILL.md files (and their `references/` directories) under this directory are **vendored from the upstream `avifenesh/glide-mq` repo**. We do not own them. They are mirrored here so the `agent-sh/glidemq` plugin can be installed standalone via the agentsys marketplace without requiring users to install `glide-mq` from npm first.

## Upstream

- **Repo**: https://github.com/avifenesh/glide-mq
- **Path**: `skills/`
- **License**: Apache-2.0 (see `LICENSE` at this repo root)
- **Author**: Avi Fenesh (also maintainer of this plugin)

## Vendored files

| File | Upstream path |
|------|---------------|
| `glide-mq/SKILL.md` + `references/*.md` | `skills/glide-mq/` |
| `glide-mq-migrate-bullmq/SKILL.md` + `references/*.md` | `skills/glide-mq-migrate-bullmq/` |
| `glide-mq-migrate-bee/SKILL.md` + `references/*.md` | `skills/glide-mq-migrate-bee/` |

## Last sync

| Field | Value |
|-------|-------|
| Upstream SHA | `1b19a29ff336f3a0f439c7c05a2060dfe9eb38bd` |
| Upstream date | `2026-09-23T23:16:28Z` |
| Upstream version | `v0.15.5` |
| Synced on | `2026-09-23` |
| Synced by | manual sync via `scripts/sync-upstream.sh` |
| Note | Head of avifenesh/glide-mq#290 (skill rewrite), not yet on upstream main. Re-sync to the merge commit once it lands. |

## How to update

When upstream releases a new version of the skills:

```bash
# From this repo root
./scripts/sync-upstream.sh                 # sync to current upstream/main
./scripts/sync-upstream.sh v0.16.0         # sync to a specific tag
./scripts/sync-upstream.sh <sha>           # sync to a specific commit
```

The script fetches `skills/glide-mq*` (SKILL.md and `references/`) and the LICENSE from the requested ref, replaces the local copies (upstream is the source of truth; reference files and directories that no longer exist upstream are removed), and updates the **Last sync** table. Each file is fetched to a temp file first, so a failed fetch stops the script without truncating the local copy.

After running, review the diff, commit, and open a PR titled `sync: glide-mq skills to <ref>`.

## Drift detection

CI runs `scripts/check-upstream-drift.sh` weekly (Mondays, and on demand). It compares the git object SHAs of `skills/glide-mq*/` and `LICENSE` at the recorded SHA and at upstream `main`, so library-only commits upstream do not count as drift. When the vendored content differs, it exits 1 and the workflow opens (or comments on) an issue labeled `upstream-sync`, creating the label if needed. A recorded SHA that is not on upstream `main` (the head of an unmerged upstream PR) is reported as `[PENDING]` with exit 0, because syncing to `main` would revert it. API errors exit 2 and fail the workflow run.

## Why vendor instead of fetch at install time

- **Offline install**: agentsys plugins should work without network calls during install
- **Marketplace consistency**: the plugin's content is reviewable in this repo before users install it
- **Determinism**: a given marketplace version pins to a specific upstream SHA

## When NOT to edit these files locally

Do **not** hand-edit the SKILL.md or any file in `references/`. Open a PR upstream at https://github.com/avifenesh/glide-mq instead, then re-sync here. Local edits will be lost on the next sync.

The only files in this directory that are owned by `agent-sh/glidemq` and safe to edit:
- `skills/UPSTREAM.md` (this file)
- New skill directories that don't exist upstream (none today)
