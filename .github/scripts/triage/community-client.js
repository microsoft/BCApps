// Community forum search client
// Searches BC community forums for related discussions to provide
// additional context during issue triage.

const MAX_RESULTS = 5;

// DynamicsUser.net (Discourse) — Business Central/NAV category
const DUG_BASE = 'https://www.dynamicsuser.net';
const DUG_CATEGORY_ID = 13; // BC/NAV User Forum

// Microsoft Dynamics Community — BC forum
const MDC_FORUM_ID = '5f8261f4-4d87-ef11-ac21-7c1e520a09df';
const MDC_BASE = 'https://community.dynamics.com';

/**
 * Search community forums for discussions related to the issue keywords.
 * Returns results from DynamicsUser.net (Discourse API) and a search link
 * for community.dynamics.com (no public API available).
 */
export async function fetchCommunityDiscussions(keywords, issueTitle = '') {
  if (!keywords || keywords.length === 0) {
    return { discussions: [], dynamicsCommunityUrl: null };
  }

  // Use top 3 most specific keywords for search
  const searchTerms = keywords.slice(0, 3).join(' ');
  console.log(`Community: searching forums for "${searchTerms}"...`);

  const [dugResults, mdcUrl] = await Promise.all([
    searchDynamicsUserNet(searchTerms, issueTitle),
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
 */
async function searchDynamicsUserNet(query, issueTitle) {
  try {
    const url = `${DUG_BASE}/search.json?q=${encodeURIComponent(query)}%20category:${DUG_CATEGORY_ID}`;
    const response = await fetch(url, {
      headers: { 'Accept': 'application/json' },
    });

    if (!response.ok) {
      console.warn(`Community: DynamicsUser.net returned ${response.status}`);
      return [];
    }

    const data = await response.json();
    const topics = data.topics || [];

    if (topics.length === 0) return [];

    // Score by title similarity to the issue
    const issueTokens = tokenize(issueTitle);

    const scored = topics.map(topic => {
      const topicTokens = tokenize(topic.title);
      const similarity = jaccardSimilarity(issueTokens, topicTokens);

      return {
        title: topic.title,
        url: `${DUG_BASE}/t/${topic.slug}/${topic.id}`,
        source: 'DynamicsUser.net',
        views: topic.views || 0,
        replies: (topic.posts_count || 1) - 1,
        created: topic.created_at ? topic.created_at.split('T')[0] : '',
        similarity: Math.round(similarity * 100),
      };
    });

    return scored
      .sort((a, b) => b.similarity - a.similarity || b.views - a.views)
      .slice(0, MAX_RESULTS);
  } catch (err) {
    console.warn(`Community: DynamicsUser.net search failed - ${err.message}`);
    return [];
  }
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
