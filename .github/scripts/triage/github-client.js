// GitHub REST API client for issue operations
// See: docs/features/issue-triage-agent/design.md (FR4, FR15-FR21, section 6.8)

import { Octokit } from '@octokit/rest';

let _octokit;

function getOctokit() {
  if (!_octokit) {
    const token = process.env.GITHUB_TOKEN;
    if (!token) throw new Error('GITHUB_TOKEN environment variable is required');
    _octokit = new Octokit({ auth: token });
  }
  return _octokit;
}

/**
 * Fetch full issue details including comments.
 */
export async function getIssue(owner, repo, issueNumber) {
  const octokit = getOctokit();

  const { data: issue } = await octokit.issues.get({
    owner,
    repo,
    issue_number: issueNumber,
  });

  const { data: comments } = await octokit.issues.listComments({
    owner,
    repo,
    issue_number: issueNumber,
    per_page: 50,
  });

  return {
    number: issue.number,
    title: issue.title,
    body: issue.body || '',
    state: issue.state,
    author: issue.user?.login || 'unknown',
    labels: issue.labels.map(l => (typeof l === 'string' ? l : l.name)),
    comments: comments.map(c => ({
      author: c.user?.login || 'unknown',
      body: c.body || '',
    })),
    created_at: issue.created_at,
  };
}

/**
 * Post a markdown comment on an issue.
 */
export async function postComment(owner, repo, issueNumber, body) {
  const octokit = getOctokit();
  await octokit.issues.createComment({
    owner,
    repo,
    issue_number: issueNumber,
    body,
  });
}

/**
 * Create a label if it doesn't already exist.
 */
export async function ensureLabel(owner, repo, name, color, description) {
  const octokit = getOctokit();
  try {
    await octokit.issues.createLabel({
      owner,
      repo,
      name,
      color,
      description,
    });
  } catch (err) {
    // 422 = label already exists
    if (err.status !== 422) throw err;
  }
}

/**
 * Add labels to an issue.
 */
export async function addLabels(owner, repo, issueNumber, labels) {
  const octokit = getOctokit();
  await octokit.issues.addLabels({
    owner,
    repo,
    issue_number: issueNumber,
    labels,
  });
}

/**
 * Remove a single label from an issue (silently ignores if not present).
 */
export async function removeLabel(owner, repo, issueNumber, label) {
  const octokit = getOctokit();
  try {
    await octokit.issues.removeLabel({
      owner,
      repo,
      issue_number: issueNumber,
      name: label,
    });
  } catch (err) {
    // 404 = label not on this issue
    if (err.status !== 404) throw err;
  }
}

/**
 * Remove all labels in a category prefix, then add the new one.
 * E.g., category "priority/" removes priority/low, priority/high, etc.
 */
export async function manageCategoryLabels(owner, repo, issueNumber, categoryPrefix, newLabel, allCategoryLabels) {
  for (const label of allCategoryLabels) {
    if (label.name.startsWith(categoryPrefix) && label.name !== newLabel) {
      await removeLabel(owner, repo, issueNumber, label.name);
    }
  }
  await ensureLabel(owner, repo, newLabel,
    allCategoryLabels.find(l => l.name === newLabel)?.color || 'EDEDED',
    allCategoryLabels.find(l => l.name === newLabel)?.description || '');
  await addLabels(owner, repo, issueNumber, [newLabel]);
}

/**
 * Check if a triage assessment comment already exists on the issue.
 * If it does, also extract the previous quality score and priority for diff display.
 * Returns { isRetriage: boolean, previousScores: { qualityTotal, priority, verdict } | null }.
 */
export async function checkExistingTriage(owner, repo, issueNumber) {
  const octokit = getOctokit();
  const { data: comments } = await octokit.issues.listComments({
    owner,
    repo,
    issue_number: issueNumber,
    per_page: 100,
  });

  // Find the most recent triage comment (in case of multiple re-triages)
  let lastTriageComment = null;
  for (const c of comments) {
    if (c.body?.includes('## :robot: AI Triage Assessment')) {
      lastTriageComment = c;
    }
  }

  if (!lastTriageComment) {
    return { isRetriage: false, previousScores: null };
  }

  // Extract scores from the previous triage comment
  const previousScores = extractScoresFromComment(lastTriageComment.body);
  return { isRetriage: true, previousScores };
}

/**
 * Parse quality score and priority from a triage comment body.
 * Handles both compact format (| READY | 82/100 | 7/10 | Implement |)
 * and verbose fallback format (Issue Quality Score: 82/100 - READY).
 */
function extractScoresFromComment(body) {
  const scores = {};

  // Try compact format first: "| READY | 82/100 | 7/10 | Implement |"
  const compactMatch = body.match(/\|\s*(READY|NEEDS WORK|INSUFFICIENT)\s*\|\s*(\d+)\/100\s*\|\s*(\d+)\/10\s*\|/);
  if (compactMatch) {
    scores.verdict = compactMatch[1];
    scores.qualityTotal = parseInt(compactMatch[2], 10);
    scores.priority = parseInt(compactMatch[3], 10);
    return scores;
  }

  // Verbose format: "Issue Quality Score: 85/100 - READY"
  const qualityMatch = body.match(/Issue Quality Score:\s*(\d+)\/100\s*-\s*(READY|NEEDS WORK|INSUFFICIENT)/);
  if (qualityMatch) {
    scores.qualityTotal = parseInt(qualityMatch[1], 10);
    scores.verdict = qualityMatch[2];
  }

  // Match individual dimension scores from table rows: "| Clarity | 18/20 |"
  for (const dim of ['Clarity', 'Reproducibility', 'Context', 'Specificity', 'Actionability']) {
    const dimMatch = body.match(new RegExp(`\\|\\s*${dim}\\s*\\|\\s*(\\d+)/20`));
    if (dimMatch) {
      scores[dim.toLowerCase()] = parseInt(dimMatch[1], 10);
    }
  }

  // Match "Priority | 7/10"
  const priorityMatch = body.match(/Priority\s*\|\s*(\d+)\/10/);
  if (priorityMatch) {
    scores.priority = parseInt(priorityMatch[1], 10);
  }

  return Object.keys(scores).length > 0 ? scores : null;
}
