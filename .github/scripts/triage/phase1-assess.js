// Phase 1: Issue quality assessment
// See: docs/features/issue-triage-agent/design.md (FR5-FR8, section 6.5)

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { callGPT } from './models-client.js';
import { detectAppArea } from './config.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

const VALID_VERDICTS = new Set(['READY', 'NEEDS WORK', 'INSUFFICIENT']);
const VALID_ISSUE_TYPES = new Set(['bug', 'feature', 'enhancement', 'question']);
const SCORE_DIMENSIONS = ['clarity', 'reproducibility', 'context', 'specificity', 'actionability'];

/**
 * Validate Phase 1 response structure and types.
 * Coerces fixable values; throws on unfixable issues.
 */
function validatePhase1Response(result) {
  if (!result.quality_score || typeof result.quality_score !== 'object') {
    throw new Error('Phase 1: Invalid response - missing quality_score object');
  }

  // Validate each dimension has a numeric score and string notes
  for (const dim of SCORE_DIMENSIONS) {
    const d = result.quality_score[dim];
    if (!d || typeof d !== 'object') {
      throw new Error(`Phase 1: Invalid response - missing quality_score.${dim}`);
    }
    if (typeof d.score !== 'number') {
      const parsed = Number(d.score);
      if (isNaN(parsed)) throw new Error(`Phase 1: Invalid response - quality_score.${dim}.score is not a number`);
      d.score = parsed;
    }
    d.score = Math.max(0, Math.min(20, Math.round(d.score)));
    if (typeof d.notes !== 'string') d.notes = String(d.notes || '');
  }

  // Recompute total from dimension scores to prevent model arithmetic errors
  result.quality_score.total = SCORE_DIMENSIONS.reduce(
    (sum, dim) => sum + result.quality_score[dim].score, 0
  );

  if (!result.verdict || !VALID_VERDICTS.has(result.verdict)) {
    // Derive verdict from score if model returned invalid value
    const total = result.quality_score.total;
    if (total >= 75) result.verdict = 'READY';
    else if (total >= 40) result.verdict = 'NEEDS WORK';
    else result.verdict = 'INSUFFICIENT';
  }

  if (!result.issue_type || !VALID_ISSUE_TYPES.has(result.issue_type)) {
    result.issue_type = 'bug'; // safe default
  }

  if (!Array.isArray(result.missing_info)) {
    result.missing_info = [];
  }

  if (typeof result.summary !== 'string') {
    result.summary = String(result.summary || '');
  }

  if (typeof result.detected_app_area !== 'string') {
    result.detected_app_area = 'Unknown';
  }

  // Validate search_terms: must be an array of 1-2 word strings
  if (!Array.isArray(result.search_terms)) {
    result.search_terms = [];
  } else {
    const cleaned = [];
    for (const t of result.search_terms) {
      if (typeof t !== 'string' || !t.trim()) continue;
      const term = t.trim().toLowerCase();
      const words = term.split(/\s+/);
      if (words.length <= 2) {
        cleaned.push(term);
      } else {
        // Split 3+ word phrases into the first 2 words and last 2 words
        cleaned.push(words.slice(0, 2).join(' '));
        if (words.length > 2) cleaned.push(words.slice(-2).join(' '));
      }
    }
    // Deduplicate while preserving order
    const seen = new Set();
    result.search_terms = cleaned.filter(t => {
      if (seen.has(t)) return false;
      seen.add(t);
      return true;
    }).slice(0, 8);
  }
}

/**
 * Assess the quality of a GitHub issue using GPT-5.4.
 * Returns a structured assessment with scores, verdict, and missing info.
 */
export async function assessIssueQuality(issue) {
  // Build system prompt from skill knowledge files + agent-specific output instructions
  const repoRoot = join(__dirname, '..', '..', '..');
  const skillDir = join(repoRoot, 'plugins', 'triage', 'skills', 'triage');
  const glossary = readFileSync(join(skillDir, 'SKILL.md'), 'utf-8')
    .replace(/^---[\s\S]*?---\n/, '') // strip frontmatter
    .match(/## BC\/AL Domain Glossary[\s\S]*?(?=## Triage Process Overview)/)?.[0] || '';
  const domainKnowledge = readFileSync(join(skillDir, 'bc-domain.md'), 'utf-8');
  const assessKnowledge = readFileSync(join(skillDir, 'triage-assess.md'), 'utf-8');

  // Load the Phase 1 system prompt template from skill file
  const promptTemplate = readFileSync(join(skillDir, 'phase1-instructions.md'), 'utf-8')
    .replace(/^[\s\S]*?---\n/, ''); // strip header (everything up to and including the --- delimiter)

  const systemPrompt = promptTemplate
    .replace('{{glossary}}', glossary)
    .replace('{{domainKnowledge}}', domainKnowledge)
    .replace('{{assessKnowledge}}', assessKnowledge);

  const commentsText = issue.comments.length > 0
    ? issue.comments.map(c => `**${c.author}**: ${c.body}`).join('\n\n')
    : '(no comments)';

  const userMessage = `## Issue #${issue.number}: ${issue.title}

**Author**: ${issue.author}
**Labels**: ${issue.labels.join(', ') || '(none)'}
**Created**: ${issue.created_at}

### Body

${issue.body || '(empty)'}

### Comments

${commentsText}`;

  console.log(`Phase 1: Assessing issue quality...`);
  const phase1Start = Date.now();
  const result = await callGPT(systemPrompt, userMessage);
  const phase1Elapsed = ((Date.now() - phase1Start) / 1000).toFixed(1);

  // Validate response structure and types
  validatePhase1Response(result);

  // Cross-check with our own app area detection
  const detectedArea = detectAppArea(issue.title, issue.body);
  if (result.detected_app_area === 'Unknown' && detectedArea.name !== 'Unknown') {
    result.detected_app_area = detectedArea.name;
  }

  console.log(`Phase 1 complete (${phase1Elapsed}s): ${result.quality_score.total}/100 ${result.verdict} | type=${result.issue_type} | area=${result.detected_app_area}`);
  return result;
}
