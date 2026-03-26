// Microsoft Learn documentation search client
// Searches learn.microsoft.com for BC-related documentation to provide
// grounded documentation links instead of relying on LLM hallucination.

import { tokenize, jaccardSimilarity } from './text-similarity.js';

const LEARN_SEARCH_URL = 'https://learn.microsoft.com/api/search';
const BC_SCOPE = 'businesscentral';
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
 * Search Microsoft Learn for BC documentation matching the issue keywords.
 */
export async function fetchLearnDocs(keywords, issueTitle = '') {
  if ((!keywords || keywords.length === 0) && !issueTitle) {
    return { articles: [], searchQuery: '' };
  }

  const searchQuery = issueTitle || keywords.slice(0, 5).join(' ');
  console.log(`Learn: searching for "${searchQuery}"...`);

  try {
    const params = new URLSearchParams({
      search: searchQuery,
      locale: 'en-us',
      $filter: `scopes/any(t:t eq '${BC_SCOPE}')`,
      $top: String(MAX_RESULTS),
    });

    const response = await fetchWithTimeout(`${LEARN_SEARCH_URL}?${params}`, {
      headers: { 'Accept': 'application/json' },
    });

    if (!response.ok) {
      console.warn(`Learn: search returned ${response.status}`);
      return { articles: [], searchQuery, error: `HTTP ${response.status}` };
    }

    const data = await response.json();
    const results = data.results || [];

    const issueTokens = issueTitle ? tokenize(issueTitle) : [];

    const articles = results.map(r => {
      const title = r.title || '(untitled)';
      const url = r.url || '';
      const description = (r.description || r.descriptions?.[0] || '').replace(/<[^>]*>/g, '').trim();

      let similarity = 0;
      if (issueTokens.length > 0) {
        const docTokens = tokenize(title);
        similarity = Math.round(jaccardSimilarity(issueTokens, docTokens) * 100);
      }

      return { title, url, description, similarity };
    });

    // Sort by similarity to issue title (highest first)
    articles.sort((a, b) => b.similarity - a.similarity);

    console.log(`Learn: found ${articles.length} documentation articles`);
    return { articles, searchQuery };

  } catch (err) {
    console.warn(`Learn: search failed - ${err.message}`);
    return { articles: [], searchQuery, error: err.message };
  }
}

/**
 * Format Learn documentation results for inclusion in the LLM prompt.
 */
export function formatLearnContext(result) {
  if (!result || result.articles.length === 0) {
    if (result?.error) {
      return `### Microsoft Learn\n\nCould not search documentation: ${result.error}\n`;
    }
    return '### Microsoft Learn\n\nNo matching documentation found on learn.microsoft.com.\n';
  }

  let output = `### Microsoft Learn\n\n`;
  output += `_Existing docs: if official documentation covers this area, the issue may be about existing functionality or a gap in current behavior._\n\n`;

  for (const doc of result.articles) {
    output += `- [**${doc.title}**](${doc.url})`;
    if (doc.similarity > 0) output += ` — ${doc.similarity}% relevance`;
    output += `\n`;
    if (doc.description) {
      const snippet = doc.description.length > 250
        ? doc.description.substring(0, 250) + '...'
        : doc.description;
      output += `  > ${snippet}\n`;
    }
  }
  output += '\n';

  return output;
}
