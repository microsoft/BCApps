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

const __dirname = dirname(fileURLToPath(import.meta.url));

/**
 * Enrich the issue with external context and produce a triage assessment.
 * Takes the original issue and Phase 1 results as input.
 */
export async function enrichAndTriage(issue, phase1Result) {
  const systemPrompt = readFileSync(
    join(__dirname, 'prompts', 'system-phase2.md'),
    'utf-8'
  );

  const appArea = detectAppArea(issue.title, issue.body);

  // Extract key terms for search context
  const keyTerms = extractKeyTerms(issue.title, issue.body);

  // Fetch actual source code from the repository
  const codeContext = fetchCodeContext(appArea.directory, keyTerms);
  const codeContextBlock = formatCodeContext(codeContext);

  // Fetch external context in parallel: Ideas Portal + ADO work items
  const [ideasResult, adoResult] = await Promise.all([
    fetchRelatedIdeas(keyTerms),
    fetchRelatedWorkItems(keyTerms),
  ]);
  const ideasContextBlock = formatIdeasContext(ideasResult);
  const adoContextBlock = formatAdoContext(adoResult);

  // Truncate very long issue bodies to avoid excessive token usage
  const maxBodyChars = 8000;
  const issueBody = (issue.body || '(empty)').length > maxBodyChars
    ? issue.body.substring(0, maxBodyChars) + '\n... (truncated)'
    : (issue.body || '(empty)');

  const userMessage = `## Issue #${issue.number}: ${issue.title}

### Issue body

${issueBody}

### Phase 1 assessment

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

Please analyze all provided context - source code structure, Ideas Portal matches, ADO work items, and your knowledge of documentation and community discussions.
Then provide your triage assessment as JSON.`;

  console.log(`Phase 2: Enriching and triaging issue #${issue.number}...`);
  const result = await callGPT(systemPrompt, userMessage);

  // Validate required fields
  if (!result.triage) {
    throw new Error('Phase 2: Invalid response - missing triage object');
  }
  if (!result.enrichment) {
    throw new Error('Phase 2: Invalid response - missing enrichment object');
  }
  if (!result.executive_summary) {
    throw new Error('Phase 2: Invalid response - missing executive_summary');
  }

  // Validate nested triage fields that index.js depends on
  const requiredTriageFields = ['complexity', 'value', 'risk', 'effort', 'implementation_path', 'priority_score', 'confidence', 'recommended_action'];
  for (const field of requiredTriageFields) {
    if (!result.triage[field]) {
      throw new Error(`Phase 2: Invalid response - missing triage.${field}`);
    }
  }

  console.log(`Phase 2 complete: Priority ${result.triage.priority_score?.score}/10 - ${result.triage.recommended_action?.action}`);

  // Attach analyzed file metadata so the comment formatter can display it
  if (!result.enrichment) result.enrichment = {};
  result.enrichment.analyzed_files = codeContext.relevantFiles.map(f => f.path);
  result.enrichment.analyzed_directory = codeContext.directory;
  result.enrichment.matched_ideas = ideasResult.ideas.map(i => ({
    title: i.title, votes: i.votes, status: i.status, url: i.url,
  }));
  result.enrichment.ado_work_items = adoResult.workItems;

  return result;
}

/**
 * Extract meaningful search terms from issue title and body.
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
  ]);

  const words = text
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.has(w));

  // Extract bigrams (two-word phrases) for more specific matching
  const allWords = text.replace(/[^a-z0-9\s-]/g, ' ').split(/\s+/).filter(w => w.length > 1);
  const bigrams = [];
  for (let i = 0; i < allWords.length - 1; i++) {
    const pair = `${allWords[i]} ${allWords[i + 1]}`;
    if (!stopWords.has(allWords[i]) || !stopWords.has(allWords[i + 1])) {
      bigrams.push(pair);
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

  // Count bigram frequency, pick top 3
  const bigramFreq = {};
  for (const bg of bigrams) {
    bigramFreq[bg] = (bigramFreq[bg] || 0) + 1;
  }
  const topBigrams = Object.entries(bigramFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([phrase]) => phrase);

  // Combine: bigrams first (more specific), then single terms
  const combined = [...topBigrams, ...singleTerms];

  // Deduplicate while preserving order
  const seen = new Set();
  return combined.filter(term => {
    if (seen.has(term)) return false;
    seen.add(term);
    return true;
  }).slice(0, 10);
}
