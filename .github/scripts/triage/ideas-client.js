// Dynamics 365 Ideas Portal client
// Fetches ideas from the public OData endpoint at experience.dynamics.com
// and matches them against issue keywords for enrichment context.

import { tokenize, jaccardSimilarity } from './text-similarity.js';

const IDEAS_ODATA_URL = 'https://experience.dynamics.com/_odata/ideas';
const BC_FORUM_ID = 'e288ef32-82ed-e611-8101-5065f38b21f1';
const BC_FORUM_FILTER = `adx_ideaforumid/Id eq guid'${BC_FORUM_ID}' and adx_approved eq true`;
const RESULTS_PER_QUERY = 20;
const MAX_RESULTS = 5;
const FETCH_TIMEOUT_MS = 10_000;
const MAX_SYNONYM_VARIANTS = 3;

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
 * Fetch ideas from the Dynamics 365 Ideas Portal and match against keywords.
 */
export async function fetchRelatedIdeas(keywords, issueTitle = '') {
  if (!keywords || keywords.length === 0) {
    return { ideas: [], totalFetched: 0 };
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
  const phrases = uniqueKeywords.filter(kw => kw.includes(' ')).slice(0, 4);
  const singles = uniqueKeywords.filter(kw => !kw.includes(' ')).slice(0, 4);
  const topKeywords = [...phrases, ...singles].slice(0, 7);

  console.log(`Ideas Portal: searching for ideas matching [${topKeywords.join(', ')}]...`);

  const seenIds = new Set();
  const allIdeas = [];
  let error;

  try {
    // Run one targeted OData query per keyword, all in parallel
    const queryPromises = topKeywords.map(kw => {
      const filter = buildSearchFilter(kw);
      const url = `${IDEAS_ODATA_URL}?$top=${RESULTS_PER_QUERY}`
        + `&$orderby=adx_votestotalnumberof%20desc`
        + `&$filter=${encodeURIComponent(filter)}`;
      return fetchWithTimeout(url, { headers: { 'Accept': 'application/json' } })
        .then(res => res.ok ? res.json() : null)
        .catch(() => null);
    });

    const results = await Promise.all(queryPromises);

    for (const data of results) {
      if (!data?.value) continue;
      for (const idea of data.value) {
        if (!seenIds.has(idea.adx_ideaid)) {
          seenIds.add(idea.adx_ideaid);
          allIdeas.push(idea);
        }
      }
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
    relevance: scoreIdeaRelevance(idea, topKeywords, issueTitle),
  }));

  // Statuses considered "active" (not yet delivered or declined)
  const CLOSED_STATUSES = new Set(['completed', 'declined', 'closed', 'archived', 'delivered', 'won\'t do', 'duplicate', 'out of scope']);

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
  if (stemmed !== kwLower) return [kwLower, stemmed];
  return [kwLower];
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

function scoreIdeaRelevance(idea, keywords, issueTitle = '') {
  const title = (idea.adx_name || '').toLowerCase();
  const body = stripHtml(idea.adx_copy || '').toLowerCase();

  let score = 0;
  for (const kw of keywords) {
    const isPhrase = kw.includes(' ');
    const variants = expandKeyword(kw);
    let matched = false;

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

  // Title similarity bonus using shared synonym-aware tokenizer.
  if (issueTitle) {
    const issueTokens = tokenize(issueTitle);
    const ideaTokens = tokenize(title);
    const similarity = jaccardSimilarity(issueTokens, ideaTokens);
    score += Math.round(similarity * 25);
  }

  return score;
}

function stripHtml(html) {
  return html
    .replace(/<[^>]*>/g, '')
    .replace(/&(?:#\d+|#x[\da-fA-F]+|[a-z]+);/gi, ' ')  // handle named + numeric HTML entities
    .trim();
}

/**
 * Build an OData $filter clause that searches both title and body for a keyword
 * and its synonym variants, scoped to the BC forum with approved ideas only.
 */
function buildSearchFilter(keyword) {
  const variants = expandKeyword(keyword).slice(0, MAX_SYNONYM_VARIANTS);
  const clauses = [];
  for (const variant of variants) {
    const escaped = variant.replace(/'/g, "''");
    clauses.push(`substringof('${escaped}',adx_name)`);
    clauses.push(`substringof('${escaped}',adx_copy)`);
  }
  return `${BC_FORUM_FILTER} and (${clauses.join(' or ')})`;
}

function formatIdeaEntry(idea) {
  let entry = `- [**${idea.title}**](${idea.url}) — ${idea.votes} votes, ${idea.status} · ${idea.category}\n`;
  if (idea.description) {
    const snippet = idea.description.length > 200
      ? idea.description.substring(0, 200) + '...'
      : idea.description;
    entry += `  > ${snippet}\n`;
  }
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

  let output = `### Ideas Portal\n\n`;
  output += `_Demand signal: community-submitted feature requests and pain points. High-vote ideas indicate widespread need._\n\n`;

  if (active.length > 0) {
    output += `**Active ideas** (${active.length}):\n\n`;
    for (const idea of active) {
      output += formatIdeaEntry(idea);
    }
    output += '\n';
  }

  if (closed.length > 0) {
    output += `**Previously addressed** (${closed.length}):\n\n`;
    for (const idea of closed) {
      output += formatIdeaEntry(idea);
    }
    output += '\n';
  }

  return output;
}
