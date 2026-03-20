---
name: glide-mq
description: "Creates glide-mq message queue implementations. Use for new queue setup, producer/consumer patterns, job scheduling, workflows, batch processing, or any greenfield glide-mq development."
version: 1.0.0
argument-hint: "[task description]"
---

# glide-mq

Provides guidance for greenfield glide-mq message queue development - queues, workers, producers, job scheduling, and workflows.

> This is a thin wrapper. For full API reference, advanced patterns, and deep documentation, see `node_modules/glide-mq/skills/` or https://avifenesh.github.io/glide-mq.dev/

## When to Use

Invoke this skill when:
- User is building a new message queue system with glide-mq
- User needs queue, worker, producer, or job scheduling setup
- User asks about glide-mq API, patterns, or configuration
- User wants workflow orchestration (flows, DAGs, chains)

## Install

```bash
npm install glide-mq
```

Requires Node.js 20+ and Valkey 7.0+ (or Redis 7.0+).

## Connection

All glide-mq classes use the addresses array format:

```typescript
const connection = { addresses: [{ host: 'localhost', port: 6379 }] };
```

With TLS and authentication:

```typescript
const connection = {
  addresses: [{ host: 'my-cluster.cache.amazonaws.com', port: 6379 }],
  useTLS: true,
  credentials: { password: 'secret' },
  clusterMode: true,
};
```

## Quick Start

```typescript
import { Queue, Worker } from 'glide-mq';

const connection = { addresses: [{ host: 'localhost', port: 6379 }] };

// Producer
const queue = new Queue('tasks', { connection });
await queue.add('send-email', { to: 'user@example.com' }, {
  attempts: 3,
  backoff: { type: 'exponential', delay: 1000 },
  priority: 1,
});

// Consumer
const worker = new Worker('tasks', async (job) => {
  console.log(`Processing ${job.name}:`, job.data);
  return { sent: true };
}, { connection, concurrency: 10 });

worker.on('completed', (job) => console.log(`Job ${job.id} done`));
worker.on('failed', (job, err) => console.error(`Job ${job.id} failed:`, err.message));
```

## Core API

| Class | Purpose | Key Methods |
|-------|---------|-------------|
| `Queue` | Enqueue and manage jobs | `add()`, `addBulk()`, `addAndWait()`, `pause()`, `resume()`, `drain()` |
| `Worker` | Process jobs | Constructor takes `(name, processor, opts)`. Events: `completed`, `failed`, `active` |
| `Producer` | Lightweight enqueue (serverless) | `add()` - no EventEmitter overhead |
| `FlowProducer` | Parent-child job trees | `add()` for DAG workflows |
| `QueueEvents` | Monitor queue events | `on('completed')`, `on('failed')`, `on('delayed')` |
| `Broadcast` | Durable pub/sub | Fan-out with subject filtering |

## Job Options

| Option | Type | Description |
|--------|------|-------------|
| `attempts` | number | Retry count on failure |
| `backoff` | object | `{ type: 'exponential' \| 'fixed', delay: ms }` |
| `delay` | number | Delay before processing (ms) |
| `priority` | number | Lower number = higher priority (0 is highest) |
| `ttl` | number | Auto-expire after time-to-live (ms) |
| `jobId` | string | Custom deduplication ID |
| `ordering.key` | string | Per-key ordering group |
| `ordering.concurrency` | number | Max parallel jobs per group (default 1) |
| `ordering.rateLimit` | object | `{ max, duration }` - static sliding window per group |
| `ordering.tokenBucket` | object | `{ capacity, refillRate }` - cost-based rate limiting per group |

**Runtime group rate limiting** (new in v0.12):
- `job.rateLimitGroup(duration, opts?)` - pause group from inside processor (e.g., on 429)
- `throw new GroupRateLimitError(duration, opts?)` - throw-style sugar
- `queue.rateLimitGroup(key, duration, opts?)` - pause group from outside (webhook, health check)
- Options: `currentJob` ('requeue'|'fail'), `requeuePosition` ('front'|'back'), `extend` ('max'|'replace')

**Note:** Compression (`compression: 'gzip'`) is a Queue-level option passed to the Queue constructor, not a per-job option.

## Worker Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `concurrency` | number | 1 | Parallel job limit |
| `lockDuration` | number | 30000 | Lock timeout (ms) |
| `stalledInterval` | number | 30000 | Recovery check frequency (ms) |

## Scheduling and Testing

```typescript
// Cron scheduling
await queue.upsertJobScheduler('daily-report',
  { pattern: '0 9 * * *', tz: 'America/New_York' },
  { name: 'daily-report', data: { v: 1 } },
);

// In-memory testing (no Valkey/Redis required)
import { TestQueue, TestWorker } from 'glide-mq/testing';
const queue = new TestQueue('tasks');
const worker = new TestWorker(queue, async (job) => ({ sent: true }));
```

## Critical Notes

- Connection uses `{ addresses: [{ host, port }] }` - NOT `{ host, port }` directly
- Priority: lower number = higher priority (0 is highest)
- Keys are hash-tagged (`glide:{queueName}:*`) for native cluster support
- Single FCALL per operation - no Lua EVAL overhead

## Deep Dive

For complete API reference, workflows, observability, and serverless guides:
- `node_modules/glide-mq/skills/` | https://avifenesh.github.io/glide-mq.dev/
