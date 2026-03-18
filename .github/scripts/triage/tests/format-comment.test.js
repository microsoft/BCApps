// Unit tests for format-comment.js - comment formatting and truncation
// Run with: node --test tests/format-comment.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { formatTriageComment, formatInsufficientComment } from '../format-comment.js';

const mockPhase1 = {
  quality_score: {
    clarity: { score: 18, notes: 'Clear' },
    reproducibility: { score: 16, notes: 'Good steps' },
    context: { score: 15, notes: 'Version provided' },
    specificity: { score: 17, notes: 'Well scoped' },
    actionability: { score: 16, notes: 'Ready to go' },
    total: 82,
  },
  verdict: 'READY',
  missing_info: [],
  detected_app_area: 'Shopify',
  issue_type: 'bug',
  summary: 'Shopify sync fails for large catalogs',
};

const mockPhase2 = {
  triage: {
    complexity: { rating: 'Medium', rationale: 'Multi-file change' },
    value: { rating: 'High', rationale: 'Affects many users' },
    risk: { rating: 'Low', rationale: 'Isolated change' },
    effort: { rating: 'M', rationale: '1-3 days' },
    implementation_path: { rating: 'Copilot-Assisted', rationale: 'Follows patterns' },
    priority_score: { score: 7, rationale: 'High value, medium effort' },
    confidence: { rating: 'High', rationale: 'Code reviewed' },
    recommended_action: { action: 'Implement', rationale: 'Worth doing' },
  },
  enrichment: {
    documentation: [],
    ideas_portal: [],
    community: [],
    code_areas: [],
    analyzed_files: ['src/Apps/W1/Shopify/App/src/Sync.Codeunit.al'],
    analyzed_directory: 'src/Apps/W1/Shopify/',
    matched_ideas: [],
    ado_work_items: [],
  },
  executive_summary: 'High-value fix for Shopify sync issue.',
};

describe('formatTriageComment', () => {
  it('should include the AI Triage Assessment header', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false);
    assert.ok(comment.includes('## :robot: AI Triage Assessment'));
  });

  it('should include quality scores', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false);
    assert.ok(comment.includes('82/100'));
    assert.ok(comment.includes('READY'));
  });

  it('should include triage recommendation', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false);
    assert.ok(comment.includes('7/10'));
    assert.ok(comment.includes('Implement'));
  });

  it('should show re-triage notice', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, true);
    assert.ok(comment.includes('Re-triage'));
  });

  it('should show re-triage diff when previous scores available', () => {
    const prevScores = { qualityTotal: 60, priority: 5, verdict: 'NEEDS WORK', clarity: 12 };
    const comment = formatTriageComment(mockPhase1, mockPhase2, true, [], prevScores);
    assert.ok(comment.includes('Changes since last triage'));
    assert.ok(comment.includes('60/100'));
    assert.ok(comment.includes('82/100'));
  });

  it('should not exceed GitHub comment limit', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false);
    assert.ok(comment.length <= 65536);
  });
});

describe('formatInsufficientComment', () => {
  const insufficientPhase1 = {
    ...mockPhase1,
    quality_score: {
      ...mockPhase1.quality_score,
      total: 20,
    },
    verdict: 'INSUFFICIENT',
    missing_info: ['Steps to reproduce', 'BC version'],
  };

  it('should include INSUFFICIENT header', () => {
    const comment = formatInsufficientComment(insufficientPhase1);
    assert.ok(comment.includes('INSUFFICIENT'));
  });

  it('should list missing info items', () => {
    const comment = formatInsufficientComment(insufficientPhase1);
    assert.ok(comment.includes('Steps to reproduce'));
    assert.ok(comment.includes('BC version'));
  });

  it('should include duplicates section when provided', () => {
    const dupes = [{ number: 10, title: 'Dup', similarity: 50, url: 'https://example.com' }];
    const comment = formatInsufficientComment(insufficientPhase1, dupes);
    assert.ok(comment.includes('#10'));
  });
});
