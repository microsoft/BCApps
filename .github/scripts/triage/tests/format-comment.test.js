// Unit tests for format-comment.js - compact and fallback comment formatting
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

describe('formatTriageComment - compact mode (with wiki URL)', () => {
  const wikiUrl = 'https://github.com/owner/repo/wiki/Triage-Report-Issue-5';

  it('should include the AI Triage Assessment header', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, wikiUrl);
    assert.ok(comment.includes('## :robot: AI Triage Assessment'));
  });

  it('should include compact summary table', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, wikiUrl);
    assert.ok(comment.includes('| READY | 82/100 | 7/10 |'));
  });

  it('should include wiki link', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, wikiUrl);
    assert.ok(comment.includes('[View full triage report →]'));
    assert.ok(comment.includes(wikiUrl));
  });

  it('should include executive summary', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, wikiUrl);
    assert.ok(comment.includes('High-value fix'));
  });

  it('should NOT include verbose quality dimension table', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, wikiUrl);
    assert.ok(!comment.includes('| Clarity |'));
    assert.ok(!comment.includes('| Reproducibility |'));
  });

  it('should NOT include enrichment details section', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, wikiUrl);
    assert.ok(!comment.includes('<details>'));
    assert.ok(!comment.includes('Enrichment context'));
  });

  it('should show re-triage notice', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, true, [], null, wikiUrl);
    assert.ok(comment.includes('Re-triage'));
  });

  it('should include missing info when present', () => {
    const phase1WithMissing = {
      ...mockPhase1,
      missing_info: ['BC version needed', 'Steps to reproduce'],
    };
    const comment = formatTriageComment(phase1WithMissing, mockPhase2, false, [], null, wikiUrl);
    assert.ok(comment.includes('BC version needed'));
  });
});

describe('formatTriageComment - verbose fallback (no wiki URL)', () => {
  it('should include full quality dimension table when wikiUrl is null', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, null);
    assert.ok(comment.includes('| Clarity |'));
    assert.ok(comment.includes('| Reproducibility |'));
    assert.ok(comment.includes('Triage Recommendation'));
  });

  it('should include enrichment details section', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, null);
    assert.ok(comment.includes('<details>'));
  });

  it('should note wiki was unavailable', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, null);
    assert.ok(comment.includes('could not be published to wiki'));
  });

  it('should not exceed GitHub comment limit', () => {
    const comment = formatTriageComment(mockPhase1, mockPhase2, false, [], null, null);
    assert.ok(comment.length <= 65536);
  });
});

describe('formatInsufficientComment', () => {
  const insufficientPhase1 = {
    ...mockPhase1,
    quality_score: { ...mockPhase1.quality_score, total: 20 },
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
