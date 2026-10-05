# glidemq

This repo is the glidemq plugin: glide-mq message queue skills for greenfield development and for migration from BullMQ or Bee-Queue. Part of the [agentsys](https://github.com/agent-sh/agentsys) ecosystem; skills follow https://agentskills.io.

## Vendored skills

The three skills (`glide-mq`, `glide-mq-migrate-bullmq`, `glide-mq-migrate-bee`) and their `references/` are copied from [avifenesh/glide-mq](https://github.com/avifenesh/glide-mq) `skills/`, and the root `LICENSE` from that repo's root `LICENSE`. Upstream is the source of truth. Change them upstream and re-sync with `./scripts/sync-upstream.sh [ref]`, because the next sync overwrites local edits. `skills/UPSTREAM.md` records the pinned commit and explains the sync and the weekly drift check (`scripts/check-upstream-drift.sh`). This repo owns `AGENTS.md`, `skills/UPSTREAM.md`, `scripts/`, `.github/` and the package metadata.

## Rules

- Output is plain text: no emojis or ASCII art. Status markers are `[OK]`, `[ERROR]`, `[WARN]`, `[CRITICAL]`.
- Commit only product files. Summaries, plans and audit notes belong in the PR or the conversation.
- A change is done when its checks pass; a script fix comes with a check that covers it.
- Non-trivial changes go through a PR, not a direct push to main. Run the git hooks; do not bypass them.
- In prose use ` - ` (single dash with spaces), not ` -- `.
- If a script fails, report the failure before doing the step by hand, so broken tooling gets fixed.
- Priorities, in order: plugin users' experience, automation that needs no babysitting, token efficiency, output quality, simplicity.

## Checks

```bash
npm test                          # syntax and executable checks for both scripts
./scripts/check-upstream-drift.sh # 0 up to date or pending, 1 drift, 2 error
agnix .                           # agent config lint
```

## References

- glide-mq docs: https://avifenesh.github.io/glide-mq.dev/
- glide-mq repo: https://github.com/avifenesh/glide-mq
