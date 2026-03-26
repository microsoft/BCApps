// Unit tests for duplicate-detector.js - tokenization and similarity
// Run with: node --test tests/duplicate-detector.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { formatDuplicatesSection } from '../duplicate-detector.js';

describe('formatDuplicatesSection', () => {
  it('should return empty string for no duplicates', () => {
    assert.equal(formatDuplicatesSection([]), '');
    assert.equal(formatDuplicatesSection(null), '');
    assert.equal(formatDuplicatesSection(undefined), '');
  });

  it('should format duplicates with links and similarity', () => {
    const duplicates = [
      { number: 42, title: 'Similar issue', similarity: 65, url: 'https://github.com/test/repo/issues/42' },
    ];
    const result = formatDuplicatesSection(duplicates);
    assert.ok(result.includes('#42'));
    assert.ok(result.includes('Similar issue'));
    assert.ok(result.includes('65%'));
    assert.ok(result.includes('Potential Duplicates'));
  });
});
