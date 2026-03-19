// Unit tests for config.js - app area detection, team labels, and label mapping
// Run with: node --test tests/config.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  detectAppArea,
  getTeamLabel,
  getTriageLabelName,
  getPriorityLabelName,
  getComplexityLabelName,
  getEffortLabelName,
  getPathLabelName,
  getTypeLabelName,
  VERDICT,
} from '../config.js';

describe('detectAppArea', () => {
  it('should detect Shopify from keywords', () => {
    const area = detectAppArea('Shopify sync issue', 'Products not syncing');
    assert.equal(area.name, 'Shopify');
  });

  it('should detect E-Document from keywords', () => {
    const area = detectAppArea('E-Document export fails', '');
    assert.equal(area.name, 'E-Document');
  });

  it('should detect BaseApp sub-areas', () => {
    const area = detectAppArea('Bank reconciliation problem', 'Cannot reconcile bank account');
    assert.equal(area.name, 'BaseApp - Bank');
    assert.ok(area.directory.includes('BaseApp/Bank'));
  });

  it('should detect BaseApp Finance sub-area', () => {
    const area = detectAppArea('General ledger posting issue', 'Dimensions not applied');
    assert.equal(area.name, 'BaseApp - Finance');
  });

  it('should detect BaseApp Warehouse sub-area', () => {
    const area = detectAppArea('Warehouse receipt issue', 'Put away not created');
    assert.equal(area.name, 'BaseApp - Warehouse');
  });

  it('should detect BaseApp catch-all for generic base app references', () => {
    const area = detectAppArea('Base application issue', '');
    assert.equal(area.name, 'BaseApp');
  });

  it('should return Unknown for unrecognized text', () => {
    const area = detectAppArea('xyz123', 'completely unrelated text nothing matches');
    assert.equal(area.name, 'Unknown');
  });

  it('should prefer explicit keyword match over fallback directory scan', () => {
    const area = detectAppArea('Subscription billing recurring', '');
    assert.equal(area.name, 'Subscription Billing');
    assert.ok(area.directory.includes('Subscription Billing'));
  });
});

describe('getTeamLabel', () => {
  it('should assign Finance for finance keywords', () => {
    assert.equal(getTeamLabel('General ledger posting', 'budget consolidation', ''), 'Finance');
  });

  it('should assign SCM for supply chain keywords', () => {
    assert.equal(getTeamLabel('Purchase order issue', 'inventory tracking', ''), 'SCM');
  });

  it('should assign Integration for integration keywords', () => {
    assert.equal(getTeamLabel('API webhook', 'dataverse integration', ''), 'Integration');
  });

  it('should default to Integration for unknown text', () => {
    assert.equal(getTeamLabel('xyz', 'abc', ''), 'Integration');
  });

  it('should consider app area name in scoring', () => {
    assert.equal(getTeamLabel('some issue', 'details', 'Shopify'), 'Integration');
  });
});

describe('label mapping functions', () => {
  it('getTriageLabelName should map READY', () => {
    assert.equal(getTriageLabelName(VERDICT.READY), 'triage/ready');
  });

  it('getTriageLabelName should map NEEDS_WORK', () => {
    assert.equal(getTriageLabelName(VERDICT.NEEDS_WORK), 'triage/needs-info');
  });

  it('getTriageLabelName should map INSUFFICIENT', () => {
    assert.equal(getTriageLabelName(VERDICT.INSUFFICIENT), 'triage/insufficient');
  });

  it('getPriorityLabelName should map score ranges', () => {
    assert.equal(getPriorityLabelName(10), 'priority/critical');
    assert.equal(getPriorityLabelName(9), 'priority/critical');
    assert.equal(getPriorityLabelName(8), 'priority/high');
    assert.equal(getPriorityLabelName(5), 'priority/medium');
    assert.equal(getPriorityLabelName(2), 'priority/low');
  });

  it('getComplexityLabelName should handle case insensitive', () => {
    assert.equal(getComplexityLabelName('Low'), 'complexity/low');
    assert.equal(getComplexityLabelName('HIGH'), 'complexity/high');
    assert.equal(getComplexityLabelName('Very High'), 'complexity/high');
  });

  it('getEffortLabelName should map effort ratings', () => {
    assert.equal(getEffortLabelName('XS'), 'effort/xs-s');
    assert.equal(getEffortLabelName('S'), 'effort/xs-s');
    assert.equal(getEffortLabelName('M'), 'effort/m');
    assert.equal(getEffortLabelName('L'), 'effort/l-xl');
    assert.equal(getEffortLabelName('XL'), 'effort/l-xl');
  });

  it('getPathLabelName should map implementation paths', () => {
    assert.equal(getPathLabelName('Manual'), 'path/manual');
    assert.equal(getPathLabelName('Copilot-Assisted'), 'path/copilot-assisted');
    assert.equal(getPathLabelName('Agentic'), 'path/agentic');
  });

  it('getTypeLabelName should map issue types', () => {
    assert.equal(getTypeLabelName('bug'), 'type/bug');
    assert.equal(getTypeLabelName('feature'), 'type/feature');
    assert.equal(getTypeLabelName('enhancement'), 'type/enhancement');
    assert.equal(getTypeLabelName('question'), 'type/question');
  });

  it('getTypeLabelName should default to bug for unknown types', () => {
    assert.equal(getTypeLabelName(''), 'type/bug');
    assert.equal(getTypeLabelName(null), 'type/bug');
  });
});
