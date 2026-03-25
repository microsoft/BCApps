// Azure DevOps work item search client
// Searches for related work items in the Dynamics SMB ADO project
// using the WIQL (Work Item Query Language) REST API.
// Runs two queries: active items first, then closed — so the most
// actionable matches surface even if the project has many closed items.

const ADO_ORG = 'dynamicssmb2';
const ADO_PROJECT = 'Dynamics SMB';
const ADO_API_VERSION = '7.1';
const MAX_WIQL_RESULTS = 15;
const MAX_ACTIVE = 5;
const MAX_CLOSED = 3;
const MIN_RELEVANCE = 3;

// States considered "active" in ADO (everything else is treated as closed)
const CLOSED_STATES = new Set(['closed', 'resolved', 'removed', 'done', 'completed', 'cut']);

/**
 * Search for related work items in Azure DevOps using keyword-based WIQL queries.
 * Runs separate queries for active and closed items so active results aren't
 * crowded out by a large volume of closed work items.
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

  // Normalize keywords: split any 3+ word phrases into 1-2 word terms
  const normalized = [];
  for (const kw of keywords) {
    const words = kw.split(/\s+/);
    if (words.length <= 2) {
      normalized.push(kw);
    } else {
      for (let i = 0; i < words.length - 1; i += 2) {
        normalized.push(words.slice(i, i + 2).join(' '));
      }
    }
  }
  const uniqueKeywords = [...new Set(normalized)];
  const phrases = uniqueKeywords.filter(kw => kw.includes(' ')).slice(0, 3);
  const singles = uniqueKeywords.filter(kw => !kw.includes(' ')).slice(0, 3);
  const topKeywords = [...phrases, ...singles].slice(0, 5);

  console.log(`ADO: searching work items for [${topKeywords.join(', ')}]...`);

  const authHeader = `Basic ${btoa(':' + pat)}`;
  const wiqlUrl = `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_apis/wit/wiql?api-version=${ADO_API_VERSION}&$top=${MAX_WIQL_RESULTS}`;

  const titleConditions = topKeywords.map(kw =>
    `[System.Title] Contains '${escapeWiql(kw)}'`
  ).join(' OR ');

  // Run two queries in parallel: active items and all items
  const activeFilter = `[System.State] NOT IN ('Closed', 'Resolved', 'Removed', 'Done', 'Completed', 'Cut')`;
  const activeWiql = `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${ADO_PROJECT}' AND ${activeFilter} AND (${titleConditions}) ORDER BY [System.ChangedDate] DESC`;
  const allWiql = `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${ADO_PROJECT}' AND (${titleConditions}) ORDER BY [System.ChangedDate] DESC`;

  try {
    const [activeResult, allResult] = await Promise.all([
      runWiqlQuery(wiqlUrl, activeWiql, authHeader),
      runWiqlQuery(wiqlUrl, allWiql, authHeader),
    ]);

    // Combine IDs, deduplicate, fetch details
    const activeIds = new Set(activeResult.map(wi => wi.id));
    const allIds = allResult.map(wi => wi.id);
    const combinedIds = [...new Set([...activeIds, ...allIds])].slice(0, MAX_WIQL_RESULTS);

    if (combinedIds.length === 0) {
      console.log('ADO: no matching work items found');
      return { activeItems: [], closedItems: [] };
    }

    const fields = ['System.Id', 'System.Title', 'System.State', 'System.WorkItemType', 'System.Description'].join(',');
    const detailsUrl = `https://dev.azure.com/${ADO_ORG}/_apis/wit/workitems?ids=${combinedIds.join(',')}&fields=${fields}&api-version=${ADO_API_VERSION}`;

    const detailsResponse = await fetch(detailsUrl, {
      headers: { 'Authorization': authHeader },
    });

    if (!detailsResponse.ok) {
      const text = await detailsResponse.text();
      throw new Error(`Work item fetch failed (${detailsResponse.status}): ${text.substring(0, 200)}`);
    }

    const detailsData = await detailsResponse.json();
    const workItems = (detailsData.value || []).map(wi => {
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
 * Execute a WIQL query with fallback on failure.
 */
async function runWiqlQuery(wiqlUrl, wiql, authHeader) {
  const response = await fetch(wiqlUrl, {
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
 * Tokenize text into a set of meaningful words for similarity comparison.
 */
function tokenize(text) {
  return new Set(
    (text || '').toLowerCase()
      .replace(/[^a-z0-9\s]/g, ' ')
      .split(/\s+/)
      .filter(w => w.length > 2)
  );
}

/**
 * Compute Jaccard similarity between two token sets (0-1).
 */
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
 * Score a work item's relevance based on keyword matches plus title similarity.
 * Title similarity adds a large bonus when the candidate title closely matches
 * the issue title — this ensures near-identical items always rank highest.
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

  // Title similarity bonus: Jaccard similarity between issue title and candidate title.
  // A 50% word overlap adds +10, a 80%+ overlap adds +20. This ensures items with
  // nearly identical titles always outrank items that merely share a few keywords.
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

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function buildMatchReason(matchedKeywords) {
  if (matchedKeywords.length === 0) return 'Weak match';

  const similarityMatch = matchedKeywords.find(m => m.location === 'similarity');
  const titleMatches = matchedKeywords.filter(m => m.location === 'title').map(m => m.keyword);
  const descMatches = matchedKeywords.filter(m => m.location === 'description').map(m => m.keyword);

  const parts = [];
  if (similarityMatch) {
    parts.push(similarityMatch.keyword);
  }
  if (titleMatches.length > 0) {
    parts.push(`title keywords: ${titleMatches.join(', ')}`);
  }
  if (descMatches.length > 0) {
    parts.push(`description keywords: ${descMatches.join(', ')}`);
  }
  return parts.join('; ');
}

function escapeWiql(str) {
  return str.replace(/'/g, "''");
}

function stripHtml(html) {
  return html.replace(/<[^>]*>/g, '').replace(/&[a-z]+;/gi, ' ').trim();
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

  let output = `### Azure DevOps related work items\n\n`;

  if (activeItems.length > 0) {
    output += `**Active work items** (${activeItems.length}):\n\n`;
    for (const wi of activeItems) {
      output += `- **[${wi.type} #${wi.id}] ${wi.title}** (${wi.state}) — _${wi.matchReason}_\n`;
    }
    output += `\n`;
  }

  if (closedItems.length > 0) {
    output += `**Previously addressed** (${closedItems.length}):\n\n`;
    for (const wi of closedItems) {
      output += `- **[${wi.type} #${wi.id}] ${wi.title}** (${wi.state}) — _${wi.matchReason}_\n`;
    }
    output += `\n`;
  }

  return output;
}
