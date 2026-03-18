// Dynamics 365 Ideas Portal client
// Fetches ideas from the public OData endpoint at experience.dynamics.com
// and matches them against issue keywords for enrichment context.

const IDEAS_ODATA_URL = 'https://experience.dynamics.com/_odata/ideas';
const BC_FORUM_ID = 'e288ef32-82ed-e611-8101-5065f38b21f1';
const PAGES_TO_FETCH = 10;
const PAGE_SIZE = 10;
const MAX_RESULTS = 5;

/**
 * Fetch ideas from the Dynamics 365 Ideas Portal and match against keywords.
 */
export async function fetchRelatedIdeas(keywords) {
  if (!keywords || keywords.length === 0) {
    return { ideas: [], totalFetched: 0 };
  }

  console.log(`Ideas Portal: searching for ideas matching [${keywords.slice(0, 5).join(', ')}]...`);

  let allIdeas = [];
  let error;

  try {
    for (let page = 0; page < PAGES_TO_FETCH; page++) {
      const skip = page * PAGE_SIZE;
      const url = `${IDEAS_ODATA_URL}?$skip=${skip}`;

      const response = await fetch(url, {
        headers: { 'Accept': 'application/json' },
      });

      if (!response.ok) {
        console.warn(`Ideas Portal: page ${page} returned ${response.status}, stopping pagination`);
        break;
      }

      const data = await response.json();
      if (!data.value || data.value.length === 0) break;

      const bcIdeas = data.value.filter(
        idea => idea.adx_ideaforumid?.Id === BC_FORUM_ID && idea.adx_approved
      );

      allIdeas.push(...bcIdeas);

      if (!data['odata.nextLink']) break;
    }
  } catch (err) {
    console.warn(`Ideas Portal: fetch error - ${err.message}`);
    error = err.message;
  }

  console.log(`Ideas Portal: fetched ${allIdeas.length} BC ideas`);

  const scored = allIdeas.map(idea => ({
    title: idea.adx_name || '(untitled)',
    votes: idea.adx_votestotalnumberof || 0,
    status: idea.statuscode?.Name || 'Unknown',
    category: idea.mip_ideacategory?.Name || 'Unknown',
    description: stripHtml(idea.adx_copy || ''),
    url: `https://experience.dynamics.com/ideas/idea/?ideaid=${idea.adx_ideaid}`,
    relevance: scoreIdeaRelevance(idea, keywords),
  }));

  const relevant = scored
    .filter(idea => idea.relevance >= 2)
    .sort((a, b) => b.relevance - a.relevance || b.votes - a.votes)
    .slice(0, MAX_RESULTS);

  console.log(`Ideas Portal: found ${relevant.length} relevant ideas`);

  return {
    ideas: relevant,
    totalFetched: allIdeas.length,
    ...(error && { error }),
  };
}

// Simple suffix-stripping stemmer for improved matching
function stem(word) {
  return word
    .replace(/ies$/, 'y')
    .replace(/ves$/, 'f')
    .replace(/(ing|tion|ment|ness|able|ible|ated|ize|ise)$/, '')
    .replace(/s$/, '')
    .replace(/ed$/, '');
}

// BC domain synonyms: each group of terms should match each other
const SYNONYM_GROUPS = [
  ['price', 'pricing', 'price list'],
  ['purchase', 'purchasing', 'procurement', 'buy'],
  ['sales', 'selling', 'sell'],
  ['invoice', 'invoicing', 'billing'],
  ['inventory', 'stock', 'stockkeeping'],
  ['warehouse', 'warehousing', 'whse'],
  ['manufacturing', 'production', 'mfg'],
  ['assembly', 'assemble', 'asm'],
  ['journal', 'jnl'],
  ['dimension', 'dim'],
  ['reconciliation', 'reconcile', 'recon'],
  ['ledger', 'ledger entry'],
  ['posting', 'post'],
  ['customer', 'cust'],
  ['vendor', 'vend'],
  ['general ledger', 'g/l', 'gl'],
];

// Build lookup: word -> set of synonyms
const _synonymMap = new Map();
for (const group of SYNONYM_GROUPS) {
  for (const term of group) {
    _synonymMap.set(term, group);
  }
}

function expandKeyword(kw) {
  const kwLower = kw.toLowerCase();
  const synonyms = _synonymMap.get(kwLower);
  if (synonyms) return synonyms;
  // Also check stemmed form
  const stemmed = stem(kwLower);
  return [kwLower, stemmed];
}

function scoreIdeaRelevance(idea, keywords) {
  const title = (idea.adx_name || '').toLowerCase();
  const body = (idea.adx_copy || '').toLowerCase();

  let score = 0;
  for (const kw of keywords) {
    const variants = expandKeyword(kw);
    let matched = false;
    for (const variant of variants) {
      if (title.includes(variant)) { score += 3; matched = true; break; }
    }
    if (!matched) {
      for (const variant of variants) {
        if (body.includes(variant)) { score += 1; break; }
      }
    }
  }
  return score;
}

function stripHtml(html) {
  return html.replace(/<[^>]*>/g, '').replace(/&[a-z]+;/gi, ' ').trim();
}

/**
 * Format ideas results for inclusion in the LLM prompt.
 */
export function formatIdeasContext(result) {
  if (!result || result.ideas.length === 0) {
    if (result?.error) {
      return `### Ideas Portal\n\nCould not fetch ideas: ${result.error}\n`;
    }
    return '### Ideas Portal\n\nNo matching ideas found on the Dynamics 365 Ideas Portal.\n';
  }

  let output = `### Ideas Portal matches\n\n`;
  output += `Found ${result.ideas.length} related ideas (from ${result.totalFetched} BC ideas scanned):\n\n`;

  for (const idea of result.ideas) {
    output += `- **${idea.title}** (${idea.votes} votes, ${idea.status})\n`;
    output += `  Category: ${idea.category} | [View idea](${idea.url})\n`;
    if (idea.description) {
      const snippet = idea.description.length > 200
        ? idea.description.substring(0, 200) + '...'
        : idea.description;
      output += `  > ${snippet}\n`;
    }
    output += `\n`;
  }

  return output;
}
