// Shared text similarity utilities for duplicate detection and precedent finding.
// Uses BC domain synonym normalization, bigram matching, and title-weighted scoring
// to catch semantic duplicates that naive Jaccard misses.

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
  'should', 'may', 'might', 'can', 'shall', 'to', 'of', 'in', 'for',
  'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during',
  'before', 'after', 'then', 'when', 'where', 'why', 'how', 'all', 'each',
  'every', 'both', 'few', 'more', 'most', 'other', 'some', 'such', 'no',
  'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 'and', 'but',
  'or', 'if', 'it', 'this', 'that', 'these', 'those', 'i', 'we', 'you',
  'they', 'me', 'us', 'my', 'our', 'your', 'his', 'its', 'their', 'what',
  'which', 'who', 'about', 'up', 'out', 'just', 'also', 'new', 'like',
  'need', 'want', 'use', 'used', 'using', 'add', 'get', 'set', 'make',
  'work', 'way', 'still', 'please', 'would', 'issue', 'bug', 'feature',
  'request', 'error', 'problem',
]);

/**
 * BC domain synonym groups. Each array contains terms that should be treated
 * as equivalent during similarity comparison. The first term in each group
 * is the canonical form all others normalize to.
 */
const SYNONYM_GROUPS = [
  ['sales_invoice', 'sales invoice', 'posted sales invoice', 'sales invoices', 'posted sales invoices'],
  ['purchase_invoice', 'purchase invoice', 'posted purchase invoice', 'purchase invoices', 'posted purchase invoices'],
  ['sales_order', 'sales order', 'sales orders', 'so'],
  ['purchase_order', 'purchase order', 'purchase orders', 'po'],
  ['general_ledger', 'general ledger', 'gl', 'g/l', 'general journal', 'gen. journal'],
  ['bank_reconciliation', 'bank reconciliation', 'bank rec', 'bank recon', 'bank account reconciliation'],
  ['fixed_asset', 'fixed asset', 'fixed assets', 'fa'],
  ['posting_group', 'posting group', 'posting groups', 'gen. posting group', 'general posting group'],
  ['dimension', 'dimension', 'dimensions', 'dimension value', 'dimension set', 'global dimension', 'shortcut dimension'],
  ['item_tracking', 'item tracking', 'serial number', 'serial no', 'lot number', 'lot no', 'lot tracking'],
  ['warehouse', 'warehouse', 'whse', 'wms'],
  ['production_order', 'production order', 'prod order', 'prod. order', 'production orders'],
  ['assembly_order', 'assembly order', 'assembly orders', 'asm order'],
  ['chart_of_accounts', 'chart of accounts', 'coa', 'account chart'],
  ['vat', 'vat', 'value added tax', 'tax', 'sales tax'],
  ['rounding', 'rounding', 'round', 'rounding error', 'rounding issue', 'rounding difference', 'penny difference'],
  ['amount', 'amount', 'amounts', 'incorrect amount', 'wrong amount'],
  ['posting', 'posting', 'post', 'posted', 'posts'],
  ['customer', 'customer', 'customers', 'cust', 'sell-to', 'bill-to'],
  ['vendor', 'vendor', 'vendors', 'vend', 'buy-from', 'pay-to'],
  ['ledger_entry', 'ledger entry', 'ledger entries', 'entry', 'entries'],
  ['service_order', 'service order', 'service orders', 'service document', 'service documents'],
  ['cash_flow', 'cash flow', 'cash flow forecast', 'cashflow'],
  ['cost_accounting', 'cost accounting', 'cost center', 'cost type', 'cost object'],
  ['job_queue', 'job queue', 'job queue entry', 'background task', 'scheduled task'],
  ['approval', 'approval', 'approval workflow', 'approval entry', 'approval request'],
  ['e_document', 'e-document', 'edocument', 'e-invoice', 'einvoice', 'electronic document', 'electronic invoice'],
  ['shopify', 'shopify', 'shopify connector', 'shopify sync', 'shopify integration'],
  ['price_list', 'price list', 'price lists', 'sales price', 'purchase price', 'price calculation'],
  ['subscription_billing', 'subscription billing', 'recurring billing', 'subscription', 'recurring revenue'],
  ['intercompany', 'intercompany', 'inter-company', 'ic transaction', 'ic partner'],
  ['copilot', 'copilot', 'ai', 'artificial intelligence', 'ai suggestion'],
  ['dataverse', 'dataverse', 'cds', 'common data service', 'dynamics 365 sales integration'],
  ['transfer_order', 'transfer order', 'transfer orders', 'location transfer', 'inventory transfer'],
  ['payment', 'payment', 'payments', 'payment journal', 'payment registration', 'vendor payment'],
  ['reminder', 'reminder', 'reminders', 'finance charge', 'finance charge memo'],
];

// Build a lookup: term → canonical form
const synonymLookup = new Map();
for (const group of SYNONYM_GROUPS) {
  const canonical = group[0];
  for (const term of group) {
    synonymLookup.set(term, canonical);
  }
}

// Multi-word synonyms sorted longest-first for greedy matching
const multiWordSynonyms = [...synonymLookup.keys()]
  .filter(k => k.includes(' ') || k.includes('-'))
  .sort((a, b) => b.length - a.length);

/**
 * Normalize text by replacing known BC domain synonyms with canonical forms.
 * Multi-word phrases are matched first (longest-first), then single words.
 */
function normalizeSynonyms(text) {
  let result = text.toLowerCase();
  // Replace multi-word synonyms first (longest match wins)
  for (const phrase of multiWordSynonyms) {
    if (result.includes(phrase)) {
      result = result.replaceAll(phrase, synonymLookup.get(phrase));
    }
  }
  return result;
}

/**
 * Extract bigrams (two-word phrases) from a word list.
 * Both words must be non-stop-words and > 2 chars.
 */
function extractBigrams(words) {
  const bigrams = [];
  for (let i = 0; i < words.length - 1; i++) {
    const w1 = words[i], w2 = words[i + 1];
    if (!STOP_WORDS.has(w1) && !STOP_WORDS.has(w2) && w1.length > 2 && w2.length > 2) {
      bigrams.push(`${w1}_${w2}`);
    }
  }
  return bigrams;
}

/**
 * Tokenize text into a set of meaningful tokens, including:
 * - Single words (stop-words removed, synonyms normalized)
 * - Bigrams for phrase-level matching
 */
export function tokenize(text) {
  const normalized = normalizeSynonyms(text || '');
  const cleaned = normalized.replace(/[^a-z0-9_\s-]/g, ' ');
  const words = cleaned.split(/\s+/).filter(w => w.length > 2 && !STOP_WORDS.has(w));
  const bigrams = extractBigrams(words);
  return new Set([...words, ...bigrams]);
}

/**
 * Compute Jaccard similarity between two token sets.
 */
export function jaccardSimilarity(setA, setB) {
  if (setA.size === 0 && setB.size === 0) return 0;
  let intersection = 0;
  for (const token of setA) {
    if (setB.has(token)) intersection++;
  }
  const union = setA.size + setB.size - intersection;
  return union === 0 ? 0 : intersection / union;
}

/**
 * Compute a weighted similarity score that emphasizes title overlap.
 *
 * The score is a weighted average of:
 * - Full text Jaccard similarity (title + body vs title + body)
 * - Title-to-title Jaccard similarity (weighted 2x)
 *
 * This way, two issues with similar titles but different body text
 * still score high, catching semantic duplicates.
 */
export function weightedSimilarity(titleA, bodyA, titleB, bodyB) {
  const titleTokensA = tokenize(titleA);
  const titleTokensB = tokenize(titleB);
  const fullTokensA = tokenize(`${titleA} ${bodyA}`);
  const fullTokensB = tokenize(`${titleB} ${bodyB}`);

  const titleSim = jaccardSimilarity(titleTokensA, titleTokensB);
  const fullSim = jaccardSimilarity(fullTokensA, fullTokensB);

  // Weight: 2/3 title similarity, 1/3 full-text similarity.
  // Title is the strongest signal for duplicate intent.
  return (titleSim * 2 + fullSim) / 3;
}
