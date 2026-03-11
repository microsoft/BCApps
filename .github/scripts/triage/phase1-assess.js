// Phase 1: Issue quality assessment
// See: docs/features/issue-triage-agent/design.md (FR5-FR8, section 6.5)

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { callGPT } from './models-client.js';
import { detectAppArea } from './config.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Assess the quality of a GitHub issue using GPT-5.4.
 * Returns a structured assessment with scores, verdict, and missing info.
 */
export async function assessIssueQuality(issue) {
  const systemPrompt = readFileSync(
    join(__dirname, 'prompts', 'system-phase1.md'),
    'utf-8'
  );

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

  // Validate required fields
  if (!result.quality_score || typeof result.quality_score.total !== 'number') {
    throw new Error('Phase 1: Invalid response - missing quality_score.total');
  }
  if (!result.verdict) {
    throw new Error('Phase 1: Invalid response - missing verdict');
  }

  // Cross-check with our own app area detection
  const detectedArea = detectAppArea(issue.title, issue.body);
  if (result.detected_app_area === 'Unknown' && detectedArea.name !== 'Unknown') {
    result.detected_app_area = detectedArea.name;
  }

  console.log(`Phase 1 complete: Score ${result.quality_score.total}/100 - ${result.verdict}`);
  return result;
}
