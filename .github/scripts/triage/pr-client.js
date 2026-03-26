// GitHub pull request search client
// Searches for related PRs in the same repository to identify
// in-progress or recently merged work relevant to the issue.

import { Octokit } from '@octokit/rest';
import { tokenize, jaccardSimilarity } from './text-similarity.js';

const MAX_RESULTS = 10;
const MAX_OPEN = 5;
const MAX_MERGED = 5;
const MIN_RELEVANCE = 3;

let _octokit;

function getOctokit() {
  if (!_octokit) {
    const token = process.env.GITHUB_TOKEN;
    if (!token) return null;
    _octokit = new Octokit({ auth: token });
  }
  return _octokit;
}

/**
 * Search for related pull requests in the repository.
 */
export async function fetchRelatedPRs(keywords, issueTitle = '') {
  const octokit = getOctokit();
  if (!octokit) {
    console.log('PR search: No GITHUB_TOKEN, skipping PR search');
    return { openPRs: [], mergedPRs: [], error: 'GITHUB_TOKEN not configured' };
  }

  const owner = process.env.REPO_OWNER;
  const repo = process.env.REPO_NAME;
  if (!owner || !repo) {
    console.log('PR search: No REPO_OWNER/REPO_NAME, skipping PR search');
    return { openPRs: [], mergedPRs: [], error: 'REPO_OWNER/REPO_NAME not configured' };
  }

  if (!keywords || keywords.length === 0) {
    return { openPRs: [], mergedPRs: [] };
  }

  const searchTerms = keywords.slice(0, 4).join(' ');
  console.log(`PR search: searching for "${searchTerms}" in ${owner}/${repo}...`);

  try {
    // Search PRs via the issues/PR search API
    const query = `${searchTerms} repo:${owner}/${repo} is:pr`;
    const { data } = await octokit.request('GET /search/issues', {
      q: query,
      sort: 'updated',
      order: 'desc',
      per_page: MAX_RESULTS * 2,  // fetch extra to compensate for filtering
    });

    if (!data.items || data.items.length === 0) {
      console.log('PR search: no matching pull requests found');
      return { openPRs: [], mergedPRs: [] };
    }

    const issueTokens = issueTitle ? tokenize(issueTitle) : [];

    const prs = data.items.map(item => {
      const title = item.title || '(untitled)';
      const { score, matchedKeywords } = scoreRelevance(title, item.body || '', keywords, issueTokens);
      const isMerged = !!item.pull_request?.merged_at;
      const isOpen = item.state === 'open';

      return {
        number: item.number,
        title,
        state: isMerged ? 'merged' : item.state,
        author: item.user?.login || 'unknown',
        url: item.html_url,
        updatedAt: item.updated_at ? item.updated_at.split('T')[0] : '',
        relevanceScore: score,
        matchedKeywords,
        matchReason: buildMatchReason(matchedKeywords),
        isOpen,
        isMerged,
      };
    });

    const openPRs = prs
      .filter(pr => pr.isOpen && pr.relevanceScore >= MIN_RELEVANCE)
      .sort((a, b) => b.relevanceScore - a.relevanceScore)
      .slice(0, MAX_OPEN);

    const mergedPRs = prs
      .filter(pr => pr.isMerged && pr.relevanceScore >= MIN_RELEVANCE)
      .sort((a, b) => b.relevanceScore - a.relevanceScore)
      .slice(0, MAX_MERGED);

    console.log(`PR search: found ${openPRs.length} open + ${mergedPRs.length} merged PRs (${prs.length} total)`);
    return { openPRs, mergedPRs };

  } catch (err) {
    console.warn(`PR search: failed - ${err.message}`);
    return { openPRs: [], mergedPRs: [], error: err.message };
  }
}

/**
 * Score a PR's relevance based on keyword matches and title similarity.
 */
function scoreRelevance(title, body, keywords, issueTokens) {
  const titleLower = title.toLowerCase();
  const bodyLower = (body || '').toLowerCase();
  let score = 0;
  const matchedKeywords = [];

  for (const kw of keywords) {
    const kwLower = kw.toLowerCase();
    const isPhrase = kwLower.includes(' ');

    const inTitle = isPhrase
      ? titleLower.includes(kwLower)
      : new RegExp(`\\b${escapeRegex(kwLower)}`).test(titleLower);
    const inBody = isPhrase
      ? bodyLower.includes(kwLower)
      : new RegExp(`\\b${escapeRegex(kwLower)}`).test(bodyLower);

    const titleWeight = isPhrase ? 5 : 3;
    const bodyWeight = isPhrase ? 2 : 1;

    if (inTitle) {
      score += titleWeight;
      matchedKeywords.push({ keyword: kw, location: 'title' });
    } else if (inBody) {
      score += bodyWeight;
      matchedKeywords.push({ keyword: kw, location: 'body' });
    }
  }

  // Title similarity bonus
  if (issueTokens.length > 0) {
    const prTokens = tokenize(titleLower);
    const similarity = jaccardSimilarity(issueTokens, prTokens);
    const bonus = Math.round(similarity * 25);
    if (bonus > 0) {
      score += bonus;
      matchedKeywords.push({ keyword: `${Math.round(similarity * 100)}% title overlap`, location: 'similarity' });
    }
  }

  return { score, matchedKeywords };
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function buildMatchReason(matchedKeywords) {
  if (matchedKeywords.length === 0) return 'Weak match';

  const parts = [];
  const similarityMatch = matchedKeywords.find(m => m.location === 'similarity');
  const titleMatches = matchedKeywords.filter(m => m.location === 'title').map(m => m.keyword);
  const bodyMatches = matchedKeywords.filter(m => m.location === 'body').map(m => m.keyword);

  if (similarityMatch) parts.push(similarityMatch.keyword);
  if (titleMatches.length > 0) parts.push(`title: ${titleMatches.join(', ')}`);
  if (bodyMatches.length > 0) parts.push(`body: ${bodyMatches.join(', ')}`);

  return parts.join('; ');
}

/**
 * Format PR search results for inclusion in the LLM prompt.
 */
export function formatPRContext(result) {
  if (!result) {
    return '### Related pull requests\n\nNo PR search results available.\n';
  }
  if (result.error === 'GITHUB_TOKEN not configured' || result.error === 'REPO_OWNER/REPO_NAME not configured') {
    return '### Related pull requests\n\nPR search is not configured.\n';
  }
  if (result.error) {
    return `### Related pull requests\n\nCould not search PRs: ${result.error}\n`;
  }

  const { openPRs = [], mergedPRs = [] } = result;

  if (openPRs.length === 0 && mergedPRs.length === 0) {
    return '### Related pull requests\n\nNo matching pull requests found.\n';
  }

  let output = '### Related pull requests\n\n';

  if (openPRs.length > 0) {
    output += `**Open PRs** (${openPRs.length}) — work potentially in progress:\n\n`;
    for (const pr of openPRs) {
      output += `- **#${pr.number}: ${pr.title}** by @${pr.author} (updated ${pr.updatedAt}) — _${pr.matchReason}_\n`;
    }
    output += '\n';
  }

  if (mergedPRs.length > 0) {
    output += `**Recently merged** (${mergedPRs.length}):\n\n`;
    for (const pr of mergedPRs) {
      output += `- **#${pr.number}: ${pr.title}** by @${pr.author} (updated ${pr.updatedAt}) — _${pr.matchReason}_\n`;
    }
    output += '\n';
  }

  return output;
}
