// Azure DevOps work item search client
// Searches for related work items in the Dynamics SMB ADO project.
// Primary: ADO Work Item Search API (full-text, relevance-ranked).
// Fallback: WIQL title+description Contains queries.
// Runs separate searches for active and closed items so the most
// actionable matches surface even if the project has many closed items.

import { tokenize, jaccardSimilarity } from './text-similarity.js';

const ADO_ORG = 'dynamicssmb2';
const ADO_PROJECT = 'Dynamics SMB';
const ADO_API_VERSION = '7.1';
const MAX_WIQL_RESULTS = 15;
const MAX_ACTIVE = 5;
const MAX_CLOSED = 3;
const MIN_RELEVANCE = 3;
const FETCH_TIMEOUT_MS = 15_000;

// States considered "active" in ADO (everything else is treated as closed)
const CLOSED_STATES = new Set(['closed', 'resolved', 'removed', 'done', 'completed', 'cut']);

/**
 * Search for related work items in Azure DevOps.
 * Primary: ADO Work Item Search API (full-text, relevance-ranked).
 * Fallback: WIQL title+description Contains queries.
 */
export async function fetchRelatedWorkItems(keywords, issueTitle = '') {
  const pat = process.env.ADO_PAT;
  if (!pat) {
    console.log('ADO: No ADO_PAT configured, skipping work item search');
    return { activeItems: [], closedItems: [], error: 'ADO_PAT not configured' };
  }

  if (!keywords || keywords.length === 0) {
    return { activeItems: [], closedItems: [] };
  }

  // Normalize keywords: split 3+ word phrases into overlapping bigrams
  // so "approval workflow management" → ["approval workflow", "workflow management"]
  const normalized = [];
  for (const kw of keywords) {
    const words = kw.split(/\s+/);
    if (words.length <= 2) {
      normalized.push(kw);
    } else {
      for (let i = 0; i < words.length - 1; i++) {
        normalized.push(words.slice(i, i + 2).join(' '));
      }
    }
  }
  const uniqueKeywords = [...new Set(normalized)];
  const phrases = uniqueKeywords.filter(kw => kw.includes(' ')).slice(0, 3);
  const singles = uniqueKeywords.filter(kw => !kw.includes(' ')).slice(0, 3);
  const topKeywords = [...phrases, ...singles].slice(0, 5);

  console.log(`ADO: searching work items for [${topKeywords.join(', ')}]...`);

  const authHeader = `Basic ${Buffer.from(':' + pat).toString('base64')}`;

  try {
    // Build a KQL query for keyword search:
    // - Multi-word phrases get exact-match quotes: "work description"
    // - Single words stay as-is
    // - All joined with OR for broad recall
    const keywordQuery = topKeywords.map(kw => kw.includes(' ') ? `"${kw}"` : kw).join(' OR ');
    let workItems = await searchWithFullTextApi(topKeywords, authHeader, issueTitle, keywordQuery, 'keyword');

    // Fall back to WIQL if Search API isn't available
    if (!workItems) {
      console.log('ADO: Search API unavailable, falling back to WIQL');
      workItems = await searchWithWiql(topKeywords, authHeader, issueTitle);
    }

    // Run a supplementary title-based search using exact phrase + individual words
    if (issueTitle) {
      const titleWords = issueTitle.replace(/[^\w\s]/g, ' ').split(/\s+/).filter(w => w.length > 2);
      const titleQuery = `"${issueTitle}" OR ${titleWords.join(' AND ')}`;
      const titleItems = await searchWithFullTextApi([], authHeader, issueTitle, titleQuery, 'title-match');
      if (titleItems && titleItems.length > 0) {
        const existingIds = new Set(workItems.map(wi => wi.id));
        const newItems = titleItems.filter(wi => !existingIds.has(wi.id));
        if (newItems.length > 0) {
          console.log(`ADO: title search found ${newItems.length} additional items`);
          workItems.push(...newItems);
        }
      }
    }

    // Split into active and closed, filter by relevance, sort by score
    const activeItems = workItems
      .filter(wi => wi.isActive && wi.relevanceScore >= MIN_RELEVANCE)
      .sort((a, b) => b.relevanceScore - a.relevanceScore)
      .slice(0, MAX_ACTIVE);

    const closedItems = workItems
      .filter(wi => !wi.isActive && wi.relevanceScore >= MIN_RELEVANCE)
      .sort((a, b) => b.relevanceScore - a.relevanceScore)
      .slice(0, MAX_CLOSED);

    console.log(`ADO: found ${activeItems.length} active + ${closedItems.length} closed work items (${workItems.length} total)`);
    return { activeItems, closedItems };

  } catch (err) {
    console.warn(`ADO: search failed - ${err.message}`);
    return { activeItems: [], closedItems: [], error: err.message };
  }
}

/**
 * ADO Work Item Search API — full-text, relevance-ranked search.
 * Supports KQL syntax: "exact phrase", AND, OR, NOT.
 * Returns null if the API is unavailable (e.g., PAT lacks permissions).
 * @param {string[]} scoringKeywords - keywords for relevance scoring (may be empty for title-match)
 * @param {string} authHeader - Basic auth header
 * @param {string} issueTitle - original issue title for similarity scoring
 * @param {string} searchQuery - KQL search query to send to the API
 * @param {string} searchLabel - label for logging (e.g., 'keyword' or 'title-match')
 */
async function searchWithFullTextApi(scoringKeywords, authHeader, issueTitle, searchQuery, searchLabel) {
  if (!searchQuery.trim()) return [];
  console.log(`ADO: [${searchLabel}] querying Search API: ${searchQuery}`);
  const searchUrl = `https://almsearch.dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_apis/search/workitemsearchresults?api-version=7.1-preview.1`;

  let response;
  try {
    response = await fetchWithTimeout(searchUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': authHeader },
      body: JSON.stringify({
        searchText: searchQuery,
        '$top': MAX_WIQL_RESULTS * 2,
        '$skip': 0,
        'filters': {
          'System.TeamProject': [ADO_PROJECT],
        },
        'includeFacets': false,
      }),
    });
  } catch {
    return null;
  }

  if (!response.ok) {
    console.log(`ADO: [${searchLabel}] Search API returned ${response.status}`);
    return null;
  }

  const data = await response.json();
  const results = data.results || [];
  console.log(`ADO: [${searchLabel}] Search API returned ${results.length} results`);

  if (results.length === 0) return [];

  return results.map(r => {
    const fields = r.fields || {};
    const title = fields['system.title'] || '(untitled)';
    const state = fields['system.state'] || 'Unknown';
    const type = fields['system.workitemtype'] || 'Unknown';
    const description = stripHtml(fields['system.description'] || '');
    const id = parseInt(fields['system.id'], 10) || 0;
    // When called via title search (scoringKeywords=[]), derive from issue title
    const effectiveKeywords = scoringKeywords.length > 0 ? scoringKeywords : deriveKeywordsFromTitle(issueTitle);
    const { score, matchedKeywords } = scoreRelevance(title, description, effectiveKeywords, issueTitle);

    return {
      id,
      title,
      state,
      type,
      url: `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_workitems/edit/${id}`,
      relevanceScore: score,
      matchedKeywords,
      matchReason: buildMatchReason(matchedKeywords),
      isActive: !CLOSED_STATES.has(state.toLowerCase()),
    };
  });
}

/**
 * WIQL-based search — fallback when ADO Search API is unavailable.
 * Searches both title and description for keyword matches.
 */
async function searchWithWiql(topKeywords, authHeader, issueTitle) {
  console.log(`ADO: [WIQL fallback] querying for [${topKeywords.join(', ')}]`);
  const wiqlUrl = `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_apis/wit/wiql?api-version=${ADO_API_VERSION}&%24top=${MAX_WIQL_RESULTS}`;

  // Build conditions that search both title AND description
  const conditions = topKeywords.map(kw => {
    const safe = sanitizeWiqlValue(kw);
    return `[System.Title] Contains '${safe}' OR [System.Description] Contains '${safe}'`;
  }).join(' OR ');

  // Run two queries in parallel: active items and all items
  const activeFilter = `[System.State] NOT IN ('Closed', 'Resolved', 'Removed', 'Done', 'Completed', 'Cut')`;
  const activeWiql = `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${ADO_PROJECT}' AND ${activeFilter} AND (${conditions}) ORDER BY [System.ChangedDate] DESC`;
  const allWiql = `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${ADO_PROJECT}' AND (${conditions}) ORDER BY [System.ChangedDate] DESC`;

  const [activeResult, allResult] = await Promise.all([
    runWiqlQuery(wiqlUrl, activeWiql, authHeader),
    runWiqlQuery(wiqlUrl, allWiql, authHeader),
  ]);

  // Combine IDs, deduplicate, fetch details
  const activeIds = new Set(activeResult.map(wi => wi.id));
  const allIds = allResult.map(wi => wi.id);
  const combinedIds = [...new Set([...activeIds, ...allIds])].slice(0, MAX_WIQL_RESULTS);

  if (combinedIds.length === 0) {
    console.log('ADO: [WIQL fallback] no matching work items found');
    return [];
  }

  const fields = ['System.Id', 'System.Title', 'System.State', 'System.WorkItemType', 'System.Description'].join(',');
  const detailsUrl = `https://dev.azure.com/${ADO_ORG}/_apis/wit/workitems?ids=${combinedIds.join(',')}&fields=${fields}&api-version=${ADO_API_VERSION}`;

  const detailsResponse = await fetchWithTimeout(detailsUrl, {
    headers: { 'Authorization': authHeader },
  });

  if (!detailsResponse.ok) {
    const text = await detailsResponse.text();
    throw new Error(`Work item fetch failed (${detailsResponse.status}): ${text.substring(0, 200)}`);
  }

  const detailsData = await detailsResponse.json();
  return (detailsData.value || []).map(wi => {
    const title = wi.fields?.['System.Title'] || '(untitled)';
    const state = wi.fields?.['System.State'] || 'Unknown';
    const description = stripHtml(wi.fields?.['System.Description'] || '');
    const { score, matchedKeywords } = scoreRelevance(title, description, topKeywords, issueTitle);

    return {
      id: wi.id,
      title,
      state,
      type: wi.fields?.['System.WorkItemType'] || 'Unknown',
      url: `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_workitems/edit/${wi.id}`,
      relevanceScore: score,
      matchedKeywords,
      matchReason: buildMatchReason(matchedKeywords),
      isActive: !CLOSED_STATES.has(state.toLowerCase()),
    };
  });
}

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
 * Execute a WIQL query with fallback on failure.
 */
async function runWiqlQuery(wiqlUrl, wiql, authHeader) {
  const response = await fetchWithTimeout(wiqlUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': authHeader },
    body: JSON.stringify({ query: wiql }),
  });

  if (!response.ok) {
    // Non-fatal: return empty on failure (the other query may succeed)
    console.log(`ADO: WIQL query returned ${response.status}`);
    return [];
  }

  const data = await response.json();
  return data.workItems || [];
}

/**
 * Remove bracketed tags like [BC Idea], [Bug], [Feature] from text.
 */
function stripBracketedTags(text) {
  return text.replace(/\[[^\]]*\]/g, ' ');
}

/**
 * Score a work item's relevance based on keyword matches plus title similarity.
 * Uses the shared tokenize/jaccardSimilarity from text-similarity.js for
 * consistent synonym-aware scoring across all connectors.
 */
function scoreRelevance(title, description, keywords, issueTitle = '') {
  const titleLower = stripBracketedTags(title).toLowerCase();
  const descLower = stripBracketedTags(description).toLowerCase();
  let score = 0;
  const matchedKeywords = [];

  for (const kw of keywords) {
    const kwLower = kw.toLowerCase();
    const isPhrase = kwLower.includes(' ');
    const inTitle = isPhrase
      ? titleLower.includes(kwLower)
      : new RegExp(`\\b${escapeRegex(kwLower)}`).test(titleLower);
    const inDesc = isPhrase
      ? descLower.includes(kwLower)
      : new RegExp(`\\b${escapeRegex(kwLower)}`).test(descLower);

    const titleWeight = isPhrase ? 5 : 3;
    const descWeight = isPhrase ? 2 : 1;

    if (inTitle) {
      score += titleWeight;
      matchedKeywords.push({ keyword: kw, location: 'title' });
    } else if (inDesc) {
      score += descWeight;
      matchedKeywords.push({ keyword: kw, location: 'description' });
    }
  }

  // Title similarity bonus using shared synonym-aware tokenizer.
  if (issueTitle) {
    const issueTokens = tokenize(issueTitle);
    const candidateTokens = tokenize(titleLower);
    const similarity = jaccardSimilarity(issueTokens, candidateTokens);
    const similarityBonus = Math.round(similarity * 25);
    if (similarityBonus > 0) {
      score += similarityBonus;
      matchedKeywords.push({ keyword: `${Math.round(similarity * 100)}% title overlap`, location: 'similarity' });
    }
  }

  return { score, matchedKeywords };
}

/**
 * Derive scoring keywords from the issue title when Phase 1 keywords aren't available.
 * Extracts individual words and overlapping bigrams (same pattern as the main normalizer).
 */
function deriveKeywordsFromTitle(title) {
  if (!title) return [];
  const STOP_WORDS = new Set(['a', 'an', 'the', 'in', 'on', 'at', 'to', 'for', 'of', 'and', 'or', 'is', 'are', 'be', 'it', 'as', 'by', 'with', 'from', 'not', 'no', 'also']);
  const words = title.toLowerCase().replace(/[^\w\s]/g, ' ').split(/\s+/).filter(w => w.length > 1 && !STOP_WORDS.has(w));
  const keywords = [];
  // Add bigrams first (more specific)
  for (let i = 0; i < words.length - 1; i++) {
    keywords.push(words.slice(i, i + 2).join(' '));
  }
  // Then individual words
  keywords.push(...words);
  return [...new Set(keywords)].slice(0, 8);
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function buildMatchReason(matchedKeywords) {
  if (matchedKeywords.length === 0) return 'Weak keyword overlap — may not be directly related';

  const similarityMatch = matchedKeywords.find(m => m.location === 'similarity');
  const titleMatches = matchedKeywords.filter(m => m.location === 'title').map(m => m.keyword);
  const descMatches = matchedKeywords.filter(m => m.location === 'description').map(m => m.keyword);

  const parts = [];
  if (similarityMatch) {
    const pct = parseInt(similarityMatch.keyword, 10);
    if (pct >= 60) parts.push(`Strong title similarity (${similarityMatch.keyword}) — likely tracks the same topic`);
    else if (pct >= 35) parts.push(`Moderate title similarity (${similarityMatch.keyword}) — possibly related`);
    else parts.push(`Partial title overlap (${similarityMatch.keyword})`);
  }
  if (titleMatches.length > 0) {
    parts.push(`Title contains: ${titleMatches.join(', ')}`);
  }
  if (descMatches.length > 0) {
    parts.push(`Description mentions: ${descMatches.join(', ')}`);
  }
  return parts.join('; ');
}

/**
 * Sanitize a value for safe inclusion in a WIQL Contains clause.
 * - Escapes single quotes (WIQL string delimiter)
 * - Strips characters that could break the query structure
 */
function sanitizeWiqlValue(str) {
  return str
    .replace(/'/g, "''")          // escape single quotes
    .replace(/[[\](){}]/g, '')    // strip brackets/parens that could break syntax
    .replace(/\b(AND|OR|NOT)\b/gi, '') // strip WIQL boolean operators
    .trim();
}

function stripHtml(html) {
  return html
    .replace(/<[^>]*>/g, '')
    .replace(/&(?:#\d+|#x[\da-fA-F]+|[a-z]+);/gi, ' ')  // handle named + numeric HTML entities
    .trim();
}

/**
 * Format ADO work items for inclusion in the LLM prompt.
 * Shows active items first, then closed items in a separate section.
 */
export function formatAdoContext(result) {
  if (!result) {
    return '### Azure DevOps\n\nNo matching work items found in Dynamics SMB project.\n';
  }
  if (result.error === 'ADO_PAT not configured') {
    return '### Azure DevOps\n\nADO work item search is not configured (no ADO_PAT).\n';
  }
  if (result.error) {
    return `### Azure DevOps\n\nCould not search work items: ${result.error}\n`;
  }

  const { activeItems = [], closedItems = [] } = result;

  if (activeItems.length === 0 && closedItems.length === 0) {
    return '### Azure DevOps\n\nNo matching work items found in Dynamics SMB project.\n';
  }

  let output = `### Azure DevOps\n\n`;
  output += `_Internal tracking: active items may indicate planned or in-progress work; closed items show how similar requests were previously handled._\n\n`;

  if (activeItems.length > 0) {
    output += `**Active work items** (${activeItems.length}):\n\n`;
    for (const wi of activeItems) {
      output += `- [**${wi.type} #${wi.id}: ${wi.title}**](${wi.url}) — ${wi.state} · ${wi.matchReason}\n`;
    }
    output += `\n`;
  }

  if (closedItems.length > 0) {
    output += `**Previously addressed** (${closedItems.length}):\n\n`;
    for (const wi of closedItems) {
      output += `- [**${wi.type} #${wi.id}: ${wi.title}**](${wi.url}) — ${wi.state} · ${wi.matchReason}\n`;
    }
    output += `\n`;
  }

  return output;
}
