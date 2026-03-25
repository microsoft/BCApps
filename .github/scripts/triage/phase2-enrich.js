// Phase 2: Issue enrichment and triage assessment
// See: docs/features/issue-triage-agent/design.md (FR9-FR16, section 6.6)

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { callGPT } from './models-client.js';
import { detectAppArea } from './config.js';
import { fetchCodeContext, formatCodeContext } from './code-reader.js';
import { fetchRelatedIdeas, formatIdeasContext } from './ideas-client.js';
import { fetchRelatedWorkItems, formatAdoContext } from './ado-client.js';
import { fetchMarketplaceApps, formatMarketplaceContext } from './marketplace-client.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Enrich the issue with external context and produce a triage assessment.
 * Takes the original issue and Phase 1 results as input.
 */
export async function enrichAndTriage(issue, phase1Result) {
  // Build system prompt from skill knowledge files + agent-specific enrichment and output instructions
  const repoRoot = join(__dirname, '..', '..', '..');
  const skillDir = join(repoRoot, 'plugins', 'triage', 'skills', 'triage');
  const glossary = readFileSync(join(skillDir, 'SKILL.md'), 'utf-8')
    .replace(/^---[\s\S]*?---\n/, '')
    .match(/## BC\/AL Domain Glossary[\s\S]*?(?=## Triage Process Overview)/)?.[0] || '';
  const domainKnowledge = readFileSync(join(skillDir, 'bc-domain.md'), 'utf-8');
  const enrichKnowledge = readFileSync(join(skillDir, 'triage-enrich.md'), 'utf-8');

  const systemPrompt = `You are a senior product manager and technical lead performing triage on a GitHub issue for a Microsoft Dynamics 365 Business Central application repository. You have been given the issue content, a quality assessment from Phase 1, and enrichment data including repository code structure, Ideas Portal matches, and Azure DevOps work items.

Your job is to enrich the issue with external context and produce a triage recommendation that helps a product manager decide: implement, defer, investigate, or reject.

${glossary}

${domainKnowledge}

## Enrichment instructions

Based on the issue content, think about what documentation, community discussions, and ideas portal entries would be relevant. Provide the most relevant links and context you know of.

### Documentation (Microsoft Learn)
Search your knowledge for relevant Business Central documentation from learn.microsoft.com. Focus on feature documentation, API documentation, known limitations, and configuration guides.
Provide actual URLs when confident they exist. Format: \`https://learn.microsoft.com/en-us/dynamics365/business-central/...\`

### Ideas Portal (experience.dynamics.com)
You will be provided with actual search results from the Dynamics 365 Ideas Portal. Use these to gauge community demand, check current status of related ideas, and incorporate high-vote ideas into your value assessment.

### Azure DevOps work items
You may be provided with related work items from the Dynamics SMB ADO project. Use these to identify if this issue is already tracked internally and factor existing work into your recommended action.

### Community discussions
Consider relevant Stack Overflow questions, GitHub issues in related repositories, or community forum discussions.

### AppSource Marketplace
You will be provided with search results from the Microsoft AppSource marketplace for Business Central apps. Use the number of related apps as a demand signal:
- **20+ related apps**: Strong ecosystem interest — the capability is well-established and improvements have high value
- **5-19 related apps**: Moderate interest — established demand in this area
- **<5 related apps**: Niche area — could be an opportunity or low-demand capability
Factor the marketplace signal into your value and priority assessment.

### Repository source code
You will be provided with actual source code files from the detected app area. Use this code to identify specific AL objects that would need to change, assess complexity, evaluate risk, estimate effort, and determine the implementation path.

### Related code areas
Based on the detected app area, issue content, and the provided source code, identify which files and directories are most relevant. Be specific about which AL objects would need modification.

${enrichKnowledge}

## Output format

Return a JSON object with this exact structure:
\`\`\`json
{
  "enrichment": {
    "documentation": [
      { "title": "Article title", "url": "https://...", "relevance": "Why this is relevant" }
    ],
    "ideas_portal": [
      { "title": "Idea title", "url": "https://experience.dynamics.com/...", "relevance": "Why this is relevant" }
    ],
    "community": [
      { "title": "Discussion title", "url": "https://...", "relevance": "Why this is relevant" }
    ],
    "code_areas": [
      { "path": "src/Apps/W1/...", "relevance": "Why this area is relevant" }
    ]
  },
  "triage": {
    "complexity": { "rating": "Medium", "rationale": "Explanation" },
    "value": { "rating": "High", "rationale": "Explanation" },
    "risk": { "rating": "Low", "rationale": "Explanation" },
    "effort": { "rating": "M", "rationale": "Explanation" },
    "implementation_path": { "rating": "Copilot-Assisted", "rationale": "Explanation" },
    "priority_score": { "score": 7, "rationale": "Calculation explanation" },
    "confidence": { "rating": "High", "rationale": "Explanation" },
    "recommended_action": { "action": "Implement", "rationale": "Explanation" }
  },
  "executive_summary": "2-3 sentence summary for a product manager who needs to make a quick decision."
}
\`\`\`

Return ONLY valid JSON. No markdown fences, no explanation text outside the JSON.`;

  const appArea = detectAppArea(issue.title, issue.body);
  console.log(`Phase 2: Detected app area: ${appArea.name} (${appArea.directory})`);

  // Use LLM-extracted search terms from Phase 1 (with regex fallback)
  const llmTerms = phase1Result.search_terms || [];
  const regexTerms = extractKeyTerms(issue.title, issue.body);
  const keyTerms = llmTerms.length >= 3 ? llmTerms : regexTerms;
  console.log(`Phase 2: Key terms (${llmTerms.length >= 3 ? 'LLM' : 'regex'}): [${keyTerms.join(', ')}]`);

  // Fetch all enrichment context in parallel
  console.log(`Phase 2: Fetching enrichment context (code, Ideas Portal, ADO, AppSource)...`);
  const [codeContext, ideasResult, adoResult, marketplaceResult] = await Promise.all([
    Promise.resolve(fetchCodeContext(appArea.directory, keyTerms)),
    fetchRelatedIdeas(keyTerms),
    fetchRelatedWorkItems(keyTerms),
    fetchMarketplaceApps(keyTerms),
  ]);

  console.log(`Phase 2: Code context: ${codeContext.relevantFiles?.length || 0} files from ${appArea.directory}`);
  console.log(`Phase 2: Ideas Portal: ${ideasResult.ideas?.length || 0} matches`);
  console.log(`Phase 2: ADO: ${adoResult.workItems?.length || 0} work items`);
  console.log(`Phase 2: AppSource: search terms "${marketplaceResult.searchTerms}" (LLM will estimate)`);

  const codeContextBlock = formatCodeContext(codeContext);
  const ideasContextBlock = formatIdeasContext(ideasResult);
  const adoContextBlock = formatAdoContext(adoResult);
  const marketplaceContextBlock = formatMarketplaceContext(marketplaceResult);

  // Truncate very long issue bodies to avoid excessive token usage
  const maxBodyChars = 8000;
  const issueBody = (issue.body || '(empty)').length > maxBodyChars
    ? issue.body.substring(0, maxBodyChars) + '\n... (truncated)'
    : (issue.body || '(empty)');

  // Include issue comments — they often contain clarifications, repro steps, and version info
  const maxCommentChars = 4000;
  let commentsBlock = '';
  if (issue.comments && issue.comments.length > 0) {
    let commentsText = issue.comments
      .map(c => `**${c.author}**: ${c.body}`)
      .join('\n\n');
    if (commentsText.length > maxCommentChars) {
      commentsText = commentsText.substring(0, maxCommentChars) + '\n... (truncated)';
    }
    commentsBlock = `### Issue comments\n\n${commentsText}\n\n`;
  }

  const userMessage = `## Issue #${issue.number}: ${issue.title}

### Issue body

${issueBody}

${commentsBlock}### Phase 1 assessment

- **Quality score**: ${phase1Result.quality_score.total}/100
- **Verdict**: ${phase1Result.verdict}
- **Issue type**: ${phase1Result.issue_type}
- **Summary**: ${phase1Result.summary}
- **Detected app area**: ${phase1Result.detected_app_area}

### Context for enrichment

- **App area directory**: ${appArea.directory}
- **Key search terms**: ${keyTerms.join(', ')}
- **Repository**: microsoft/BCAppsCampAIRHack (Business Central applications)
- **Search scope for documentation**: site:learn.microsoft.com/en-us/dynamics365/business-central/
- **Search scope for community**: stackoverflow.com, github.com/microsoft/BCApps

${codeContextBlock}

${ideasContextBlock}

${adoContextBlock}

${marketplaceContextBlock}

Please analyze all provided context - source code structure, Ideas Portal matches, ADO work items, AppSource marketplace data, and your knowledge of documentation and community discussions.
Then provide your triage assessment as JSON.`;

  console.log(`Phase 2: Enriching and triaging issue #${issue.number}...`);
  const result = await callGPT(systemPrompt, userMessage);

  // Validate response structure and types
  validatePhase2Response(result);

  console.log(`Phase 2 complete: Priority ${result.triage.priority_score?.score}/10 - ${result.triage.recommended_action?.action}`);

  // Attach analyzed file metadata so the comment formatter can display it
  if (!result.enrichment) result.enrichment = {};
  result.enrichment.analyzed_files = codeContext.relevantFiles.map(f => f.path);
  result.enrichment.analyzed_directory = codeContext.directory;
  result.enrichment.matched_ideas = ideasResult.ideas.map(i => ({
    title: i.title, votes: i.votes, status: i.status, url: i.url,
  }));
  result.enrichment.ado_work_items = adoResult.workItems;
  result.enrichment.marketplace = {
    searchTerms: marketplaceResult.searchTerms,
    searchUrl: marketplaceResult.searchUrl,
  };

  return result;
}

// Known BC multi-word terms that should be kept intact during extraction.
// These are matched first (longest first) before falling back to single words / bigrams.
const BC_DOMAIN_PHRASES = [
  'purchase order', 'purchase invoice', 'purchase line', 'purchase header',
  'sales order', 'sales invoice', 'sales line', 'sales header', 'sales price',
  'general ledger', 'general journal', 'chart of accounts',
  'bank reconciliation', 'bank account',
  'fixed asset', 'fixed assets',
  'posting group', 'posting groups',
  'number series', 'no. series',
  'dimension value', 'dimension set',
  'item tracking', 'item charge', 'item journal',
  'warehouse receipt', 'warehouse shipment',
  'production order', 'production bom', 'bill of material',
  'work center', 'machine center',
  'service order', 'service item', 'service contract',
  'cash flow', 'cash flow forecast',
  'cost accounting', 'cost center', 'cost type',
  'assembly order', 'assembly bom',
  'data archive', 'data search', 'data exchange',
  'e-document', 'e-invoice',
  'subscription billing', 'recurring billing',
  'quality management', 'quality inspection',
  'power bi', 'excel report',
  'role center',
  'ledger entry', 'customer ledger', 'vendor ledger', 'item ledger',
  'job queue', 'job journal',
  'payment journal', 'payment registration',
  'intercompany', 'responsibility center',
  'shopify connector',
  'retention policy',
  'price list', 'price calculation',
  'transfer order', 'location transfer',
  'human resource', 'employment contract',
];
// Sort longest first so longer phrases match before shorter substrings
const SORTED_PHRASES = [...BC_DOMAIN_PHRASES].sort((a, b) => b.length - a.length);

/**
 * Extract meaningful search terms from issue title and body.
 * Prioritizes known BC domain phrases, then bigrams, then single high-frequency words.
 */
function extractKeyTerms(title, body) {
  const text = `${title} ${body}`.toLowerCase();
  const stopWords = new Set([
    'the', 'a', 'an', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
    'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could',
    'should', 'may', 'might', 'can', 'shall', 'to', 'of', 'in', 'for',
    'on', 'with', 'at', 'by', 'from', 'as', 'into', 'through', 'during',
    'before', 'after', 'above', 'below', 'between', 'out', 'off', 'over',
    'under', 'again', 'further', 'then', 'once', 'here', 'there', 'when',
    'where', 'why', 'how', 'all', 'each', 'every', 'both', 'few', 'more',
    'most', 'other', 'some', 'such', 'no', 'not', 'only', 'own', 'same',
    'so', 'than', 'too', 'very', 'and', 'but', 'or', 'nor', 'if', 'it',
    'this', 'that', 'these', 'those', 'i', 'we', 'you', 'he', 'she',
    'they', 'me', 'us', 'him', 'her', 'them', 'my', 'our', 'your', 'his',
    'its', 'their', 'what', 'which', 'who', 'whom', 'about', 'up',
    // BC-domain generic terms that match too broadly
    'item', 'items', 'page', 'pages', 'table', 'tables', 'field', 'fields',
    'function', 'functions', 'report', 'reports', 'codeunit', 'codeunits',
    'value', 'values', 'number', 'numbers', 'code', 'name', 'list', 'card',
    'document', 'documents', 'entry', 'entries', 'line', 'lines', 'record',
    'records', 'data', 'type', 'option', 'action', 'error', 'issue', 'bug',
    'feature', 'request', 'add', 'added', 'adding', 'change', 'changed',
    'new', 'create', 'update', 'delete', 'get', 'set', 'show', 'display',
    'open', 'close', 'run', 'use', 'used', 'using', 'work', 'works',
    'need', 'want', 'like', 'make', 'way', 'also', 'just', 'still',
    'appear', 'appears', 'look', 'looks', 'seem', 'seems', 'expected',
    // Code-level noise that leaks from issue bodies containing AL/code snippets
    'procedure', 'var', 'begin', 'end', 'local', 'trigger', 'true', 'false',
    'then', 'else', 'exit', 'repeat', 'until', 'case', 'with', 'rec',
    'text', 'integer', 'boolean', 'decimal', 'guid', 'enum', 'interface',
    'try', 'catch', 'throw', 'return', 'call', 'method', 'parameter',
    'log', 'logging', 'message', 'result', 'response', 'context',
    'init', 'setup', 'handler', 'helper', 'util', 'utils', 'service',
    'file', 'files', 'path', 'string', 'object', 'class', 'module',
    'something', 'anything', 'everything', 'nothing', 'thing', 'things',
    'however', 'therefore', 'instead', 'already', 'currently', 'actually',
    'basically', 'simply', 'really', 'always', 'never', 'sometimes',
    'able', 'unable', 'possible', 'impossible', 'necessary', 'specific',
  ]);

  // Step 1: Extract known BC domain phrases found in the text
  const domainMatches = [];
  for (const phrase of SORTED_PHRASES) {
    if (text.includes(phrase)) {
      domainMatches.push(phrase);
      if (domainMatches.length >= 5) break; // cap domain phrases
    }
  }

  // Step 2: Extract single words
  const words = text
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.has(w));

  // Step 3: Extract bigrams (two-word phrases) for more specific matching
  // Both words must be non-stop-words and reasonably sized to avoid code noise
  const allWords = text.replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/).filter(w => w.length > 1);
  const bigrams = [];
  for (let i = 0; i < allWords.length - 1; i++) {
    const w1 = allWords[i], w2 = allWords[i + 1];
    if (!stopWords.has(w1) && !stopWords.has(w2)
        && w1.length > 2 && w2.length > 2
        && w1.length < 25 && w2.length < 25) {
      bigrams.push(`${w1} ${w2}`);
    }
  }

  // Count frequency of single words and return top terms
  const freq = {};
  for (const w of words) {
    freq[w] = (freq[w] || 0) + 1;
  }

  const singleTerms = Object.entries(freq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .map(([word]) => word);

  // Count bigram frequency, pick top 5
  const bigramFreq = {};
  for (const bg of bigrams) {
    bigramFreq[bg] = (bigramFreq[bg] || 0) + 1;
  }
  const topBigrams = Object.entries(bigramFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([phrase]) => phrase);

  // Combine: domain phrases first (most specific), then bigrams, then single terms
  const combined = [...domainMatches, ...topBigrams, ...singleTerms];

  // Deduplicate while preserving order
  const seen = new Set();
  return combined.filter(term => {
    if (seen.has(term)) return false;
    seen.add(term);
    return true;
  }).slice(0, 12);
}

const VALID_COMPLEXITY = new Set(['Low', 'Medium', 'High', 'Very High']);
const VALID_VALUE = new Set(['Low', 'Medium', 'High', 'Critical']);
const VALID_RISK = new Set(['Low', 'Medium', 'High']);
const VALID_EFFORT = new Set(['XS', 'S', 'M', 'L', 'XL']);
const VALID_PATH = new Set(['Manual', 'Copilot-Assisted', 'Agentic']);
const VALID_CONFIDENCE = new Set(['High', 'Medium', 'Low']);
const VALID_ACTION = new Set(['Implement', 'Defer', 'Investigate', 'Reject']);

/**
 * Validate and coerce Phase 2 response structure and types.
 */
function validatePhase2Response(result) {
  if (!result.triage || typeof result.triage !== 'object') {
    throw new Error('Phase 2: Invalid response - missing triage object');
  }
  if (!result.enrichment || typeof result.enrichment !== 'object') {
    result.enrichment = {};
  }
  if (typeof result.executive_summary !== 'string') {
    result.executive_summary = String(result.executive_summary || 'No summary provided.');
  }

  const t = result.triage;

  // Validate rating fields: ensure object with rating and rationale strings
  function validateRatingField(field, validSet, defaultVal) {
    if (!t[field] || typeof t[field] !== 'object') {
      t[field] = { rating: defaultVal, rationale: 'No rationale provided' };
    }
    if (!validSet.has(t[field].rating)) {
      // Try case-insensitive match
      const match = [...validSet].find(v => v.toLowerCase() === String(t[field].rating).toLowerCase());
      t[field].rating = match || defaultVal;
    }
    if (typeof t[field].rationale !== 'string') {
      t[field].rationale = String(t[field].rationale || '');
    }
  }

  validateRatingField('complexity', VALID_COMPLEXITY, 'Medium');
  validateRatingField('value', VALID_VALUE, 'Medium');
  validateRatingField('risk', VALID_RISK, 'Medium');
  validateRatingField('effort', VALID_EFFORT, 'M');
  validateRatingField('implementation_path', VALID_PATH, 'Copilot-Assisted');
  validateRatingField('confidence', VALID_CONFIDENCE, 'Medium');

  // Validate priority_score: must have numeric score
  if (!t.priority_score || typeof t.priority_score !== 'object') {
    t.priority_score = { score: 5, rationale: 'Default score' };
  }
  if (typeof t.priority_score.score !== 'number') {
    const parsed = Number(t.priority_score.score);
    t.priority_score.score = isNaN(parsed) ? 5 : parsed;
  }
  t.priority_score.score = Math.max(1, Math.min(10, Math.round(t.priority_score.score)));
  if (typeof t.priority_score.rationale !== 'string') {
    t.priority_score.rationale = String(t.priority_score.rationale || '');
  }

  // Validate recommended_action
  if (!t.recommended_action || typeof t.recommended_action !== 'object') {
    t.recommended_action = { action: 'Investigate', rationale: 'No rationale provided' };
  }
  if (!VALID_ACTION.has(t.recommended_action.action)) {
    const match = [...VALID_ACTION].find(v => v.toLowerCase() === String(t.recommended_action.action).toLowerCase());
    t.recommended_action.action = match || 'Investigate';
  }
  if (typeof t.recommended_action.rationale !== 'string') {
    t.recommended_action.rationale = String(t.recommended_action.rationale || '');
  }

  // Validate enrichment arrays
  for (const field of ['documentation', 'ideas_portal', 'community', 'code_areas']) {
    if (!Array.isArray(result.enrichment[field])) {
      result.enrichment[field] = [];
    }
  }
}
