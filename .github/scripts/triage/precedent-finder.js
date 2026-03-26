// Precedent finder: searches recently closed issues to find historical context
// for the current issue being triaged. Helps PMs understand how similar problems
// were handled in the past.

import { Octokit } from '@octokit/rest';
import { weightedSimilarity } from './text-similarity.js';

const MIN_SIMILARITY = 0.25; // Lower than duplicate detection — these are historical references
const MAX_PRECEDENTS = 3;    // Maximum number of precedents to report
const RECENT_CLOSED_COUNT = 100; // How many recent closed issues to compare against

/**
 * Find similar resolved (closed) issues that may serve as precedents.
 * Returns an array of { number, title, similarity, url, state_reason }.
 */
export async function findPrecedents(owner, repo, currentIssueNumber, title, body) {
  const token = process.env.GITHUB_TOKEN;
  if (!token) return [];

  const octokit = new Octokit({ auth: token });

  try {
    const { data: issues } = await octokit.issues.listForRepo({
      owner,
      repo,
      state: 'closed',
      per_page: RECENT_CLOSED_COUNT,
      sort: 'updated',
      direction: 'desc',
    });

    const candidates = [];

    for (const issue of issues) {
      // Skip the current issue itself and pull requests
      if (issue.number === currentIssueNumber || issue.pull_request) continue;

      const similarity = weightedSimilarity(
        title, body || '',
        issue.title, issue.body || '',
      );

      if (similarity >= MIN_SIMILARITY) {
        candidates.push({
          number: issue.number,
          title: issue.title,
          similarity: Math.round(similarity * 100),
          url: issue.html_url,
          state_reason: issue.state_reason || 'completed',
        });
      }
    }

    // Sort by similarity descending and return top matches
    return candidates
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, MAX_PRECEDENTS);
  } catch (err) {
    console.warn(`Precedent search failed: ${err.message}`);
    return [];
  }
}

/**
 * Format precedent results as a markdown section for triage reports.
 */
export function formatPrecedentsSection(precedents) {
  if (!precedents || precedents.length === 0) return '';

  let md = `### Similar resolved issues\n\n`;
  md += `These closed issues may provide context on how similar problems were handled:\n\n`;
  for (const p of precedents) {
    md += `- [#${p.number}: ${p.title}](${p.url}) (${p.state_reason}, ${p.similarity}% similarity)\n`;
  }
  md += `\n`;
  return md;
}
