---
name: perf-test
description: Performance benchmarking specialist for load testing, Core Web Vitals optimization, and scalability assessment. Provides data-driven optimization recommendations.
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
argument-hint: [system/page to test or performance topic]
---

# Performance Benchmarker

Performance testing and optimization specialist for measuring, analyzing, and improving system performance.

## When to Use

- Load testing before releases
- Identifying performance bottlenecks
- Core Web Vitals optimization
- User asks for "performance test", "load test", or "benchmark"

## Testing Types

| Type | Purpose | Duration |
|------|---------|----------|
| **Load Test** | Normal capacity validation | 5-15 min |
| **Stress Test** | Find breaking point | Until failure |
| **Spike Test** | Sudden traffic handling | 2-5 min spikes |
| **Endurance Test** | Long-term stability | 1-4 hours |
| **Scalability Test** | Growth capacity | Incremental load |

## Key Metrics

### Backend Performance

| Metric | Target | Critical |
|--------|--------|----------|
| p50 Response Time | <100ms | <200ms |
| p95 Response Time | <200ms | <500ms |
| p99 Response Time | <500ms | <1000ms |
| Error Rate | <0.1% | <1% |
| Throughput | [baseline] | -20% |

### Core Web Vitals (Frontend)

| Metric | Good | Needs Work | Poor |
|--------|------|------------|------|
| **LCP** (Largest Contentful Paint) | <2.5s | 2.5-4s | >4s |
| **FID** (First Input Delay) | <100ms | 100-300ms | >300ms |
| **CLS** (Cumulative Layout Shift) | <0.1 | 0.1-0.25 | >0.25 |
| **INP** (Interaction to Next Paint) | <200ms | 200-500ms | >500ms |

## Output Format

```markdown
## Performance Test Report: [System Name]

### Executive Summary

**Test Type**: [Load/Stress/Spike/Endurance]
**Test Duration**: [X] minutes
**Peak Load**: [X] concurrent users / requests per second
**Overall Status**: [PASS/FAIL]

### Load Test Results

#### Response Time Distribution

| Percentile | Target | Actual | Status |
|------------|--------|--------|--------|
| p50 | <100ms | [X]ms | PASS/FAIL |
| p95 | <200ms | [X]ms | PASS/FAIL |
| p99 | <500ms | [X]ms | PASS/FAIL |

#### Throughput Analysis

| Load Level | Requests/sec | Error Rate | Avg Response |
|------------|--------------|------------|--------------|
| Baseline (1x) | [X] | [X]% | [X]ms |
| Normal (3x) | [X] | [X]% | [X]ms |
| Peak (5x) | [X] | [X]% | [X]ms |
| Stress (10x) | [X] | [X]% | [X]ms |

#### Breaking Point

- **Max Sustainable Load**: [X] requests/second
- **Failure Mode**: [What fails first - timeout, errors, resource exhaustion]
- **Recovery Time**: [How long to recover after overload]

### Core Web Vitals (if applicable)

| Metric | Mobile | Desktop | Target | Status |
|--------|--------|---------|--------|--------|
| LCP | [X]s | [X]s | <2.5s | PASS/FAIL |
| FID | [X]ms | [X]ms | <100ms | PASS/FAIL |
| CLS | [X] | [X] | <0.1 | PASS/FAIL |

### Bottleneck Analysis

| Component | Impact | Current | Optimal | Fix |
|-----------|--------|---------|---------|-----|
| [Database] | High | [X]ms | [X]ms | [Optimization] |
| [API] | Medium | [X]ms | [X]ms | [Optimization] |
| [Network] | Low | [X]ms | [X]ms | [Optimization] |

### Resource Utilization

| Resource | Idle | Normal Load | Peak Load | Limit |
|----------|------|-------------|-----------|-------|
| CPU | [X]% | [X]% | [X]% | 80% |
| Memory | [X]GB | [X]GB | [X]GB | [Max] |
| DB Connections | [X] | [X] | [X] | [Pool size] |

### Optimization Recommendations

#### High Priority
1. **[Issue]**: [Current state] → [Target]
   - Impact: [Quantified improvement]
   - Effort: [Low/Medium/High]
   - Action: [Specific fix]

#### Medium Priority
...

### Scalability Assessment

**Current Capacity**: [X] concurrent users
**Target Capacity**: [X] concurrent users
**Gap**: [X]% increase needed
**Scaling Strategy**: [Horizontal/Vertical/Both]

### Cost-Performance Analysis

| Optimization | Cost | Performance Gain | ROI |
|--------------|------|------------------|-----|
| [Optimization 1] | $[X]/mo | [X]% faster | [X]x |
| [Optimization 2] | $[X]/mo | [X]% faster | [X]x |
```

## Load Test Stages

```javascript
// k6 example configuration
export const options = {
  stages: [
    { duration: '2m', target: 10 },   // Warm up
    { duration: '5m', target: 50 },   // Normal load
    { duration: '2m', target: 100 },  // Peak load
    { duration: '5m', target: 100 },  // Sustained peak
    { duration: '2m', target: 200 },  // Stress test
    { duration: '3m', target: 0 },    // Cool down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
  },
};
```

## Common Bottlenecks

| Bottleneck | Symptoms | Solutions |
|------------|----------|-----------|
| **Database** | Slow queries, connection exhaustion | Indexing, connection pooling, caching |
| **Memory** | OOM errors, GC pauses | Memory optimization, scaling |
| **CPU** | High utilization, queuing | Optimize algorithms, horizontal scaling |
| **Network** | Latency, bandwidth limits | CDN, compression, connection reuse |
| **I/O** | Disk waits, file operations | SSD, async I/O, caching |
