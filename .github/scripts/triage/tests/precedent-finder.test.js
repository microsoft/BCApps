// Unit tests for precedent-finder.js - formatPrecedentsSection
// Run with: node --test tests/precedent-finder.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { formatPrecedentsSection } from '../precedent-finder.js';

describe('formatPrecedentsSection', () => {
  it('returns empty string for empty array', () => {
    assert.equal(formatPrecedentsSection([]), '');
  });

  it('returns empty string for null', () => {
    assert.equal(formatPrecedentsSection(null), '');
  });

  it('returns empty string for undefined', () => {
    assert.equal(formatPrecedentsSection(undefined), '');
  });

  it('formats a single precedent with number, title, similarity, and state_reason', () => {
    const precedents = [
      {
        number: 42,
        title: 'Fix posting error in GL',
        similarity: 78,
        url: 'https://github.com/org/repo/issues/42',
        state_reason: 'completed',
      },
    ];
    const result = formatPrecedentsSection(precedents);
    assert.ok(result.includes('#42'));
    assert.ok(result.includes('Fix posting error in GL'));
    assert.ok(result.includes('78% similarity'));
    assert.ok(result.includes('completed'));
    assert.ok(result.includes('https://github.com/org/repo/issues/42'));
  });

  it('includes all precedents when given multiple', () => {
    const precedents = [
      {
        number: 10,
        title: 'Issue Alpha',
        similarity: 90,
        url: 'https://github.com/org/repo/issues/10',
        state_reason: 'completed',
      },
      {
        number: 20,
        title: 'Issue Beta',
        similarity: 65,
        url: 'https://github.com/org/repo/issues/20',
        state_reason: 'not_planned',
      },
      {
        number: 30,
        title: 'Issue Gamma',
        similarity: 50,
        url: 'https://github.com/org/repo/issues/30',
        state_reason: 'completed',
      },
    ];
    const result = formatPrecedentsSection(precedents);
    assert.ok(result.includes('#10'));
    assert.ok(result.includes('Issue Alpha'));
    assert.ok(result.includes('#20'));
    assert.ok(result.includes('Issue Beta'));
    assert.ok(result.includes('not_planned'));
    assert.ok(result.includes('#30'));
    assert.ok(result.includes('Issue Gamma'));
  });

  it('includes the section header', () => {
    const precedents = [
      {
        number: 1,
        title: 'Test',
        similarity: 30,
        url: 'https://github.com/org/repo/issues/1',
        state_reason: 'completed',
      },
    ];
    const result = formatPrecedentsSection(precedents);
    assert.ok(result.includes('### Similar Resolved Issues'));
  });
});
