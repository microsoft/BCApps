// Azure DevOps work item search client
// Searches for related work items in the Dynamics SMB ADO project
// using the WIQL (Work Item Query Language) REST API.

const ADO_ORG = 'dynamicssmb2';
const ADO_PROJECT = 'Dynamics SMB';
const ADO_API_VERSION = '7.1';
const MAX_RESULTS = 10;
const MIN_RELEVANCE = 3; // Require at least a title match or multiple description matches

/**
 * Search for related work items in Azure DevOps using keyword-based WIQL queries.
 * Each result is scored by how many keywords matched its title/description.
 */
export async function fetchRelatedWorkItems(keywords) {
  const pat = process.env.ADO_PAT;
  if (!pat) {
    console.log('ADO: No ADO_PAT configured, skipping work item search');
    return { workItems: [], error: 'ADO_PAT not configured' };
  }

  if (!keywords || keywords.length === 0) {
    return { workItems: [] };
  }

  // Separate multi-word phrases (more specific) from single words (broader)
  const phrases = keywords.filter(kw => kw.includes(' ')).slice(0, 4);
  const singles = keywords.filter(kw => !kw.includes(' ')).slice(0, 4);
  const topKeywords = [...phrases, ...singles].slice(0, 7);

  console.log(`ADO: searching work items for [${topKeywords.join(', ')}]...`);

  try {
    // Build WIQL: if we have specific phrases, require at least one phrase match
    // combined with broader single-word matches
    let whereClause;
    if (phrases.length > 0 && singles.length > 0) {
      // Require at least one phrase in title/description AND at least one single word
      const phraseConditions = phrases.flatMap(kw => [
        `[System.Title] Contains '${escapeWiql(kw)}'`,
        `[System.Description] Contains '${escapeWiql(kw)}'`,
      ]).join(' OR ');
      const singleConditions = singles.flatMap(kw => [
        `[System.Title] Contains '${escapeWiql(kw)}'`,
        `[System.Description] Contains '${escapeWiql(kw)}'`,
      ]).join(' OR ');
      whereClause = `(${phraseConditions}) AND (${singleConditions})`;
    } else {
      // Fallback: OR logic across all keywords
      const conditions = topKeywords.flatMap(kw => [
        `[System.Title] Contains '${escapeWiql(kw)}'`,
        `[System.Description] Contains '${escapeWiql(kw)}'`,
      ]);
      whereClause = conditions.join(' OR ');
    }

    const wiql = `SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = '${ADO_PROJECT}' AND (${whereClause}) ORDER BY [System.ChangedDate] DESC`;

    const wiqlUrl = `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_apis/wit/wiql?api-version=${ADO_API_VERSION}&$top=${MAX_RESULTS}`;
    const authHeader = `Basic ${btoa(':' + pat)}`;

    const wiqlResponse = await fetch(wiqlUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      },
      body: JSON.stringify({ query: wiql }),
    });

    if (!wiqlResponse.ok) {
      const text = await wiqlResponse.text();
      throw new Error(`WIQL query failed (${wiqlResponse.status}): ${text.substring(0, 200)}`);
    }

    const wiqlData = await wiqlResponse.json();
    const ids = (wiqlData.workItems || []).map(wi => wi.id);

    if (ids.length === 0) {
      console.log('ADO: no matching work items found');
      return { workItems: [] };
    }

    // Fetch details including description for relevance scoring
    const fields = ['System.Id', 'System.Title', 'System.State', 'System.WorkItemType', 'System.Description'].join(',');
    const idsParam = ids.slice(0, MAX_RESULTS).join(',');
    const detailsUrl = `https://dev.azure.com/${ADO_ORG}/_apis/wit/workitems?ids=${idsParam}&fields=${fields}&api-version=${ADO_API_VERSION}`;

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
      const description = stripHtml(wi.fields?.['System.Description'] || '');
      const { score, matchedKeywords } = scoreRelevance(title, description, topKeywords);

      return {
        id: wi.id,
        title,
        state: wi.fields?.['System.State'] || 'Unknown',
        type: wi.fields?.['System.WorkItemType'] || 'Unknown',
        url: `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_workitems/edit/${wi.id}`,
        relevanceScore: score,
        matchedKeywords,
        matchReason: buildMatchReason(matchedKeywords),
      };
    });

    // Filter by minimum relevance, sort by score descending, return top 5
    const relevant = workItems
      .filter(wi => wi.relevanceScore >= MIN_RELEVANCE)
      .sort((a, b) => b.relevanceScore - a.relevanceScore)
      .slice(0, 5);

    console.log(`ADO: found ${relevant.length} relevant work items (${workItems.length} total matches, min score ${MIN_RELEVANCE})`);
    return { workItems: relevant };

  } catch (err) {
    console.warn(`ADO: search failed - ${err.message}`);
    return { workItems: [], error: err.message };
  }
}

/**
 * Remove bracketed tags like [BC Idea], [Bug], [Feature] from text.
 * These are metadata properties, not descriptive content.
 */
function stripBracketedTags(text) {
  return text.replace(/\[[^\]]*\]/g, ' ');
}

/**
 * Score a work item's relevance based on keyword matches in title and description.
 * Title matches are weighted 3x, description matches 1x.
 * Bracketed tags (e.g. [BC Idea]) are stripped before matching.
 */
function scoreRelevance(title, description, keywords) {
  const titleLower = stripBracketedTags(title).toLowerCase();
  const descLower = stripBracketedTags(description).toLowerCase();
  let score = 0;
  const matchedKeywords = [];

  for (const kw of keywords) {
    const kwLower = kw.toLowerCase();
    const isPhrase = kwLower.includes(' ');
    // Use word-boundary matching for single words to avoid substring false positives
    // (e.g. "order" should not match "reorder" or "disorder")
    // Phrases use substring matching since they are already specific
    const inTitle = isPhrase
      ? titleLower.includes(kwLower)
      : new RegExp(`\\b${escapeRegex(kwLower)}\\b`).test(titleLower);
    const inDesc = isPhrase
      ? descLower.includes(kwLower)
      : new RegExp(`\\b${escapeRegex(kwLower)}\\b`).test(descLower);

    // Multi-word phrases are weighted higher — they signal stronger relevance
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

  return { score, matchedKeywords };
}

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * Build a human-readable match reason from matched keywords.
 */
function buildMatchReason(matchedKeywords) {
  if (matchedKeywords.length === 0) return 'Weak match';

  const titleMatches = matchedKeywords.filter(m => m.location === 'title').map(m => m.keyword);
  const descMatches = matchedKeywords.filter(m => m.location === 'description').map(m => m.keyword);

  const parts = [];
  if (titleMatches.length > 0) {
    parts.push(`title matches: ${titleMatches.join(', ')}`);
  }
  if (descMatches.length > 0) {
    parts.push(`description matches: ${descMatches.join(', ')}`);
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
 */
export function formatAdoContext(result) {
  if (!result || result.workItems.length === 0) {
    if (result?.error === 'ADO_PAT not configured') {
      return '### Azure DevOps\n\nADO work item search is not configured (no ADO_PAT).\n';
    }
    if (result?.error) {
      return `### Azure DevOps\n\nCould not search work items: ${result.error}\n`;
    }
    return '### Azure DevOps\n\nNo matching work items found in Dynamics SMB project.\n';
  }

  let output = `### Azure DevOps related work items\n\n`;
  output += `Found ${result.workItems.length} related work items in the Dynamics SMB project:\n\n`;

  for (const wi of result.workItems) {
    output += `- **[${wi.type} #${wi.id}] ${wi.title}** (${wi.state}) — _${wi.matchReason}_\n`;
  }

  return output;
}
