// Azure DevOps work item search client
// Two-stage approach: broad retrieval via ADO Search API, then LLM semantic reranking.
// Stage 1: Fetch a large candidate pool using multiple search queries (keywords + title).
// Stage 2: LLM evaluates each candidate's relevance to the GitHub issue.
// Fallback: WIQL title+description Contains queries when the Search API is unavailable.

import { callGPT } from './models-client.js';

const ADO_ORG = 'dynamicssmb2';
const ADO_PROJECT = 'Dynamics SMB';
const ADO_API_VERSION = '7.1';
const SEARCH_API_TOP = 50;
const WIQL_TOP = 30;
const MAX_CANDIDATES_FOR_LLM = 40;
const MAX_ACTIVE = 5;
const MAX_CLOSED = 3;
const FETCH_TIMEOUT_MS = 15_000;

const CLOSED_STATES = new Set(['closed', 'resolved', 'removed', 'done', 'completed', 'cut']);

/**
 * Search for related work items in Azure DevOps using two-stage retrieve + LLM rerank.
 * @param {string[]} keywords - Phase 1 extracted search terms
 * @param {string} issueTitle - GitHub issue title
 * @param {string} [issueBody] - GitHub issue body (truncated) for LLM context
 */
export async function fetchRelatedWorkItems(keywords, issueTitle = '', issueBody = '') {
  const pat = process.env.ADO_PAT;
  if (!pat) {
    console.log('ADO: No ADO_PAT configured, skipping work item search');
    return { activeItems: [], closedItems: [], error: 'ADO_PAT not configured' };
  }

  if ((!keywords || keywords.length === 0) && !issueTitle) {
    return { activeItems: [], closedItems: [] };
  }

  const authHeader = `Basic ${Buffer.from(':' + pat).toString('base64')}`;

  try {
    // ── Stage 1: Broad retrieval ──
    const candidates = await retrieveCandidates(keywords, issueTitle, authHeader);

    if (candidates.length === 0) {
      console.log(`ADO: no matching work items found`);
      return { activeItems: [], closedItems: [] };
    }

    // ── Stage 2: LLM semantic reranking ──
    const ranked = await rerankWithLLM(candidates, issueTitle, issueBody);

    const activeItems = ranked
      .filter(wi => wi.isActive)
      .slice(0, MAX_ACTIVE);

    const closedItems = ranked
      .filter(wi => !wi.isActive)
      .slice(0, MAX_CLOSED);

    console.log(`ADO: ${candidates.length} candidates → LLM selected ${activeItems.length} active + ${closedItems.length} closed`);
    return { activeItems, closedItems };

  } catch (err) {
    console.warn(`ADO: search failed — ${err.message}`);
    return { activeItems: [], closedItems: [], error: err.message };
  }
}

// ── Stage 1: Broad retrieval ──────────────────────────────────────────────

/**
 * Run multiple search strategies in parallel and merge into a deduplicated candidate pool.
 */
async function retrieveCandidates(keywords, issueTitle, authHeader) {
  const queries = buildSearchQueries(keywords, issueTitle);

  const searchResults = await Promise.all(
    queries.map(q => searchApi(q.query, q.label, authHeader))
  );

  // Check if Search API responded (first non-null result)
  const apiAvailable = searchResults.some(r => r !== null);

  let allItems;
  if (apiAvailable) {
    allItems = searchResults.filter(r => r !== null).flat();
  } else {
    console.log('ADO: Search API unavailable, falling back to WIQL');
    allItems = await searchWithWiql(keywords, issueTitle, authHeader);
  }

  // Deduplicate by work item ID
  const seen = new Map();
  for (const item of allItems) {
    if (!seen.has(item.id)) {
      seen.set(item.id, item);
    }
  }

  return [...seen.values()].slice(0, MAX_CANDIDATES_FOR_LLM);
}

/**
 * Build multiple search queries for maximum recall.
 */
function buildSearchQueries(keywords, issueTitle) {
  const queries = [];

  // Query 1: Exact title phrase — highest precision
  if (issueTitle) {
    queries.push({ label: 'exact-title', query: `"${issueTitle}"` });
  }

  // Query 2: Title words with AND — all words must match
  if (issueTitle) {
    const words = issueTitle.replace(/[^\w\s]/g, ' ').split(/\s+/).filter(w => w.length > 2);
    if (words.length >= 2) {
      queries.push({ label: 'title-AND', query: words.join(' AND ') });
    }
  }

  // Query 3: Keywords with OR — broad semantic
  if (keywords.length > 0) {
    const kqlTerms = keywords.slice(0, 6).map(kw =>
      kw.includes(' ') ? `"${kw}"` : kw
    );
    queries.push({ label: 'keywords-OR', query: kqlTerms.join(' OR ') });
  }

  // Query 4: Title words as OR — broadest, catches partial overlaps
  if (issueTitle) {
    const words = issueTitle.replace(/[^\w\s]/g, ' ').split(/\s+/).filter(w => w.length > 2);
    if (words.length >= 2) {
      queries.push({ label: 'title-OR', query: words.join(' OR ') });
    }
  }

  return queries;
}

/**
 * ADO Work Item Search API call. Returns null if API is unavailable.
 */
async function searchApi(searchQuery, label, authHeader) {
  const searchUrl = `https://almsearch.dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_apis/search/workitemsearchresults?api-version=7.1-preview.1`;

  let response;
  try {
    response = await fetchWithTimeout(searchUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': authHeader },
      body: JSON.stringify({
        searchText: searchQuery,
        '$top': SEARCH_API_TOP,
        '$skip': 0,
        filters: { 'System.TeamProject': [ADO_PROJECT] },
        includeFacets: false,
      }),
    });
  } catch {
    return null;
  }

  if (!response.ok) {
    return null;
  }

  const data = await response.json();
  const results = data.results || [];

  return results.map(r => {
    const fields = r.fields || {};
    const id = parseInt(fields['system.id'], 10) || 0;
    return {
      id,
      title: fields['system.title'] || '(untitled)',
      state: fields['system.state'] || 'Unknown',
      type: fields['system.workitemtype'] || 'Unknown',
      description: stripHtml(fields['system.description'] || '').slice(0, 300),
      url: `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_workitems/edit/${id}`,
      isActive: !CLOSED_STATES.has((fields['system.state'] || '').toLowerCase()),
    };
  });
}

/**
 * WIQL-based fallback retrieval when Search API is unavailable.
 */
async function searchWithWiql(keywords, issueTitle, authHeader) {
  console.log('ADO: Search API unavailable, using WIQL fallback');
  const wiqlUrl = `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_apis/wit/wiql?api-version=${ADO_API_VERSION}&%24top=${WIQL_TOP}`;

  const titleWords = (issueTitle || '').replace(/[^\w\s]/g, ' ').split(/\s+/).filter(w => w.length > 2);
  const allTerms = [...new Set([...(keywords || []), ...titleWords])].slice(0, 8);

  if (allTerms.length === 0) return [];

  const conditions = allTerms.map(kw => {
    const safe = sanitizeWiqlValue(kw);
    return `[System.Title] Contains '${safe}' OR [System.Description] Contains '${safe}'`;
  }).join(' OR ');

  const wiql = `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${ADO_PROJECT}' AND (${conditions}) ORDER BY [System.ChangedDate] DESC`;

  const response = await fetchWithTimeout(wiqlUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': authHeader },
    body: JSON.stringify({ query: wiql }),
  });

  if (!response.ok) return [];

  const data = await response.json();
  const ids = (data.workItems || []).map(wi => wi.id).slice(0, WIQL_TOP);
  if (ids.length === 0) return [];
  const fields = ['System.Id', 'System.Title', 'System.State', 'System.WorkItemType', 'System.Description'].join(',');
  const detailsUrl = `https://dev.azure.com/${ADO_ORG}/_apis/wit/workitems?ids=${ids.join(',')}&fields=${fields}&api-version=${ADO_API_VERSION}`;

  const detailsResponse = await fetchWithTimeout(detailsUrl, {
    headers: { 'Authorization': authHeader },
  });

  if (!detailsResponse.ok) return [];
  const detailsData = await detailsResponse.json();

  return (detailsData.value || []).map(wi => ({
    id: wi.id,
    title: wi.fields?.['System.Title'] || '(untitled)',
    state: wi.fields?.['System.State'] || 'Unknown',
    type: wi.fields?.['System.WorkItemType'] || 'Unknown',
    description: stripHtml(wi.fields?.['System.Description'] || '').slice(0, 300),
    url: `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_workitems/edit/${wi.id}`,
    isActive: !CLOSED_STATES.has((wi.fields?.['System.State'] || '').toLowerCase()),
  }));
}

// ── Stage 2: LLM semantic reranking ──────────────────────────────────────

const RERANK_SYSTEM_PROMPT = `You are a relevance evaluator for Azure DevOps work items.

Given a GitHub issue and a list of candidate ADO work items, identify which work items are genuinely related to the issue. Consider:
- Direct matches: same feature request, same bug, same area
- Partial overlaps: related functionality, parent/child features, prerequisite work
- Historical context: similar past work that informs how to handle this issue

For each relevant work item, explain WHY it matters for triaging this issue in 1-2 sentences.
Be selective — only include items that a product manager would find useful during triage.

Respond with ONLY a JSON object:
{
  "relevant_items": [
    { "id": 12345, "relevance": "Tracks the exact same request — adding Work Description to purchase documents. This is the internal implementation slice." },
    { "id": 67890, "relevance": "Related parent feature for purchase document improvements. This issue would fall under this work stream." }
  ]
}

Rules:
- Include 0-8 most relevant items, sorted by relevance (most relevant first)
- Omit items that are only tangentially related
- The "relevance" explanation should tell the PM why this item matters for triage`;

/**
 * Use the LLM to semantically evaluate which candidates are relevant to the issue.
 */
async function rerankWithLLM(candidates, issueTitle, issueBody) {
  const candidateList = candidates.map(c =>
    `[${c.id}] ${c.type} | ${c.state} | ${c.title}${c.description ? ' | ' + c.description.slice(0, 150) : ''}`
  ).join('\n');

  const userMessage = `## GitHub Issue

**Title:** ${issueTitle}
${issueBody ? `**Body (excerpt):** ${issueBody.slice(0, 500)}` : ''}

## Candidate ADO Work Items (${candidates.length})

${candidateList}`;

  let result;
  try {
    result = await callGPT(RERANK_SYSTEM_PROMPT, userMessage);
  } catch (err) {
    console.warn(`ADO: LLM rerank failed — ${err.message}. Returning top candidates unranked.`);
    return candidates.slice(0, MAX_ACTIVE + MAX_CLOSED);
  }

  const relevantItems = result?.relevant_items || [];

  const candidateMap = new Map(candidates.map(c => [c.id, c]));
  const ranked = [];

  for (const item of relevantItems) {
    const candidate = candidateMap.get(item.id);
    if (candidate) {
      ranked.push({
        ...candidate,
        matchReason: item.relevance || '',
      });
    }
  }

  return ranked;
}

// ── Utilities ─────────────────────────────────────────────────────────────

function fetchWithTimeout(url, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  return fetch(url, { ...options, signal: controller.signal })
    .finally(() => clearTimeout(timeout));
}

function sanitizeWiqlValue(str) {
  return str
    .replace(/'/g, "''")
    .replace(/[[\](){}]/g, '')
    .replace(/\b(AND|OR|NOT)\b/gi, '')
    .trim();
}

function stripHtml(html) {
  return html
    .replace(/<[^>]*>/g, '')
    .replace(/&(?:#\d+|#x[\da-fA-F]+|[a-z]+);/gi, ' ')
    .trim();
}

/**
 * Format ADO work items for inclusion in the LLM prompt.
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

  let output = '### Azure DevOps\n\n';
  output += '_Internal tracking: active items may indicate planned or in-progress work; closed items show how similar requests were previously handled._\n\n';

  if (activeItems.length > 0) {
    output += `**Active work items** (${activeItems.length}):\n\n`;
    for (const wi of activeItems) {
      output += `- [**${wi.type} #${wi.id}: ${wi.title}**](${wi.url}) — ${wi.state} · ${wi.matchReason}\n`;
    }
    output += '\n';
  }

  if (closedItems.length > 0) {
    output += `**Previously addressed** (${closedItems.length}):\n\n`;
    for (const wi of closedItems) {
      output += `- [**${wi.type} #${wi.id}: ${wi.title}**](${wi.url}) — ${wi.state} · ${wi.matchReason}\n`;
    }
    output += '\n';
  }

  return output;
}
