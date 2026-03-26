// Unit tests for phase2-enrich.js - exported utility helpers
// Run with: node --test tests/phase2-enrich.test.js

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { escapeMdTable, isAllowedDocUrl, sanitizeCompetitiveLandscape } from '../phase2-enrich.js';

// ─── escapeMdTable ───

describe('escapeMdTable', () => {
  it('returns empty string for null', () => {
    assert.equal(escapeMdTable(null), '');
  });

  it('returns empty string for undefined', () => {
    assert.equal(escapeMdTable(undefined), '');
  });

  it('passes through normal text unchanged', () => {
    assert.equal(escapeMdTable('normal text'), 'normal text');
  });

  it('escapes pipe characters', () => {
    assert.equal(escapeMdTable('has | pipe'), 'has \\| pipe');
  });

  it('replaces newlines with spaces', () => {
    assert.equal(escapeMdTable('has\nnewline'), 'has newline');
  });

  it('escapes pipes and replaces newlines together', () => {
    assert.equal(escapeMdTable('has | pipe\nand newline'), 'has \\| pipe and newline');
  });
});

// ─── isAllowedDocUrl ───

describe('isAllowedDocUrl', () => {
  it('allows learn.microsoft.com URLs', () => {
    assert.equal(isAllowedDocUrl('https://learn.microsoft.com/en-us/dynamics365/business-central/overview'), true);
  });

  it('allows experience.dynamics.com URLs', () => {
    assert.equal(isAllowedDocUrl('https://experience.dynamics.com/ideas/idea/?v=2'), true);
  });

  it('allows github.com URLs', () => {
    assert.equal(isAllowedDocUrl('https://github.com/microsoft/ALAppExtensions'), true);
  });

  it('allows community.dynamics.com URLs', () => {
    assert.equal(isAllowedDocUrl('https://community.dynamics.com/forums/thread/details/?threadid=abc'), true);
  });

  it('allows www.dynamicsuser.net URLs', () => {
    assert.equal(isAllowedDocUrl('https://www.dynamicsuser.net/c/nav-tips-tricks/'), true);
  });

  it('rejects unknown domains', () => {
    assert.equal(isAllowedDocUrl('https://evil.com/fake'), false);
  });

  it('rejects empty string', () => {
    assert.equal(isAllowedDocUrl(''), false);
  });

  it('rejects null', () => {
    assert.equal(isAllowedDocUrl(null), false);
  });
});

// ─── sanitizeCompetitiveLandscape ───

describe('sanitizeCompetitiveLandscape', () => {
  it('returns empty string for null', () => {
    assert.equal(sanitizeCompetitiveLandscape(null), '');
  });

  it('returns empty string for empty string', () => {
    assert.equal(sanitizeCompetitiveLandscape(''), '');
  });

  it('leaves generic text unchanged', () => {
    const text = 'A major cloud ERP competitor offers this';
    assert.equal(sanitizeCompetitiveLandscape(text), text);
  });

  it('redacts SAP Business One', () => {
    const result = sanitizeCompetitiveLandscape('SAP Business One handles this well');
    assert.ok(!result.includes('SAP Business One'));
    assert.ok(result.includes('[competing ERP]'));
  });

  it('redacts Oracle NetSuite and SAP together', () => {
    const result = sanitizeCompetitiveLandscape('Oracle NetSuite and SAP provide this');
    assert.ok(!result.includes('Oracle NetSuite'));
    assert.ok(!result.includes('SAP'));
    assert.ok(result.includes('[competing ERP]'));
  });

  it('redacts SAP', () => {
    assert.ok(!sanitizeCompetitiveLandscape('SAP offers it').includes('SAP'));
  });

  it('redacts Oracle', () => {
    assert.ok(!sanitizeCompetitiveLandscape('Oracle has it').includes('Oracle'));
  });

  it('redacts NetSuite', () => {
    assert.ok(!sanitizeCompetitiveLandscape('NetSuite provides').includes('NetSuite'));
  });

  it('redacts Sage', () => {
    assert.ok(!sanitizeCompetitiveLandscape('Sage does this').includes('Sage'));
  });

  it('redacts QuickBooks', () => {
    assert.ok(!sanitizeCompetitiveLandscape('QuickBooks handles it').includes('QuickBooks'));
  });

  it('redacts Xero', () => {
    assert.ok(!sanitizeCompetitiveLandscape('Xero supports this').includes('Xero'));
  });

  it('redacts Acumatica', () => {
    assert.ok(!sanitizeCompetitiveLandscape('Acumatica offers it').includes('Acumatica'));
  });

  it('redacts Odoo', () => {
    assert.ok(!sanitizeCompetitiveLandscape('Odoo has this feature').includes('Odoo'));
  });

  it('redacts Infor', () => {
    assert.ok(!sanitizeCompetitiveLandscape('Infor provides this').includes('Infor'));
  });
});
