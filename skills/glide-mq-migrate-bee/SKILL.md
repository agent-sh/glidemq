---
name: glide-mq-migrate-bee
description: "Migrates Bee-Queue applications to glide-mq. Use when user wants to convert, migrate, replace, or switch from Bee-Queue to glide-mq, or asks about Bee-Queue vs glide-mq differences."
version: 1.0.0
argument-hint: "[migration scope or question]"
---

# glide-mq-migrate-bee

Provides guidance for migrating Bee-Queue applications to glide-mq - chained builder to options object conversion, API mapping, and architectural changes.

> This is a thin wrapper. For the complete migration guide, see `node_modules/glide-mq/skills/` or https://avifenesh.github.io/glide-mq.dev/migration/from-bee-queue

## When to Use

Invoke this skill when:
- User wants to migrate from Bee-Queue to glide-mq
- User asks about differences between Bee-Queue and glide-mq
- User needs help converting Bee-Queue chained job builders
- User is evaluating Bee-Queue alternatives or has compatibility issues

## Why Migrate

Bee-Queue is unmaintained (last release 2021) with Node.js compatibility issues. It lacks:
- Cluster support and TLS
- Delayed jobs and priority queues
- TypeScript types
- Workflow orchestration
- Active maintenance and security patches

glide-mq provides all of these with 35%+ higher throughput.

## Install

```bash
npm uninstall bee-queue @types/bee-queue
npm install glide-mq
```

## Connection Conversion

**Bee-Queue:**
```typescript
const queue = new Queue('tasks', {
  redis: { host: 'localhost', port: 6379 }
});
```

**glide-mq:**
```typescript
import { Queue, Worker } from 'glide-mq';
const connection = { addresses: [{ host: 'localhost', port: 6379 }] };
const queue = new Queue('tasks', { connection });
```

## Chained Builder to Options Object

The biggest migration change. Bee-Queue uses chained methods; glide-mq uses an options object.

**Bee-Queue (chained builder):**
```typescript
const job = queue.createJob(data)
  .timeout(30000)
  .retries(3)
  .backoff('exponential', 1000)
  .delayUntil(Date.now() + 60000)
  .setId('unique-123')
  .save();
```

**glide-mq (options object):**
```typescript
await queue.add('task-name', data, {
  timeout: 30000,                                  // .timeout(ms) -> timeout (job option)
  attempts: 3,                                    // .retries(n) -> attempts
  backoff: { type: 'exponential', delay: 1000 },  // .backoff() -> backoff object
  delay: 60000,                                    // .delayUntil() -> delay (relative ms)
  jobId: 'unique-123',                             // .setId() -> jobId
});
```

**CRITICAL**: Bee-Queue `.retries(n)` maps to glide-mq `attempts` - different name!

## Worker Processing

```typescript
// Bee-Queue:  queue.process(10, handler); queue.on('succeeded', ...)
// glide-mq:   new Worker(name, handler, { connection, concurrency: 10 })
const worker = new Worker('tasks', async (job) => {
  return { processed: true };
}, { connection, concurrency: 10 });
worker.on('completed', (job) => console.log('Done:', job.returnValue));
```

## Key Differences

| Feature | Bee-Queue | glide-mq | Notes |
|---------|-----------|----------|-------|
| Job creation | `createJob(data).save()` | `queue.add(name, data, opts)` | Pattern changed |
| Options style | Chained methods | Options object | Architectural |
| Retries | `.retries(n)` | `attempts: n` | **Name changed!** |
| Timeout | `.timeout(ms)` | `timeout` on job options | Per-job option |
| Worker setup | `queue.process(n, fn)` | `new Worker(name, fn, { concurrency: n })` | Separate class |
| Progress | `reportProgress(json)` | `updateProgress(0-100 or object)` | Number or object |
| Stall detection | Manual `stallInterval` | Auto via Worker `lockDuration` | Simplified |
| `succeeded` event | `queue.on('succeeded')` | `worker.on('completed')` | Renamed |
| Producer-only | `{ isWorker: false }` | `new Producer('queue', { connection })` | Dedicated class |
| Batch save | `queue.saveAll(jobs)` | `queue.addBulk(jobs)` | Renamed |
| Connection | `{ redis: { host, port } }` | `{ addresses: [{ host, port }] }` | Must convert |
| Delayed jobs | Not supported | `delay` option (ms) | New |
| Priority | Not supported | `priority` option (0 = highest) | New |

## Migration Checklist

- [ ] Replace `bee-queue` with `glide-mq` in package.json
- [ ] Convert `{ redis: { host, port } }` to `{ addresses: [{ host, port }] }`
- [ ] Split queue instances into Queue (producer) and Worker (consumer)
- [ ] Convert `.createJob().save()` chains to `queue.add(name, data, opts)`
- [ ] Rename `.retries(n)` to `attempts: n` in all job options
- [ ] Rename `'succeeded'` events to `'completed'`
- [ ] Replace `queue.process()` with `new Worker()` constructor
- [ ] Run full test suite

## Deep Dive

For the complete migration guide with batch operation details and edge cases:
- Full migration guide: `node_modules/glide-mq/skills/`
- Online guide: https://avifenesh.github.io/glide-mq.dev/migration/from-bee-queue
- Repository: https://github.com/avifenesh/glide-mq
