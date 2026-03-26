// Community forum search client
// Searches BC community forums for related discussions to provide
// additional context during issue triage.

import { tokenize, jaccardSimilarity } from './text-similarity.js';

const MAX_RESULTS = 5;
const FETCH_TIMEOUT_MS = 10_000;
const STAGGER_DELAY_MS = 1_200;  // Delay between Discourse queries to avoid 429s
const MAX_RETRIES = 2;

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
 * Searches both DynamicsUser.net (Discourse API) and community.dynamics.com
 * (HTML scraping of global search) in parallel.
 */
export async function fetchCommunityDiscussions(keywords, issueTitle = '') {
  if ((!keywords || keywords.length === 0) && !issueTitle) {
    return { discussions: [], dynamicsCommunityUrl: null };
  }

  const searchTerms = keywords.slice(0, 3).join(' ');
  console.log(`Community: searching forums for "${issueTitle || searchTerms}"...`);

  const [dugResults, mdcResults] = await Promise.all([
    searchDynamicsUserNet(keywords, issueTitle),
    searchDynamicsCommunity(keywords, issueTitle),
  ]);

  console.log(`Community: found ${dugResults.length} on DynamicsUser.net + ${mdcResults.length} on community.dynamics.com`);

  // Merge and deduplicate across both sources (by title similarity)
  const allDiscussions = [...dugResults];
  for (const mdc of mdcResults) {
    const isDuplicate = allDiscussions.some(d =>
      d.title.toLowerCase() === mdc.title.toLowerCase()
    );
    if (!isDuplicate) allDiscussions.push(mdc);
  }

  // Sort by similarity then views, take top results
  const merged = allDiscussions
    .sort((a, b) => b.similarity - a.similarity || b.views - a.views)
    .slice(0, MAX_RESULTS);

  return {
    discussions: merged,
    dynamicsCommunityUrl: buildDynamicsCommunityUrl(searchTerms),
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

  // Run queries sequentially with stagger delay to respect Discourse rate limits.
  // Parallel requests reliably trigger 429s on unauthenticated endpoints.
  const queryResults = [];
  for (let i = 0; i < queries.length; i++) {
    if (i > 0) await delay(STAGGER_DELAY_MS);
    try {
      queryResults.push(await runDiscourseSearch(queries[i]));
    } catch (err) {
      console.warn(`Community: DynamicsUser.net query "${queries[i]}" failed - ${err.message}`);
      queryResults.push([]);
    }
  }

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

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Run a single Discourse search query and return the topics array.
 * Retries on 429 (rate limit) with exponential backoff.
 */
async function runDiscourseSearch(query) {
  const url = `${DUG_BASE}/search.json?q=${encodeURIComponent(query)}%20category:${DUG_CATEGORY_ID}`;

  for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
    const response = await fetchWithTimeout(url, {
      headers: { 'Accept': 'application/json' },
    });

    if (response.status === 429) {
      const retryAfter = Number(response.headers.get('retry-after')) || (2 ** attempt * 2);
      const waitMs = Math.min(retryAfter * 1000, 10_000);
      console.log(`Community: rate-limited on "${query}", waiting ${waitMs}ms (attempt ${attempt + 1}/${MAX_RETRIES + 1})`);
      if (attempt < MAX_RETRIES) {
        await delay(waitMs);
        continue;
      }
      console.warn(`Community: DynamicsUser.net query "${query}" returned 429 after ${MAX_RETRIES + 1} attempts`);
      return [];
    }

    if (!response.ok) {
      console.warn(`Community: DynamicsUser.net query "${query}" returned ${response.status}`);
      return [];
    }

    const data = await response.json();
    return data.topics || [];
  }

  return [];
}

/**
 * Search community.dynamics.com via its global search endpoint.
 * The endpoint returns server-rendered HTML; we parse thread titles, IDs, and dates.
 */
async function searchDynamicsCommunity(keywords, issueTitle) {
  const queries = [];
  if (issueTitle) queries.push(issueTitle);
  const topKeywords = (keywords || []).slice(0, 2);
  for (const kw of topKeywords) queries.push(kw);
  if (queries.length === 0) return [];

  const issueTokens = tokenize(issueTitle);
  const allThreads = new Map();

  for (const query of queries) {
    try {
      const threads = await runDynamicsCommunitySearch(query);
      for (const thread of threads) {
        if (!allThreads.has(thread.id)) {
          const topicTokens = tokenize(thread.title);
          const similarity = jaccardSimilarity(issueTokens, topicTokens);
          allThreads.set(thread.id, {
            title: thread.title,
            url: `${MDC_BASE}/forums/thread/details/?threadid=${thread.id}`,
            source: 'community.dynamics.com',
            views: 0,   // not available from global search
            replies: 0,  // not available from global search
            created: thread.created || '',
            similarity: Math.round(similarity * 100),
          });
        }
      }
    } catch (err) {
      console.warn(`Community: community.dynamics.com query "${query}" failed - ${err.message}`);
    }
  }

  const MIN_SIMILARITY = 20;
  return [...allThreads.values()]
    .filter(t => t.similarity >= MIN_SIMILARITY);
}

/**
 * Run a single search against community.dynamics.com global search.
 * Parses thread IDs, titles, and dates from the HTML response.
 */
async function runDynamicsCommunitySearch(query) {
  const url = `${MDC_BASE}/globalsearch/?target=forum&q=${encodeURIComponent(query)}&id=${MDC_FORUM_ID}`;

  const response = await fetchWithTimeout(url, {
    headers: { 'Accept': 'text/html' },
  });

  if (!response.ok) {
    console.warn(`Community: community.dynamics.com returned ${response.status}`);
    return [];
  }

  const html = await response.text();

  // Parse thread links: href="/forums/thread/details/?threadid=GUID" class="dc-pane-item-link">Title</a>
  const threadPattern = /href="\/forums\/thread\/details\/\?threadid=([^"&]+)"[^>]*class="dc-pane-item-link">([^<]+)<\/a>/g;
  const threads = [];
  const seen = new Set();
  let match;

  while ((match = threadPattern.exec(html)) !== null) {
    const id = match[1];
    if (seen.has(id)) continue;
    seen.add(id);
    threads.push({ id, title: match[2].trim() });
  }

  // Try to extract dates (data-utc-date-time attributes near each thread)
  const datePattern = /data-utc-date-time="([^"]+)"/g;
  let dateIdx = 0;
  while ((match = datePattern.exec(html)) !== null && dateIdx < threads.length) {
    threads[dateIdx].created = match[1].split(' ')[0]; // "6/23/2015 12:15:15 PM" → "6/23/2015"
    dateIdx++;
  }

  return threads;
}

/**
 * Build a search URL for Microsoft Dynamics Community (for manual lookup).
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
    return '### Community Forums\n\nNo community search results available.\n';
  }

  const { discussions = [], dynamicsCommunityUrl } = result;

  if (discussions.length === 0 && !dynamicsCommunityUrl) {
    return '### Community Forums\n\nNo matching community discussions found.\n';
  }

  let output = '### Community Forums\n\n';
  output += `_User discussions: high-view threads indicate common pain points; replies suggest workaround availability._\n\n`;

  if (discussions.length > 0) {
    for (const d of discussions) {
      const signal = d.views > 0 ? `${d.views} views, ${d.replies} replies` : d.source;
      output += `- [**${d.title}**](${d.url}) — ${signal} · ${d.similarity}% relevance\n`;
    }
    output += '\n';
  }

  if (dynamicsCommunityUrl) {
    output += `[Search Microsoft Dynamics Community](${dynamicsCommunityUrl})\n\n`;
  }

  return output;
}
