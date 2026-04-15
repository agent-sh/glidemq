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
| Upstream SHA | `ae9c0fa6d35921b939ed78bbcc287f7eb3982694` |
| Upstream date | `2026-04-14T22:07:13Z` |
| Upstream version | `v0.15.1` |
| Synced on | `2026-04-15` |
| Synced by | manual sync via `scripts/sync-upstream.sh` |

## How to update

When upstream releases a new version of the skills:

```bash
# From this repo root
./scripts/sync-upstream.sh                 # sync to current upstream/main
./scripts/sync-upstream.sh v0.16.0         # sync to a specific tag
./scripts/sync-upstream.sh <sha>           # sync to a specific commit
```

The script:
1. Fetches `skills/glide-mq*` and the LICENSE from the requested ref via the GitHub API
2. Overwrites local copies (no merge - upstream is source of truth)
3. Updates the **Last sync** table in this file with the new SHA, date, and version
4. Prints a diff summary

After running, review the diff, commit, and open a PR titled `sync: glide-mq skills to <ref>`.

## Drift detection

CI runs `scripts/check-upstream-drift.sh` weekly (and on demand). It compares the recorded SHA in this file against `avifenesh/glide-mq` HEAD and opens an issue if they differ by more than 30 days or the upstream version bumped a major/minor.

## Why vendor instead of fetch at install time

- **Offline install**: agentsys plugins should work without network calls during install
- **Marketplace consistency**: the plugin's content is reviewable in this repo before users install it
- **Determinism**: a given marketplace version pins to a specific upstream SHA

## When NOT to edit these files locally

Do **not** hand-edit the SKILL.md or any file in `references/`. Open a PR upstream at https://github.com/avifenesh/glide-mq instead, then re-sync here. Local edits will be lost on the next sync.

The only files in this directory that are owned by `agent-sh/glidemq` and safe to edit:
- `skills/UPSTREAM.md` (this file)
- New skill directories that don't exist upstream (none today)
