---
name: glide-mq-migrate-bullmq
description: "Migrates BullMQ applications to glide-mq. Use when user wants to convert, migrate, replace, or switch from BullMQ to glide-mq, or asks about BullMQ vs glide-mq differences."
version: 1.0.0
argument-hint: "[migration scope or question]"
---

# glide-mq-migrate-bullmq

Provides guidance for migrating BullMQ applications to glide-mq - connection conversion, API mapping, and breaking changes.

> This is a thin wrapper. For the complete migration guide with advanced patterns, see `node_modules/glide-mq/skills/` or https://avifenesh.github.io/glide-mq.dev/migration/from-bullmq

## When to Use

Invoke this skill when:
- User wants to migrate from BullMQ to glide-mq
- User asks about differences between BullMQ and glide-mq
- User needs help converting BullMQ connection or job configs
- User is evaluating BullMQ alternatives

## Install

```bash
npm remove bullmq
npm install glide-mq
```

Update all imports from `'bullmq'` to `'glide-mq'`.

## Connection Conversion

The most critical change. BullMQ uses flat ioredis format; glide-mq uses an addresses array.

**BullMQ:**
```typescript
const connection = { host: 'localhost', port: 6379 };
```

**glide-mq:**
```typescript
const connection = { addresses: [{ host: 'localhost', port: 6379 }] };
```

**With TLS:**
```typescript
const connection = {
  addresses: [{ host: 'my-cluster.cache.amazonaws.com', port: 6379 }],
  useTLS: true,
  credentials: { password: 'secret' },
  clusterMode: true,
};
```

## Quick Comparison

```typescript
// BullMQ                                    // glide-mq
import { Queue, Worker } from 'bullmq';      import { Queue, Worker } from 'glide-mq';
// connection: { host, port }                // connection: { addresses: [{ host, port }] }
```

The processor function signature is identical. Most code is a drop-in replacement after fixing the connection and imports.

## Key Differences

| Feature | BullMQ | glide-mq | Notes |
|---------|--------|----------|-------|
| Connection | `{ host, port }` | `{ addresses: [{ host, port }] }` | Must convert |
| Job scheduling | `opts.repeat` | `queue.upsertJobScheduler()` | API changed |
| Default job opts | `defaultJobOptions` in Queue | Removed - wrap `add()` | Breaking |
| Backoff strategy | `settings.backoffStrategy` | `backoffStrategies` map | Breaking |
| `waitUntilFinished` | `job.waitUntilFinished(qe, ttl)` | `job.waitUntilFinished(pollMs, timeoutMs)` | Signature changed |
| Per-key ordering | BullMQ Pro only | `opts.ordering.key` | Free in glide-mq |
| Group concurrency | `group: { id, limit }` | `ordering: { key, concurrency }` | Renamed |
| Runtime group rate limit | Not available | `job.rateLimitGroup(ms)` / `queue.rateLimitGroup(key, ms)` | New in glide-mq |
| Dead letter queue | Not native | Built-in `deadLetterQueue` option | New |
| Compression | Not available | `compression: 'gzip'` | New |
| Worker `'active'` event | Emits `(job, prev)` | Emits `(job, jobId)` | Breaking |
| `getJobs()` | Multiple types array | Single type per call | Breaking |
| Priority | Lower = higher (0 highest) | Same | Compatible |

## Breaking Changes

**`defaultJobOptions` removed** - wrap `add()` instead:
```typescript
const DEFAULTS = { attempts: 3, backoff: { type: 'exponential', delay: 1000 } };
const add = (name, data, opts) => queue.add(name, data, { ...DEFAULTS, ...opts });
```

**Scheduling** - `opts.repeat` replaced by scheduler API:
```typescript
await queue.upsertJobScheduler('report',
  { pattern: '0 9 * * *', tz: 'America/New_York' },
  { name: 'report', data },
);
```

**Backoff** - single function replaced by named map:
```typescript
new Worker('q', processor, {
  connection,
  backoffStrategies: { jitter: (attempts, err) => 1000 + Math.random() * 1000 },
});
```

## Migration Checklist

- [ ] Replace `bullmq` with `glide-mq` in package.json
- [ ] Update all imports from `'bullmq'` to `'glide-mq'`
- [ ] Convert connection configs to `{ addresses: [{ host, port }] }`
- [ ] Replace `opts.repeat` with `upsertJobScheduler()`
- [ ] Remove `QueueScheduler` instantiation (not needed)
- [ ] Remove `defaultJobOptions` - use wrapper pattern
- [ ] Replace `settings.backoffStrategy` with `backoffStrategies` map
- [ ] Update `waitUntilFinished()` call signatures
- [ ] Run full test suite

## Deep Dive

For the complete migration guide with advanced patterns, multi-tenant examples, and edge cases:
- Full migration guide: `node_modules/glide-mq/skills/`
- Online guide: https://avifenesh.github.io/glide-mq.dev/migration/from-bullmq
- Repository: https://github.com/avifenesh/glide-mq
