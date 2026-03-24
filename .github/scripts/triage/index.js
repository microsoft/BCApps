// Main orchestrator for the Issue Triage Agent
// See: docs/features/issue-triage-agent/design.md (section 6.1)

import {
  getIssue,
  postComment,
  checkExistingTriage,
  manageCategoryLabels,
  ensureLabel,
  addLabels,
  removeLabel,
  setIssueType,
} from './github-client.js';
import { assessIssueQuality } from './phase1-assess.js';
import { enrichAndTriage } from './phase2-enrich.js';
import { formatTriageComment, formatInsufficientComment } from './format-comment.js';
import { formatWikiReport } from './format-report.js';
import { publishWikiReport } from './wiki-client.js';
import { findDuplicates } from './duplicate-detector.js';
import {
  LABELS,
  ALL_LABELS,
  SCORE_THRESHOLDS,
  getTriageLabelName,
  getPriorityLabelName,
  getComplexityLabelName,
  getEffortLabelName,
  getPathLabelName,
  getIssueTypeName,
  getTeamLabel,
} from './config.js';

/**
 * Apply team label to an issue. Always runs regardless of TRIAGE_POST_RESULTS.
 */
async function applyTeamLabel(owner, repo, issueNumber, teamLabel) {
  for (const label of LABELS.team) {
    if (label.name !== teamLabel) {
      await removeLabel(owner, repo, issueNumber, label.name);
    }
  }
  await ensureLabel(owner, repo, teamLabel,
    LABELS.team.find(l => l.name === teamLabel)?.color || 'EDEDED',
    LABELS.team.find(l => l.name === teamLabel)?.description || '');
  await addLabels(owner, repo, issueNumber, [teamLabel]);
  console.log(`Team label applied: ${teamLabel}`);
}

async function main() {
  // Read environment variables
  const token = process.env.GITHUB_TOKEN;
  const issueNumber = parseInt(process.env.ISSUE_NUMBER, 10);
  const owner = process.env.REPO_OWNER;
  const repo = process.env.REPO_NAME;

  if (!token || !Number.isInteger(issueNumber) || !owner || !repo) {
    console.error('Missing or invalid environment variables: GITHUB_TOKEN, ISSUE_NUMBER, REPO_OWNER, REPO_NAME');
    process.exit(1);
  }

  // If TRIAGE_REPO is set, triage reports go to a separate repo's wiki
  // and only a brief comment is posted on the issue (no labels).
  // If not set, the full summary is posted on the issue with labels.
  const triageRepo = process.env.TRIAGE_REPO || '';
  const postResults = !triageRepo;

  console.log(`\n=== Issue Triage Agent ===`);
  console.log(`Repository: ${owner}/${repo}`);
  console.log(`Issue: #${issueNumber}`);
  console.log(`Triage repo: ${triageRepo || '(same repo)'} → postResults=${postResults}\n`);

  try {
    // Step 1: Fetch issue details
    const issue = await getIssue(owner, repo, issueNumber);

    if (issue.state !== 'open') {
      console.log(`Issue #${issueNumber} is ${issue.state}. Skipping triage.`);
      return;
    }

    console.log(`Issue: "${issue.title}" by ${issue.author}`);

    // Step 2: Check for existing triage and potential duplicates (in parallel)
    const [triageCheck, duplicates] = await Promise.all([
      checkExistingTriage(owner, repo, issueNumber),
      findDuplicates(owner, repo, issueNumber, issue.title, issue.body),
    ]);
    const isRetriage = triageCheck.isRetriage;
    const previousScores = triageCheck.previousScores;
    if (isRetriage) {
      console.log('Previous triage detected - this will be a re-triage.');
      if (previousScores) {
        console.log(`Previous scores: quality=${previousScores.qualityTotal}, priority=${previousScores.priority}`);
      }
    }
    if (duplicates.length > 0) {
      console.log(`Potential duplicates found: ${duplicates.map(d => `#${d.number}`).join(', ')}`);
    }

    // Step 2b: Short-circuit for near-empty issues (saves a model call)
    const titleLength = (issue.title || '').trim().length;
    const bodyLength = (issue.body || '').trim().length;
    // Always apply team label (regardless of postResults setting)
    const teamLabel = getTeamLabel(issue.title, issue.body, '');
    await applyTeamLabel(owner, repo, issueNumber, teamLabel);

    if (titleLength < 10 && bodyLength < 20) {
      console.log(`Issue too short (title: ${titleLength} chars, body: ${bodyLength} chars) - marking INSUFFICIENT`);
      const emptyPhase1 = {
        quality_score: {
          clarity: { score: 2, notes: 'Title and body are too short to assess' },
          reproducibility: { score: 0, notes: 'No reproduction steps or acceptance criteria provided' },
          context: { score: 0, notes: 'No context provided' },
          specificity: { score: 2, notes: 'Cannot determine scope from minimal text' },
          actionability: { score: 0, notes: 'Cannot start work without more information' },
          total: 4,
        },
        verdict: 'INSUFFICIENT',
        missing_info: [
          'A clear description of the problem or feature request',
          'Steps to reproduce (for bugs) or acceptance criteria (for features)',
          'Business Central version and environment details',
        ],
        detected_app_area: 'Unknown',
        issue_type: 'bug',
        summary: 'Issue has insufficient content for assessment',
      };
      if (postResults) {
        const comment = formatInsufficientComment(emptyPhase1, duplicates);
        await postComment(owner, repo, issueNumber, comment);
        await manageCategoryLabels(owner, repo, issueNumber, 'triage/', 'triage/insufficient', ALL_LABELS);
      }
      console.log(`\n=== Triage complete (INSUFFICIENT - minimal content) ===`);
      return;
    }

    // Step 3: Phase 1 - Quality Assessment
    const phase1Result = await assessIssueQuality(issue);
    const qualityScore = phase1Result.quality_score.total;

    // Step 4: Decide path based on quality score
    if (qualityScore < SCORE_THRESHOLDS.NEEDS_WORK) {
      // INSUFFICIENT - post needs-info comment, skip Phase 2
      console.log(`Score ${qualityScore} < ${SCORE_THRESHOLDS.NEEDS_WORK}: ${phase1Result.verdict} - skipping Phase 2`);

      if (postResults) {
        const comment = formatInsufficientComment(phase1Result, duplicates);
        await postComment(owner, repo, issueNumber, comment);
        await manageCategoryLabels(owner, repo, issueNumber, 'triage/', getTriageLabelName(phase1Result.verdict), ALL_LABELS);
        console.log(`Labels applied: ${getTriageLabelName(phase1Result.verdict)}`);
      } else {
        await postComment(owner, repo, issueNumber,
          `:robot: AI triage completed — issue scored ${qualityScore}/100 (${phase1Result.verdict}). More information is needed before full triage can proceed.`);
        console.log('Post results disabled — skipping labels. Minimal comment posted.');
      }

      console.log(`\n=== Triage complete (${phase1Result.verdict}) ===`);
      return;
    }

    // Step 5: Phase 2 - Enrichment & Triage
    const phase2Result = await enrichAndTriage(issue, phase1Result);

    // Step 6a: Publish full report to wiki (always — this is the detailed record)
    const issueMeta = {
      number: issueNumber,
      title: issue.title,
      author: issue.author,
      url: `https://github.com/${owner}/${repo}/issues/${issueNumber}`,
    };
    const wikiMarkdown = formatWikiReport(phase1Result, phase2Result, isRetriage, duplicates, previousScores, issueMeta);
    const wikiUrl = await publishWikiReport(owner, repo, issueNumber, wikiMarkdown);

    if (wikiUrl) {
      console.log(`Wiki report published: ${wikiUrl}`);
    } else {
      console.warn('Wiki report could not be published; falling back to verbose comment.');
    }

    // Step 6b: Post comment and apply labels (controlled by TRIAGE_POST_RESULTS)
    const triage = phase2Result.triage;

    if (postResults) {
      const comment = formatTriageComment(phase1Result, phase2Result, isRetriage, duplicates, previousScores, wikiUrl);
      await postComment(owner, repo, issueNumber, comment);
      console.log('Triage comment posted.');

      // Apply triage labels
      const labelOps = [
        { prefix: 'triage/', label: getTriageLabelName(phase1Result.verdict), category: LABELS.triage },
        { prefix: 'priority/', label: getPriorityLabelName(triage.priority_score.score), category: LABELS.priority },
        { prefix: 'complexity/', label: getComplexityLabelName(triage.complexity.rating), category: LABELS.complexity },
        { prefix: 'effort/', label: getEffortLabelName(triage.effort.rating), category: LABELS.effort },
        { prefix: 'path/', label: getPathLabelName(triage.implementation_path.rating), category: LABELS.path },
      ];

      for (const op of labelOps) {
        await manageCategoryLabels(owner, repo, issueNumber, op.prefix, op.label, op.category);
      }

      const appliedLabels = labelOps.map(op => op.label).join(', ');
      console.log(`Labels applied: ${appliedLabels}`);
    } else {
      // Post a minimal comment with just the wiki link
      if (wikiUrl) {
        await postComment(owner, repo, issueNumber,
          `:robot: AI triage completed. Product Group, please validate results at [Triage Report](${wikiUrl}).`);
      }
      console.log('Post results disabled — skipping labels. Minimal comment posted.');
    }

    // Set GitHub issue type (Bug/Feature/Task) — always runs
    const issueTypeName = getIssueTypeName(phase1Result.issue_type);
    await setIssueType(owner, repo, issueNumber, issueTypeName);

    // Update team label with Phase 1 app area (more accurate than initial detection)
    const refinedTeamLabel = getTeamLabel(issue.title, issue.body, phase1Result.detected_app_area || '');
    if (refinedTeamLabel !== teamLabel) {
      await applyTeamLabel(owner, repo, issueNumber, refinedTeamLabel);
    }

    console.log(`\n=== Triage complete ===`);
    console.log(`Quality: ${qualityScore}/100 (${phase1Result.verdict})`);
    console.log(`Priority: ${triage.priority_score.score}/10`);
    console.log(`Action: ${triage.recommended_action.action}`);

  } catch (err) {
    console.error(`Triage failed: ${err.message}`);

    // Best-effort: post error comment so the issue author knows
    try {
      const errorComment = [
        '## :robot: AI Triage Assessment\n',
        '> :warning: **Triage could not be completed**\n',
        `Error: ${err.message}\n`,
        'Please try removing and re-adding the `ai-triage` label to retry.',
      ].join('\n');
      await postComment(owner, repo, issueNumber, errorComment);
    } catch {
      // If we can't even post the error comment, just log it
      console.error('Failed to post error comment');
    }

    process.exit(1);
  }
}

main();
