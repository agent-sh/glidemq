# glidemq

Agent skills for [glide-mq](https://github.com/avifenesh/glide-mq), the Node.js job queue on Valkey/Redis Streams. One skill for new queue code, two for migrating from BullMQ or Bee-Queue. Skills follow the [agentskills.io](https://agentskills.io) format.

## Skills

| Skill | What it covers |
|-------|----------------|
| `glide-mq` | Queues, workers, retries, schedulers, workflows, broadcast, serverless producers, HTTP proxy, AI primitives (usage, streaming, suspend/resume, budgets, fallbacks) and vector search |
| `glide-mq-migrate-bullmq` | BullMQ (and BullMQ Pro groups) to glide-mq: connection format, changed signatures, removed options and what replaces them |
| `glide-mq-migrate-bee` | Bee-Queue to glide-mq: chained job builder to options, split Queue and Worker, settings, methods and events |

Each skill has a `references/` folder the agent loads on demand.

## Installation

```bash
npx skills add agent-sh/glidemq
```

Or copy the folders under `skills/` into your agent's skills directory (`~/.claude/skills/` for Claude Code).

glidemq is not in the agentsys marketplace.

## Upstream

The skills and `LICENSE` are vendored from [avifenesh/glide-mq](https://github.com/avifenesh/glide-mq) `skills/`. Upstream is the source of truth: change them there, then re-sync.

```bash
./scripts/sync-upstream.sh [ref]   # sync to upstream main, a tag or a commit
./scripts/check-upstream-drift.sh  # 0 up to date or pending, 1 drift, 2 error
```

[skills/UPSTREAM.md](skills/UPSTREAM.md) records the pinned commit. CI runs the drift check every Monday and opens an `upstream-sync` issue when the vendored files fall behind.

## Development

```bash
npm test   # script syntax, link regression and standalone skill links
agnix .    # agent config lint
```

## Links

- glide-mq docs: https://avifenesh.github.io/glide-mq.dev/
- glide-mq on npm: https://www.npmjs.com/package/glide-mq
- Part of the [agent-sh](https://github.com/agent-sh) ecosystem

## License

Apache-2.0, from upstream. See [LICENSE](LICENSE).
