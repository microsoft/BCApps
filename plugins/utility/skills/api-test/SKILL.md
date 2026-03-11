---
name: api-test
description: API testing specialist for comprehensive validation including functional, security, and performance testing. Generates test suites and reports.
allowed-tools: Read, Write, Edit, Bash(*), Glob, Grep
argument-hint: [API endpoint, spec file, or test scope]
---

# API Testing Specialist

Comprehensive API validation covering functional, security, and performance testing.

## When to Use

- Testing new or existing APIs
- Validating API integrations
- Security assessment of endpoints
- User asks for "API test", "test this endpoint", or "validate the API"

## Testing Categories

### Functional Testing
- Endpoint behavior verification
- Input validation
- Error handling
- Response format compliance

### Security Testing
- Authentication/authorization
- Input sanitization (SQL injection, XSS)
- Rate limiting
- Data exposure prevention

### Performance Testing
- Response time SLAs
- Concurrent request handling
- Load and stress testing
- Resource utilization

## Test Coverage Framework

| Area | Target | Validation |
|------|--------|------------|
| Functional | 95%+ endpoint coverage | All behaviors tested |
| Security | OWASP API Top 10 | Zero critical vulnerabilities |
| Performance | SLA compliance | p95 < 200ms |

## Output Format

```markdown
## API Test Report: [API Name]

### Test Summary

| Category | Tests | Passed | Failed | Coverage |
|----------|-------|--------|--------|----------|
| Functional | [X] | [X] | [X] | [X]% |
| Security | [X] | [X] | [X] | [X]% |
| Performance | [X] | [X] | [X] | [X]% |

### Functional Test Results

#### Endpoint: [METHOD /path]

| Test Case | Input | Expected | Actual | Status |
|-----------|-------|----------|--------|--------|
| Valid request | [data] | 200 OK | 200 OK | PASS |
| Invalid input | [data] | 400 Bad Request | 400 | PASS |
| Unauthorized | No token | 401 | 401 | PASS |

### Security Test Results

| Test | Target | Result | Severity |
|------|--------|--------|----------|
| SQL Injection | /users?search= | Protected | - |
| Auth bypass | All endpoints | Protected | - |
| Rate limiting | 100 req/min | Enforced | - |
| Data exposure | Response bodies | No PII leaked | - |

### Performance Test Results

| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| p50 Response Time | <100ms | [X]ms | PASS/FAIL |
| p95 Response Time | <200ms | [X]ms | PASS/FAIL |
| p99 Response Time | <500ms | [X]ms | PASS/FAIL |
| Error Rate | <0.1% | [X]% | PASS/FAIL |
| Throughput | [X] req/s | [X] req/s | PASS/FAIL |

### Issues Found

#### Critical
| Issue | Endpoint | Impact | Recommendation |
|-------|----------|--------|----------------|
| [Issue] | [Path] | [Impact] | [Fix] |

#### High
...

### Test Code Generated

[If requested, include test code snippets]

### Recommendations

1. **[Priority]**: [Recommendation]
2. **[Priority]**: [Recommendation]

### Release Readiness

**Status**: [GO / NO-GO]
**Blockers**: [List any blocking issues]
**Conditions**: [Any conditions for release]
```

## Security Test Checklist

### Authentication
- [ ] Valid token accepted
- [ ] Invalid token rejected (401)
- [ ] Expired token rejected
- [ ] Token refresh works

### Authorization
- [ ] Role-based access enforced
- [ ] Resource ownership checked
- [ ] Admin functions protected

### Input Validation
- [ ] SQL injection prevented
- [ ] XSS prevented
- [ ] Command injection prevented
- [ ] Path traversal prevented

### Rate Limiting
- [ ] Limits enforced
- [ ] 429 returned when exceeded
- [ ] Limits reset appropriately

## Performance Targets

| Load Level | Target Response | Error Rate |
|------------|-----------------|------------|
| Normal (1x) | p95 < 200ms | < 0.1% |
| Peak (5x) | p95 < 500ms | < 0.5% |
| Stress (10x) | p95 < 1000ms | < 1% |

## Test Framework Examples

```javascript
// Jest/Playwright example
describe('API: /users', () => {
  test('GET returns user list', async () => {
    const response = await fetch('/api/users', {
      headers: { Authorization: `Bearer ${token}` }
    });
    expect(response.status).toBe(200);
    expect(response.json()).toHaveProperty('data');
  });

  test('POST validates input', async () => {
    const response = await fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify({ email: 'invalid' })
    });
    expect(response.status).toBe(400);
  });
});
```
