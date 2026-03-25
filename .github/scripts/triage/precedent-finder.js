// Precedent finder: searches recently closed issues to find historical context
// for the current issue being triaged. Helps PMs understand how similar problems
// were handled in the past.

import { Octokit } from '@octokit/rest';

const MIN_SIMILARITY = 0.30; // Lower than duplicate detection — these are historical references
const MAX_PRECEDENTS = 3;    // Maximum number of precedents to report
const RECENT_CLOSED_COUNT = 100; // How many recent closed issues to compare against

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
