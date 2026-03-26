// Community forum search client
// Searches BC community forums for related discussions to provide
// additional context during issue triage.

import { tokenize, jaccardSimilarity } from './text-similarity.js';

const MAX_RESULTS = 5;
const FETCH_TIMEOUT_MS = 10_000;

// DynamicsUser.net (Discourse) — BC/NAV User Forum subcategory
const DUG_BASE = 'https://www.dynamicsuser.net';
const DUG_CATEGORY_ID = 13;

// Microsoft Dynamics Community — BC forum
const MDC_FORUM_ID = '5f8261f4-4d87-ef11-ac21-7c1e520a09df';
const MDC_BASE = 'https://community.dynamics.com';

/**
 * Fetch with an AbortController timeout.
 */
function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  return fetch(url, { ...options, signal: controller.signal })
    .finally(() => clearTimeout(timeout));
}

/**
 * Search community forums for discussions related to the issue.
 * Uses the issue title as the primary search (most natural match),
 * then supplements with keyword-based searches.
 */
export async function fetchCommunityDiscussions(keywords, issueTitle = '') {
  if ((!keywords || keywords.length === 0) && !issueTitle) {
    return { discussions: [], dynamicsCommunityUrl: null };
  }

  const searchTerms = keywords.slice(0, 3).join(' ');
  console.log(`Community: searching forums for "${issueTitle || searchTerms}"...`);

  const [dugResults, mdcUrl] = await Promise.all([
    searchDynamicsUserNet(keywords, issueTitle),
    buildDynamicsCommunityUrl(searchTerms),
  ]);

  console.log(`Community: found ${dugResults.length} discussions on DynamicsUser.net`);

  return {
    discussions: dugResults,
    dynamicsCommunityUrl: mdcUrl,
  };
}

/**
 * Search DynamicsUser.net via the Discourse search API.
 * Runs multiple queries (title, then keywords) in parallel and merges
 * results for better coverage.
 */
async function searchDynamicsUserNet(keywords, issueTitle) {
  const queries = [];

  // Primary: search by issue title (best for finding exact-match discussions)
  if (issueTitle) {
    queries.push(issueTitle);
  }

  // Secondary: search by top keywords individually for broader coverage
  const topKeywords = (keywords || []).slice(0, 3);
  for (const kw of topKeywords) {
    queries.push(kw);
  }

  if (queries.length === 0) return [];

  const issueTokens = tokenize(issueTitle);

  // Run all queries in parallel instead of sequentially
  const queryResults = await Promise.all(
    queries.map(query => runDiscourseSearch(query).catch(err => {
      console.warn(`Community: DynamicsUser.net query "${query}" failed - ${err.message}`);
      return [];
    }))
  );

  // Merge and deduplicate results across all queries
  const allTopics = new Map();
  for (const topics of queryResults) {
    for (const topic of topics) {
      if (!allTopics.has(topic.id)) {
        const topicTokens = tokenize(topic.title);
        const similarity = jaccardSimilarity(issueTokens, topicTokens);

        allTopics.set(topic.id, {
          title: topic.title,
          url: `${DUG_BASE}/t/${topic.slug}/${topic.id}`,
          source: 'DynamicsUser.net',
          views: topic.views || 0,
          replies: (topic.posts_count || 1) - 1,
          created: topic.created_at ? topic.created_at.split('T')[0] : '',
          similarity: Math.round(similarity * 100),
        });
      }
    }
  }

  const MIN_SIMILARITY = 25; // At least 25% word overlap with issue title
  const MIN_VIEWS = 1;       // Skip zero-view dead topics

  const filtered = [...allTopics.values()]
    .filter(t => t.similarity >= MIN_SIMILARITY && t.views >= MIN_VIEWS);

  if (filtered.length === 0) {
    console.log('Community: no discussions met relevance threshold');
  }

  return filtered
    .sort((a, b) => b.similarity - a.similarity || b.views - a.views)
    .slice(0, MAX_RESULTS);
}

/**
 * Run a single Discourse search query and return the topics array.
 */
async function runDiscourseSearch(query) {
  const url = `${DUG_BASE}/search.json?q=${encodeURIComponent(query)}%20category:${DUG_CATEGORY_ID}`;
  const response = await fetchWithTimeout(url, {
    headers: { 'Accept': 'application/json' },
  });

  if (!response.ok) {
    console.warn(`Community: DynamicsUser.net query "${query}" returned ${response.status}`);
    return [];
  }

  const data = await response.json();
  return data.topics || [];
}

/**
 * Build a search URL for Microsoft Dynamics Community.
 * No public API is available, so we provide a direct link for manual lookup.
 */
function buildDynamicsCommunityUrl(query) {
  if (!query) return null;
  return `${MDC_BASE}/forums/thread/?discussionforumid=${MDC_FORUM_ID}&q=${encodeURIComponent(query)}`;
}

/**
 * Format community results for inclusion in the LLM prompt.
 */
export function formatCommunityContext(result) {
  if (!result) {
    return '### Community forums\n\nNo community search results available.\n';
  }

  const { discussions = [], dynamicsCommunityUrl } = result;

  if (discussions.length === 0 && !dynamicsCommunityUrl) {
    return '### Community forums\n\nNo matching community discussions found.\n';
  }

  let output = '### Community forum discussions\n\n';

  if (discussions.length > 0) {
    output += `**DynamicsUser.net** (${discussions.length} results):\n\n`;
    for (const d of discussions) {
      output += `- **${d.title}** — ${d.views} views, ${d.replies} replies`;
      if (d.similarity > 0) output += ` (${d.similarity}% title overlap)`;
      output += `\n  ${d.url}\n`;
    }
    output += '\n';
  }

  if (dynamicsCommunityUrl) {
    output += `**Microsoft Dynamics Community** (no API — manual search):\n`;
    output += `  [Search BC forum for these keywords](${dynamicsCommunityUrl})\n\n`;
  }

  return output;
}
