// Azure DevOps work item search client
// Searches for related work items in the Dynamics SMB ADO project
// using the WIQL (Work Item Query Language) REST API.

const ADO_ORG = 'dynamicssmb2';
const ADO_PROJECT = 'Dynamics SMB';
const ADO_API_VERSION = '7.1';
const MAX_RESULTS = 10;

/**
 * Search for related work items in Azure DevOps using keyword-based WIQL queries.
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

  console.log(`ADO: searching work items for [${keywords.slice(0, 5).join(', ')}]...`);

  try {
    const topKeywords = keywords.slice(0, 5);

    // Use AND logic: require all single-word terms to match (title OR description),
    // but treat multi-word phrases as a single Contains clause
    const conditions = topKeywords.map(
      kw => `([System.Title] Contains '${escapeWiql(kw)}' OR [System.Description] Contains '${escapeWiql(kw)}')`
    );
    const whereClause = conditions.join(' AND ');

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

    const fields = ['System.Id', 'System.Title', 'System.State', 'System.WorkItemType'].join(',');
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
    const workItems = (detailsData.value || []).map(wi => ({
      id: wi.id,
      title: wi.fields?.['System.Title'] || '(untitled)',
      state: wi.fields?.['System.State'] || 'Unknown',
      type: wi.fields?.['System.WorkItemType'] || 'Unknown',
      url: `https://dev.azure.com/${ADO_ORG}/${encodeURIComponent(ADO_PROJECT)}/_workitems/edit/${wi.id}`,
    }));

    console.log(`ADO: found ${workItems.length} related work items`);
    return { workItems };

  } catch (err) {
    console.warn(`ADO: search failed - ${err.message}`);
    return { workItems: [], error: err.message };
  }
}

function escapeWiql(str) {
  return str.replace(/'/g, "''");
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
    output += `- **[${wi.type} #${wi.id}] ${wi.title}** (${wi.state})\n`;
  }

  return output;
}
