// Community forum search client
// Searches BC community forums for related discussions to provide
// additional context during issue triage.

const MAX_RESULTS = 5;

// DynamicsUser.net (Discourse) — BC/NAV User Forum subcategory
const DUG_BASE = 'https://www.dynamicsuser.net';
const DUG_CATEGORY_ID = 13;

// Microsoft Dynamics Community — BC forum
const MDC_FORUM_ID = '5f8261f4-4d87-ef11-ac21-7c1e520a09df';
const MDC_BASE = 'https://community.dynamics.com';

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
 * Runs multiple queries (title, then keywords) and merges results
 * for better coverage.
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

  const allTopics = new Map(); // deduplicate by topic ID
  const issueTokens = tokenize(issueTitle);

  for (const query of queries) {
    try {
      const url = `${DUG_BASE}/search.json?q=${encodeURIComponent(query)}%20category:${DUG_CATEGORY_ID}`;
      const response = await fetch(url, {
        headers: { 'Accept': 'application/json' },
      });

      if (!response.ok) {
        console.warn(`Community: DynamicsUser.net query "${query}" returned ${response.status}`);
        continue;
      }

      const data = await response.json();
      for (const topic of (data.topics || [])) {
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
    } catch (err) {
      console.warn(`Community: DynamicsUser.net query "${query}" failed - ${err.message}`);
    }
  }

  return [...allTopics.values()]
    .sort((a, b) => b.similarity - a.similarity || b.views - a.views)
    .slice(0, MAX_RESULTS);
}

/**
 * Build a search URL for Microsoft Dynamics Community.
 * No public API is available, so we provide a direct link for manual lookup.
 */
async function buildDynamicsCommunityUrl(query) {
  return `${MDC_BASE}/forums/thread/?discussionforumid=${MDC_FORUM_ID}&q=${encodeURIComponent(query)}`;
}

function tokenize(text) {
  return new Set(
    (text || '').toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter(w => w.length > 2)
  );
}

function jaccardSimilarity(setA, setB) {
  if (setA.size === 0 || setB.size === 0) return 0;
  let intersection = 0;
  for (const token of setA) {
    if (setB.has(token)) intersection++;
  }
  const union = setA.size + setB.size - intersection;
  return union === 0 ? 0 : intersection / union;
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
