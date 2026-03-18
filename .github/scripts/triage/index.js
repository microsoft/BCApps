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
} from './github-client.js';
import { assessIssueQuality } from './phase1-assess.js';
import { enrichAndTriage } from './phase2-enrich.js';
import { formatTriageComment, formatInsufficientComment } from './format-comment.js';
import {
  LABELS,
  ALL_LABELS,
  SCORE_THRESHOLDS,
  getTriageLabelName,
  getPriorityLabelName,
  getComplexityLabelName,
  getEffortLabelName,
  getPathLabelName,
  getTeamLabel,
} from './config.js';

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

  console.log(`\n=== Issue Triage Agent ===`);
  console.log(`Repository: ${owner}/${repo}`);
  console.log(`Issue: #${issueNumber}\n`);

  try {
    // Step 1: Fetch issue details
    const issue = await getIssue(owner, repo, issueNumber);

    if (issue.state !== 'open') {
      console.log(`Issue #${issueNumber} is ${issue.state}. Skipping triage.`);
      return;
    }

    console.log(`Issue: "${issue.title}" by ${issue.author}`);

    // Step 2: Check for existing triage (idempotency)
    const isRetriage = await checkExistingTriage(owner, repo, issueNumber);
    if (isRetriage) {
      console.log('Previous triage detected - this will be a re-triage.');
    }

    // Step 3: Phase 1 - Quality Assessment
    const phase1Result = await assessIssueQuality(issue);
    const qualityScore = phase1Result.quality_score.total;

    // Step 4: Decide path based on quality score
    if (qualityScore < SCORE_THRESHOLDS.NEEDS_WORK) {
      // INSUFFICIENT - post needs-info comment, skip Phase 2
      console.log(`Score ${qualityScore} < ${SCORE_THRESHOLDS.NEEDS_WORK}: ${phase1Result.verdict} - skipping Phase 2`);

      const comment = formatInsufficientComment(phase1Result);
      await postComment(owner, repo, issueNumber, comment);

      await manageCategoryLabels(owner, repo, issueNumber, 'triage/', getTriageLabelName(phase1Result.verdict), ALL_LABELS);
      console.log(`Labels applied: ${getTriageLabelName(phase1Result.verdict)}`);

      console.log(`\n=== Triage complete (${phase1Result.verdict}) ===`);
      return;
    }

    // Step 5: Phase 2 - Enrichment & Triage
    const phase2Result = await enrichAndTriage(issue, phase1Result);

    // Step 6: Format and post full triage comment
    const comment = formatTriageComment(phase1Result, phase2Result, isRetriage);
    await postComment(owner, repo, issueNumber, comment);
    console.log('Triage comment posted.');

    // Step 7: Apply labels
    const triage = phase2Result.triage;

    const teamLabel = getTeamLabel(issue.title, issue.body, phase1Result.detected_app_area || '');

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

    // Apply team label (remove other team labels first, then add the correct one)
    for (const label of LABELS.team) {
      if (label.name !== teamLabel) {
        await removeLabel(owner, repo, issueNumber, label.name);
      }
    }
    await ensureLabel(owner, repo, teamLabel,
      LABELS.team.find(l => l.name === teamLabel)?.color || 'EDEDED',
      LABELS.team.find(l => l.name === teamLabel)?.description || '');
    await addLabels(owner, repo, issueNumber, [teamLabel]);

    const appliedLabels = [...labelOps.map(op => op.label), teamLabel].join(', ');
    console.log(`Labels applied: ${appliedLabels}`);

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
