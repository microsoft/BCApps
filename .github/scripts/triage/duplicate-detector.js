// Duplicate issue detection via keyword overlap
// Compares the current issue against recent open issues to flag potential duplicates.

import { Octokit } from '@octokit/rest';

const MIN_SIMILARITY = 0.35; // Minimum Jaccard similarity to flag as potential duplicate
const MAX_DUPLICATES = 3;    // Maximum number of duplicates to report
const RECENT_ISSUES_COUNT = 50; // How many recent open issues to compare against

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
  'should', 'may', 'might', 'can', 'shall', 'to', 'of', 'in', 'for',
  'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during',
  'before', 'after', 'then', 'when', 'where', 'why', 'how', 'all', 'each',
  'every', 'both', 'few', 'more', 'most', 'other', 'some', 'such', 'no',
  'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'and', 'but',
  'or', 'if', 'it', 'this', 'that', 'these', 'those', 'i', 'we', 'you',
  'they', 'me', 'us', 'my', 'our', 'your', 'his', 'its', 'their', 'what',
  'which', 'who', 'about', 'up', 'out', 'just', 'also', 'new', 'like',
  'need', 'want', 'use', 'used', 'using', 'add', 'get', 'set', 'make',
  'work', 'way', 'still', 'please', 'would', 'issue', 'bug', 'feature',
  'request', 'error', 'problem',
]);

/**
 * Tokenize text into a set of meaningful words.
 */
function tokenize(text) {
  return new Set(
    (text || '')
      .toLowerCase()
      .replace(/[^a-z0-9\s-]/g, ' ')
      .split(/\s+/)
      .filter(w => w.length > 2 && !STOP_WORDS.has(w))
  );
}

/**
 * Compute Jaccard similarity between two token sets.
 */
function jaccardSimilarity(setA, setB) {
  if (setA.size === 0 && setB.size === 0) return 0;
  let intersection = 0;
  for (const token of setA) {
    if (setB.has(token)) intersection++;
  }
  const union = setA.size + setB.size - intersection;
  return union === 0 ? 0 : intersection / union;
}

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

    const currentTokens = tokenize(`${title} ${body}`);
    if (currentTokens.size === 0) return [];

    const candidates = [];

    for (const issue of issues) {
      // Skip the current issue itself and pull requests
      if (issue.number === currentIssueNumber || issue.pull_request) continue;

      const issueTokens = tokenize(`${issue.title} ${issue.body || ''}`);
      const similarity = jaccardSimilarity(currentTokens, issueTokens);

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

  let md = `### :warning: Potential duplicates detected\n\n`;
  md += `The following open issues have significant keyword overlap:\n\n`;
  for (const dup of duplicates) {
    md += `- [#${dup.number}: ${dup.title}](${dup.url}) (${dup.similarity}% similarity)\n`;
  }
  md += `\n> Please check if this issue duplicates one of the above before proceeding.\n\n`;
  return md;
}
