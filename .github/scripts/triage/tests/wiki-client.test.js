// Unit tests for wiki-client.js - URL generation
// Run with: node --test tests/wiki-client.test.js

import { describe, it, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { getWikiPageUrl } from '../wiki-client.js';

describe('getWikiPageUrl', () => {
  beforeEach(() => {
    delete process.env.TRIAGE_REPO;
  });

  it('should default to the source repo wiki', () => {
    const url = getWikiPageUrl('microsoft', 'BCAppsCampAIRHack', 123);
    assert.equal(url, 'https://github.com/microsoft/BCAppsCampAIRHack/wiki/Triage-Report-Issue-123');
  });

  it('should use TRIAGE_REPO env var when set', () => {
    process.env.TRIAGE_REPO = 'BCAppsTriage';
    const url = getWikiPageUrl('microsoft', 'BCAppsCampAIRHack', 5);
    assert.equal(url, 'https://github.com/microsoft/BCAppsTriage/wiki/Triage-Report-Issue-5');
  });

  it('should handle different owners and repos', () => {
    const url = getWikiPageUrl('myorg', 'myrepo', 1);
    assert.equal(url, 'https://github.com/myorg/myrepo/wiki/Triage-Report-Issue-1');
  });
});
