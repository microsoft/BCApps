// Unit tests for text-similarity.js
// Run with: node --test tests/text-similarity.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { tokenize, jaccardSimilarity, weightedSimilarity } from '../text-similarity.js';

describe('tokenize', () => {
  it('should remove stop words', () => {
    const tokens = tokenize('the issue is a problem with the feature');
    assert.ok(!tokens.has('the'));
    assert.ok(!tokens.has('is'));
    assert.ok(!tokens.has('a'));
    assert.ok(!tokens.has('with'));
  });

  it('should normalize BC domain synonyms', () => {
    const tokens1 = tokenize('posted sales invoice amounts wrong');
    const tokens2 = tokenize('sales invoice incorrect totals');
    // Both should contain the canonical 'sales_invoice' token
    assert.ok(tokens1.has('sales_invoice'), 'posted sales invoice should normalize');
    assert.ok(tokens2.has('sales_invoice'), 'sales invoice should normalize');
  });

  it('should generate bigrams', () => {
    const tokens = tokenize('warehouse receipt processing fails');
    assert.ok(tokens.has('warehouse_receipt'), 'should have warehouse_receipt bigram');
  });

  it('should handle empty input', () => {
    assert.equal(tokenize('').size, 0);
    assert.equal(tokenize(null).size, 0);
    assert.equal(tokenize(undefined).size, 0);
  });
});

describe('jaccardSimilarity', () => {
  it('should return 1 for identical sets', () => {
    const set = new Set(['abc', 'def']);
    assert.equal(jaccardSimilarity(set, set), 1);
  });

  it('should return 0 for disjoint sets', () => {
    const a = new Set(['abc']);
    const b = new Set(['def']);
    assert.equal(jaccardSimilarity(a, b), 0);
  });

  it('should return 0 for two empty sets', () => {
    assert.equal(jaccardSimilarity(new Set(), new Set()), 0);
  });
});

describe('weightedSimilarity', () => {
  it('should score high for same-title issues with different bodies', () => {
    const sim = weightedSimilarity(
      'Bank reconciliation error', 'Cannot complete automatic matching',
      'Bank reconciliation error', 'The reconcile function throws an exception',
    );
    // Titles are identical → should score well above threshold
    assert.ok(sim > 0.4, `Expected > 0.4, got ${sim}`);
  });

  it('should catch synonym-based semantic duplicates', () => {
    const sim = weightedSimilarity(
      'Sales invoice rounding error', 'Amounts are off by one cent',
      'Incorrect amounts on posted sales invoices', 'Rounding difference in totals',
    );
    // Without synonyms these share few tokens; with synonyms both have
    // sales_invoice and rounding canonical forms
    assert.ok(sim > 0.15, `Expected > 0.15 with synonym normalization, got ${sim}`);
  });

  it('should score low for unrelated issues', () => {
    const sim = weightedSimilarity(
      'Shopify connector timeout', 'Products fail to sync',
      'Bank reconciliation error', 'Cannot match entries',
    );
    assert.ok(sim < 0.15, `Expected < 0.15 for unrelated issues, got ${sim}`);
  });

  it('should handle empty inputs', () => {
    const sim = weightedSimilarity('', '', '', '');
    assert.equal(sim, 0);
  });
});
