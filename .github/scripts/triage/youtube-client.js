// YouTube video search client
// Searches for Business Central videos related to the issue topic
// to surface tutorials, walkthroughs, and community discussions.

import { tokenize, jaccardSimilarity } from './text-similarity.js';

const YOUTUBE_API_URL = 'https://www.googleapis.com/youtube/v3/search';
const MAX_RESULTS = 5;
const FETCH_TIMEOUT_MS = 10_000;

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
 * Search YouTube for Business Central videos related to the issue.
 */
export async function fetchYouTubeVideos(keywords, issueTitle = '') {
  const apiKey = process.env.YOUTUBE_API_KEY;
  if (!apiKey) {
    console.log('YouTube: No YOUTUBE_API_KEY configured, skipping video search');
    return { videos: [], error: 'YOUTUBE_API_KEY not configured' };
  }

  if ((!keywords || keywords.length === 0) && !issueTitle) {
    return { videos: [] };
  }

  // Prepend "Business Central" to anchor search to BC context
  const searchTerms = keywords.slice(0, 4).join(' ');
  const query = `Business Central ${searchTerms}`;
  console.log(`YouTube: searching for "${query}"...`);

  try {
    const params = new URLSearchParams({
      part: 'snippet',
      q: query,
      type: 'video',
      maxResults: String(MAX_RESULTS * 2), // fetch extra for relevance filtering
      order: 'relevance',
      relevanceLanguage: 'en',
      key: apiKey,
    });

    const response = await fetchWithTimeout(`${YOUTUBE_API_URL}?${params}`, {
      headers: { 'Accept': 'application/json' },
    });

    if (response.status === 403) {
      const data = await response.json().catch(() => ({}));
      const reason = data.error?.errors?.[0]?.reason || 'forbidden';
      console.warn(`YouTube: API returned 403 (${reason}) — quota may be exceeded`);
      return { videos: [], searchQuery: query, error: `API quota exceeded (${reason})` };
    }

    if (!response.ok) {
      console.warn(`YouTube: search returned ${response.status}`);
      return { videos: [], searchQuery: query, error: `HTTP ${response.status}` };
    }

    const data = await response.json();
    const items = data.items || [];

    const issueTokens = issueTitle ? tokenize(issueTitle) : [];

    const videos = items.map(item => {
      const snippet = item.snippet || {};
      const title = snippet.title || '(untitled)';
      const description = (snippet.description || '').substring(0, 300);
      const channelTitle = snippet.channelTitle || 'Unknown';
      const publishedAt = snippet.publishedAt ? snippet.publishedAt.split('T')[0] : '';
      const videoId = item.id?.videoId || '';
      const url = videoId ? `https://www.youtube.com/watch?v=${videoId}` : '';

      let similarity = 0;
      if (issueTokens.length > 0) {
        const titleTokens = tokenize(title);
        similarity = Math.round(jaccardSimilarity(issueTokens, titleTokens) * 100);
      }

      return { title, url, description, channelTitle, publishedAt, similarity };
    });

    // Sort by similarity, filter out very low relevance
    videos.sort((a, b) => b.similarity - a.similarity);
    const filtered = videos.slice(0, MAX_RESULTS);

    console.log(`YouTube: found ${filtered.length} videos`);
    return { videos: filtered, searchQuery: query };

  } catch (err) {
    console.warn(`YouTube: search failed - ${err.message}`);
    return { videos: [], searchQuery: query, error: err.message };
  }
}

/**
 * Format YouTube results for inclusion in the LLM prompt.
 */
export function formatYouTubeContext(result) {
  if (!result) {
    return '### YouTube\n\nNo YouTube search results available.\n';
  }
  if (result.error === 'YOUTUBE_API_KEY not configured') {
    return '### YouTube\n\nYouTube video search is not configured (no YOUTUBE_API_KEY).\n';
  }
  if (result.error) {
    return `### YouTube\n\nCould not search YouTube: ${result.error}\n`;
  }

  const { videos = [] } = result;

  if (videos.length === 0) {
    return '### YouTube\n\nNo matching Business Central videos found.\n';
  }

  let output = `### YouTube videos\n\n`;
  output += `Related Business Central videos (${videos.length} results):\n\n`;

  for (const v of videos) {
    output += `- **${v.title}** by ${v.channelTitle}`;
    if (v.publishedAt) output += ` (${v.publishedAt})`;
    output += `\n  ${v.url}\n`;
    if (v.description) {
      const snippet = v.description.length > 200
        ? v.description.substring(0, 200) + '...'
        : v.description;
      output += `  > ${snippet}\n`;
    }
  }
  output += '\n';

  return output;
}
