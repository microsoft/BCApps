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
  const assessKnowledge = readFileSync(join(skillDir, 'triage-assess.md'), 'utf-8');

  const systemPrompt = `You are a senior QA analyst evaluating GitHub issue quality for a Microsoft Dynamics 365 Business Central application repository. Your job is to assess whether an issue has enough information for a developer to start working on it.

${glossary}

${assessKnowledge}

## Issue type classification

Classify the issue as one of: "bug", "feature", "enhancement", "question"

## App area detection

The repository contains Business Central apps. Based on keywords in the title and body, detect which app area this relates to. If no area matches, use "Unknown".

## Output format

Return a JSON object with this exact structure:
\`\`\`json
{
  "quality_score": {
    "clarity": { "score": 0, "notes": "explanation" },
    "reproducibility": { "score": 0, "notes": "explanation" },
    "context": { "score": 0, "notes": "explanation" },
    "specificity": { "score": 0, "notes": "explanation" },
    "actionability": { "score": 0, "notes": "explanation" },
    "total": 0
  },
  "verdict": "READY|NEEDS WORK|INSUFFICIENT",
  "missing_info": ["specific missing item 1", "specific missing item 2"],
  "detected_app_area": "area name",
  "issue_type": "bug|feature|enhancement|question",
  "summary": "One-line summary of what this issue is about"
}
\`\`\`

Return ONLY valid JSON. No markdown fences, no explanation text outside the JSON.`;

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

  console.log(`Phase 1: Assessing issue #${issue.number} quality...`);
  const result = await callGPT(systemPrompt, userMessage);

  // Validate response structure and types
  validatePhase1Response(result);

  // Cross-check with our own app area detection
  const detectedArea = detectAppArea(issue.title, issue.body);
  if (result.detected_app_area === 'Unknown' && detectedArea.name !== 'Unknown') {
    result.detected_app_area = detectedArea.name;
  }

  console.log(`Phase 1 complete: Score ${result.quality_score.total}/100 - ${result.verdict}`);
  return result;
}
