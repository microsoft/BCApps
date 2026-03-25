// Dynamics 365 Ideas Portal client
// Fetches ideas from the public OData endpoint at experience.dynamics.com
// and matches them against issue keywords for enrichment context.

const IDEAS_ODATA_URL = 'https://experience.dynamics.com/_odata/ideas';
const BC_FORUM_ID = 'e288ef32-82ed-e611-8101-5065f38b21f1';
const PAGES_TO_FETCH = 30;
const PAGE_SIZE = 10;
const MAX_RESULTS = 5;

/**
 * Fetch ideas from the Dynamics 365 Ideas Portal and match against keywords.
 */
export async function fetchRelatedIdeas(keywords) {
  if (!keywords || keywords.length === 0) {
    return { ideas: [], totalFetched: 0 };
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
  const phrases = uniqueKeywords.filter(kw => kw.includes(' ')).slice(0, 4);
  const singles = uniqueKeywords.filter(kw => !kw.includes(' ')).slice(0, 4);
  const topKeywords = [...phrases, ...singles].slice(0, 7);

  console.log(`Ideas Portal: searching for ideas matching [${topKeywords.join(', ')}]...`);

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
    relevance: scoreIdeaRelevance(idea, topKeywords),
  }));

  // Statuses considered "active" (not yet delivered or declined)
  const CLOSED_STATUSES = new Set(['completed', 'declined', 'closed', 'archived', 'delivered']);

  const relevant = scored.filter(idea => idea.relevance >= 3);

  const activeIdeas = relevant
    .filter(idea => !CLOSED_STATUSES.has(idea.status.toLowerCase()))
    .sort((a, b) => b.relevance - a.relevance || b.votes - a.votes)
    .slice(0, MAX_RESULTS);

  const closedIdeas = relevant
    .filter(idea => CLOSED_STATUSES.has(idea.status.toLowerCase()))
    .sort((a, b) => b.relevance - a.relevance || b.votes - a.votes)
    .slice(0, 3);

  console.log(`Ideas Portal: found ${activeIdeas.length} active + ${closedIdeas.length} closed ideas (from ${relevant.length} relevant)`);

  return {
    activeIdeas,
    closedIdeas,
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
  ['approval', 'approvals', 'approval workflow'],
  ['service', 'service management', 'service order'],
  ['document', 'documents', 'doc'],
  ['reminder', 'finance charge', 'finance charge memo'],
  ['reservation', 'reserve', 'reservations'],
  ['transfer', 'transfer order'],
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

function escapeRegex(str) {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function textContains(text, term) {
  // Multi-word phrases use substring matching (already specific)
  // Single words use word-start boundary to avoid prefix false positives
  // (e.g. "order" won't match "reorder") while matching suffixed forms
  // (e.g. "approval" matches "approvals", "approved")
  if (term.includes(' ')) return text.includes(term);
  return new RegExp(`\\b${escapeRegex(term)}`).test(text);
}

function scoreIdeaRelevance(idea, keywords) {
  const title = (idea.adx_name || '').toLowerCase();
  const body = stripHtml(idea.adx_copy || '').toLowerCase();

  let score = 0;
  for (const kw of keywords) {
    const isPhrase = kw.includes(' ');
    const variants = expandKeyword(kw);
    let matched = false;

    // Multi-word phrases are weighted higher — they signal stronger relevance
    const titleWeight = isPhrase ? 5 : 3;
    const descWeight = isPhrase ? 2 : 1;

    for (const variant of variants) {
      if (textContains(title, variant)) { score += titleWeight; matched = true; break; }
    }
    if (!matched) {
      for (const variant of variants) {
        if (textContains(body, variant)) { score += descWeight; break; }
      }
    }
  }
  return score;
}

function stripHtml(html) {
  return html.replace(/<[^>]*>/g, '').replace(/&[a-z]+;/gi, ' ').trim();
}

function formatIdeaEntry(idea) {
  let entry = `- **${idea.title}** (${idea.votes} votes, ${idea.status})\n`;
  entry += `  Category: ${idea.category} | [View idea](${idea.url})\n`;
  if (idea.description) {
    const snippet = idea.description.length > 200
      ? idea.description.substring(0, 200) + '...'
      : idea.description;
    entry += `  > ${snippet}\n`;
  }
  entry += `\n`;
  return entry;
}

/**
 * Format ideas results for inclusion in the LLM prompt.
 * Shows active ideas first, then completed/declined in a separate section.
 */
export function formatIdeasContext(result) {
  const active = result?.activeIdeas || [];
  const closed = result?.closedIdeas || [];

  if (active.length === 0 && closed.length === 0) {
    if (result?.error) {
      return `### Ideas Portal\n\nCould not fetch ideas: ${result.error}\n`;
    }
    return '### Ideas Portal\n\nNo matching ideas found on the Dynamics 365 Ideas Portal.\n';
  }

  let output = `### Ideas Portal matches\n\n`;
  output += `Scanned ${result.totalFetched} BC ideas.\n\n`;

  if (active.length > 0) {
    output += `**Active ideas** (${active.length}):\n\n`;
    for (const idea of active) {
      output += formatIdeaEntry(idea);
    }
  }

  if (closed.length > 0) {
    output += `**Previously addressed** (${closed.length}):\n\n`;
    for (const idea of closed) {
      output += formatIdeaEntry(idea);
    }
  }

  return output;
}
