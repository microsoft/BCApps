// Unit tests for format-report.js - wiki report formatting
// Run with: node --test tests/format-report.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { formatWikiReport } from '../format-report.js';

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
    documentation: [{ title: 'Shopify docs', url: 'https://learn.microsoft.com/shopify', relevance: 'Main docs' }],
    ideas_portal: [],
    community: [],
    code_areas: [{ path: 'src/Apps/W1/Shopify/', relevance: 'Main app directory' }],
    analyzed_files: ['src/Apps/W1/Shopify/App/src/Sync.Codeunit.al'],
    analyzed_directory: 'src/Apps/W1/Shopify/',
    matched_ideas: [{ title: 'Better sync', url: 'https://ideas.example.com/1', votes: 42, status: 'Under Review' }],
    ado_work_items: [{ type: 'Bug', id: 123, title: 'Sync fix', url: 'https://ado.example.com/123', state: 'Active' }],
  },
  executive_summary: 'High-value fix for Shopify sync issue.',
};

const issueMeta = {
  number: 5,
  title: 'Shopify Connector sync fails for large catalogs',
  author: 'testuser',
  url: 'https://github.com/owner/repo/issues/5',
};

describe('formatWikiReport', () => {
  it('should include issue title as page heading', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, false, [], null, issueMeta);
    assert.ok(report.includes('# Issue #5:'));
    assert.ok(report.includes('Shopify Connector'));
  });

  it('should include issue metadata', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, false, [], null, issueMeta);
    assert.ok(report.includes('@testuser'));
    assert.ok(report.includes('READY'));
    assert.ok(report.includes('82/100'));
    assert.ok(report.includes('7/10'));
  });

  it('should include full quality score table', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, false, [], null, issueMeta);
    assert.ok(report.includes('| Clarity |'));
    assert.ok(report.includes('| Reproducibility |'));
    assert.ok(report.includes('| Context |'));
    assert.ok(report.includes('| Specificity |'));
    assert.ok(report.includes('| Actionability |'));
  });

  it('should include triage recommendation table', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, false, [], null, issueMeta);
    assert.ok(report.includes('| Complexity |'));
    assert.ok(report.includes('| Value |'));
    assert.ok(report.includes('| Priority |'));
    assert.ok(report.includes('Implement'));
  });

  it('should include enrichment context in collapsible sections', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, false, [], null, issueMeta);
    assert.ok(report.includes('<details>'));
    assert.ok(report.includes('Enrichment context'));
    assert.ok(report.includes('Shopify docs'));
    assert.ok(report.includes('Better sync'));
    assert.ok(report.includes('Bug #123'));
  });

  it('should include back-to-issue link', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, false, [], null, issueMeta);
    assert.ok(report.includes('[Back to issue]'));
    assert.ok(report.includes(issueMeta.url));
  });

  it('should show re-triage notice', () => {
    const report = formatWikiReport(mockPhase1, mockPhase2, true, [], null, issueMeta);
    assert.ok(report.includes('Re-triage'));
  });

  it('should show re-triage diff when previous scores available', () => {
    const prevScores = { qualityTotal: 60, priority: 5, verdict: 'NEEDS WORK' };
    const report = formatWikiReport(mockPhase1, mockPhase2, true, [], prevScores, issueMeta);
    assert.ok(report.includes('Changes since last triage'));
    assert.ok(report.includes('60/100'));
  });
});
