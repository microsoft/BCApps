// Unit tests for wiki-client.js - URL generation
// Run with: node --test tests/wiki-client.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { getWikiPageUrl } from '../wiki-client.js';

describe('getWikiPageUrl', () => {
  it('should generate correct wiki URL', () => {
    const url = getWikiPageUrl('microsoft', 'BCAppsCampAIRHack', 123);
    assert.equal(url, 'https://github.com/microsoft/BCAppsCampAIRHack/wiki/Triage-Report-Issue-123');
  });

  it('should handle different owners and repos', () => {
    const url = getWikiPageUrl('myorg', 'myrepo', 1);
    assert.equal(url, 'https://github.com/myorg/myrepo/wiki/Triage-Report-Issue-1');
  });
});
