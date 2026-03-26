// Duplicate issue detection via BC-domain-aware text similarity.
// Uses synonym normalization, bigram matching, and title-weighted scoring
// to catch semantic duplicates that simple keyword overlap would miss.

import { Octokit } from '@octokit/rest';
import { weightedSimilarity } from './text-similarity.js';

const MIN_SIMILARITY = 0.30; // Lowered from 0.35 — synonym normalization makes matches tighter
const MAX_DUPLICATES = 3;    // Maximum number of duplicates to report
const RECENT_ISSUES_COUNT = 100; // Doubled from 50 to catch older duplicates

/**
 * Find potential duplicate issues by comparing against recent open issues.
 * Returns an array of { number, title, similarity, url }.
 */
export async function findDuplicates(owner, repo, currentIssueNumber, title, body) {
  const token = process.env.GITHUB_TOKEN;
  if (!token) return [];

  const octokit = new Octokit({ auth: token });

  try {
    const { data: issues } = await octokit.issues.listForRepo({
      owner,
      repo,
      state: 'open',
      per_page: RECENT_ISSUES_COUNT,
      sort: 'created',
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
        });
      }
    }

    // Sort by similarity descending and return top matches
    return candidates
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, MAX_DUPLICATES);
  } catch (err) {
    console.warn(`Duplicate detection failed: ${err.message}`);
    return [];
  }
}

/**
 * Format duplicate detection results for the triage comment.
 */
export function formatDuplicatesSection(duplicates) {
  if (!duplicates || duplicates.length === 0) return '';

  let md = `### :warning: Potential Duplicates\n\n`;
  md += `_These open issues have significant overlap -- check before proceeding to avoid duplicate work._\n\n`;
  for (const dup of duplicates) {
    md += `- [**#${dup.number}: ${dup.title}**](${dup.url}) — ${dup.similarity}% similarity\n`;
  }
  md += `\n`;
  return md;
}
