// Phase 2: Issue enrichment and triage assessment
// See: docs/features/issue-triage-agent/design.md (FR9-FR16, section 6.6)
//
// Splits the single monolithic LLM call into three focused calls:
//   2a. Code Analysis  — source code + domain knowledge → complexity, effort, risk, path, code_areas
//   2b. Signal Analysis — Ideas, ADO, community, marketplace → value, documentation, ideas_portal, community, ado
//   2c. Synthesis       — merges 2a + 2b + Phase 1 → priority, confidence, action, executive_summary
// Steps 2a and 2b run in parallel for latency; 2c runs sequentially after both complete.

import { readFileSync, existsSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { callGPT } from './models-client.js';
import { detectAppArea } from './config.js';
import { fetchCodeContext, formatCodeContext } from './code-reader.js';
import { fetchRelatedIdeas, formatIdeasContext } from './ideas-client.js';
import { fetchRelatedWorkItems, formatAdoContext } from './ado-client.js';
import { fetchMarketplaceApps, formatMarketplaceContext } from './marketplace-client.js';
import { fetchCommunityDiscussions, formatCommunityContext } from './community-client.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Maps detected app area names to area-specific knowledge files. */
const AREA_KNOWLEDGE_MAP = {
  'BaseApp - Finance': 'finance.md',
  'BaseApp - Financial Management': 'finance.md',
  'BaseApp - Purchases': 'purchasing.md',
  'BaseApp - Sales': 'sales.md',
  'BaseApp - Inventory': 'inventory.md',
  'BaseApp - Warehouse': 'warehouse.md',
  'BaseApp - Manufacturing': 'manufacturing.md',
  'BaseApp - Assembly': 'manufacturing.md',
  'E-Document': 'e-document.md',
  'E-Document Connectors': 'e-document.md',
  'PEPPOL': 'e-document.md',
  'BaseApp - Integration': 'integration.md',
  'System Application': 'integration.md',
  'Shopify': 'integration.md',
  'BaseApp - Fixed Assets': 'finance.md',
  'BaseApp - Cost Accounting': 'finance.md',
  'BaseApp - Bank': 'finance.md',
  'BaseApp - Cash Flow': 'finance.md',
  'Subscription Billing': 'finance.md',
  'BaseApp - Service': 'sales.md',
  'BaseApp - CRM': 'sales.md',
  'BaseApp - Projects': 'finance.md',
  'Pricing': 'sales.md',
};

// ─── Shared helpers ───

function loadSkillFiles() {
  const repoRoot = join(__dirname, '..', '..', '..');
  const skillDir = join(repoRoot, 'plugins', 'triage', 'skills', 'triage');
  const glossary = readFileSync(join(skillDir, 'SKILL.md'), 'utf-8')
    .replace(/^---[\s\S]*?---\n/, '')
    .match(/## BC\/AL Domain Glossary[\s\S]*?(?=## Triage Process Overview)/)?.[0] || '';
  const enrichKnowledge = readFileSync(join(skillDir, 'triage-enrich.md'), 'utf-8');
  return { skillDir, glossary, enrichKnowledge };
}

function loadDomainContext(skillDir, appArea) {
  const areaKnowledgeFile = AREA_KNOWLEDGE_MAP[appArea.name];
  if (areaKnowledgeFile) {
    const areaKnowledgePath = join(skillDir, 'area-knowledge', areaKnowledgeFile);
    try {
      if (existsSync(areaKnowledgePath)) {
        console.log(`Phase 2: Using area-specific knowledge for ${appArea.name}`);
        return `## Domain knowledge: ${appArea.name}\n\n${readFileSync(areaKnowledgePath, 'utf-8')}`;
      }
    } catch { /* fall through */ }
  }
  console.log(`Phase 2: Using general domain knowledge`);
  return readFileSync(join(skillDir, 'bc-domain.md'), 'utf-8');
}

function formatIssueBlock(issue) {
  const maxBodyChars = 6000;
  const issueBody = (issue.body || '(empty)').length > maxBodyChars
    ? issue.body.substring(0, maxBodyChars) + '\n... (truncated)'
    : (issue.body || '(empty)');

  const maxCommentChars = 2000;
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

  return { issueBody, commentsBlock };
}

// ─── Step 2a: Code Analysis ───

function buildCodeAnalysisPrompt(glossary, domainContext, enrichKnowledge) {
  return `You are a senior AL developer analyzing the source code impact of a GitHub issue for a Microsoft Dynamics 365 Business Central application repository.

Your job is to deeply analyze the provided source code and assess the technical dimensions of implementing this change. Focus exclusively on the code — what needs to change, how complex the change is, what risks exist, and how much effort it will take.

${glossary}

${domainContext}

## BC-Specific Risk Awareness

- **Posting routine changes** are always high-risk (affect ledger integrity)
- **Dimension-related changes** often have wide impact across all document types
- **Event signature changes** are breaking changes (API contract violation)
- **FlowField CalcFormula changes** can have performance implications
- **Table schema changes** require upgrade codeunits (adds significant effort)
- **Test coverage** matters most for posting routines and financial calculations

## Assessment criteria

### Complexity (Low / Medium / High / Very High)
- **Low**: Simple configuration change, documentation fix, or single-file change with clear pattern
- **Medium**: Multi-file change following existing patterns, moderate testing needed
- **High**: Architectural changes, new integration points, or cross-module impact
- **Very High**: Fundamental design changes, breaking changes, or novel technical challenges

### Effort Estimate (XS / S / M / L / XL)
- **XS**: < 2 hours (typo fix, config change)
- **S**: 2-8 hours (single focused change with tests)
- **M**: 1-3 days (multi-file feature or complex bug fix)
- **L**: 1-2 weeks (significant feature or refactoring)
- **XL**: 2+ weeks (major feature, architectural change)

### Risk (Low / Medium / High)
- **Low**: Isolated change, good test coverage, no breaking changes
- **Medium**: Some integration points affected, moderate regression risk
- **High**: Wide-reaching changes, breaking change potential, affects critical paths

### Implementation Path (Manual / Copilot-Assisted / Agentic)
- **Manual**: Requires deep domain expertise, nuanced judgment, or novel architectural decisions
- **Copilot-Assisted**: Code changes follow existing patterns where AI can help with boilerplate
- **Agentic**: Well-defined scope with clear existing patterns — an AI agent could drive the full implementation

## Output format

Return a JSON object with this exact structure:
\`\`\`json
{
  "complexity": { "rating": "Medium", "rationale": "Explanation referencing specific AL objects" },
  "effort": { "rating": "M", "rationale": "Explanation with specific file/object references" },
  "risk": { "rating": "Low", "rationale": "Explanation of risk factors from the code" },
  "implementation_path": { "rating": "Copilot-Assisted", "rationale": "Explanation" },
  "code_areas": [
    { "path": "src/Apps/W1/...", "relevance": "Why this area needs modification" }
  ]
}
\`\`\`

Return ONLY valid JSON. No markdown fences, no explanation text outside the JSON.`;
}

// ─── Step 2b: Signal Analysis ───

function buildSignalAnalysisPrompt(glossary) {
  return `You are a senior product manager evaluating the business value and community demand for a GitHub issue in a Microsoft Dynamics 365 Business Central application repository.

Your job is to analyze external signals — Ideas Portal data, Azure DevOps work items, community discussions, AppSource marketplace data, and your knowledge of documentation — to assess the value and demand for this change. Focus exclusively on the business impact, not the code.

${glossary}

## Signal interpretation

### Documentation (Microsoft Learn)
Search your knowledge for relevant Business Central documentation from learn.microsoft.com. Focus on feature documentation, API documentation, known limitations, and configuration guides.
Provide actual URLs when confident they exist. Format: \`https://learn.microsoft.com/en-us/dynamics365/business-central/...\`

### Ideas Portal (experience.dynamics.com)
You will be provided with actual search results from the Dynamics 365 Ideas Portal. Use these to gauge community demand, check current status of related ideas, and incorporate high-vote ideas into your value assessment.

### Azure DevOps work items
You may be provided with related work items from the Dynamics SMB ADO project. Use these to identify if this issue is already tracked internally and factor existing work into your assessment.

### Community discussions
You will be provided with search results from DynamicsUser.net (a major BC community forum) and a search link for Microsoft Dynamics Community. Use these to gauge whether users are actively discussing this topic and what workarounds or solutions the community has found.

### AppSource Marketplace
You will be provided with search context from the Microsoft AppSource marketplace for Business Central apps. Use the number of related apps as a demand signal:
- **20+ related apps**: Strong ecosystem interest — improvements have high value
- **5-19 related apps**: Moderate interest — established demand
- **<5 related apps**: Niche area — could be an opportunity or low-demand capability

### Value (Low / Medium / High / Critical)
- **Low**: Nice-to-have, affects few users, minor convenience improvement
- **Medium**: Meaningful improvement for a segment of users, noticeable quality-of-life gain
- **High**: Significant business impact, affects many users, or addresses data integrity issues
- **Critical**: Data loss, security vulnerability, or blocks core business workflows

## Output format

Return a JSON object with this exact structure:
\`\`\`json
{
  "value": { "rating": "High", "rationale": "Explanation citing specific signals" },
  "documentation": [
    { "title": "Article title", "url": "https://...", "relevance": "Why this is relevant" }
  ],
  "ideas_portal": [
    { "title": "Idea title", "url": "https://experience.dynamics.com/...", "relevance": "Why this is relevant" }
  ],
  "community": [
    { "title": "Discussion title", "url": "https://...", "relevance": "Why this is relevant" }
  ],
  "ado_work_items": [
    { "id": 12345, "relevance": "Why this work item is relevant to the issue" }
  ]
}
\`\`\`

Return ONLY valid JSON. No markdown fences, no explanation text outside the JSON.`;
}

// ─── Step 2c: Synthesis ───

function buildSynthesisPrompt(enrichKnowledge) {
  return `You are a senior product manager synthesizing a final triage recommendation for a GitHub issue in a Microsoft Dynamics 365 Business Central repository.

You have been given:
1. A Phase 1 quality assessment of the issue
2. A code analysis with complexity, effort, risk, and implementation path assessments (from a separate code-focused analysis)
3. A signal analysis with value assessment, documentation, ideas, ADO items, and community data (from a separate signal-focused analysis)
4. Precedents — similar closed issues that may provide historical context

Your job is to integrate ALL of these into a final triage recommendation: priority score, confidence level, recommended action, and an executive summary.

${enrichKnowledge}

## Output format

Return a JSON object with this exact structure:
\`\`\`json
{
  "priority_score": { "score": 7, "rationale": "Calculation: (Value × Urgency) / (Effort × Risk) = X, normalized to Y/10" },
  "confidence": { "rating": "High", "rationale": "Explanation of what evidence supports or undermines confidence" },
  "recommended_action": { "action": "Implement", "rationale": "Explanation integrating code analysis and signal analysis" },
  "executive_summary": "2-3 sentence summary for a product manager who needs to make a quick decision."
}
\`\`\`

Return ONLY valid JSON. No markdown fences, no explanation text outside the JSON.`;
}

// ─── Main orchestrator ───

/**
 * Enrich the issue with external context and produce a triage assessment.
 * Takes the original issue and Phase 1 results as input.
 */
export async function enrichAndTriage(issue, phase1Result, precedents = []) {
  const { skillDir, glossary, enrichKnowledge } = loadSkillFiles();
  const appArea = detectAppArea(issue.title, issue.body);
  console.log(`Phase 2: Detected app area: ${appArea.name} (${appArea.directory})`);

  const domainContext = loadDomainContext(skillDir, appArea);

  // Use LLM-extracted search terms from Phase 1 (with regex fallback)
  const llmTerms = phase1Result.search_terms || [];
  const regexTerms = extractKeyTerms(issue.title, issue.body);
  const keyTerms = llmTerms.length >= 3 ? llmTerms : regexTerms;
  console.log(`Phase 2: Key terms (${llmTerms.length >= 3 ? 'LLM' : 'regex'}): [${keyTerms.join(', ')}]`);

  // Fetch all enrichment context in parallel
  console.log(`Phase 2: Fetching enrichment context (code, Ideas Portal, ADO, AppSource, Community)...`);
  const [codeContext, ideasResult, adoResult, marketplaceResult, communityResult] = await Promise.all([
    Promise.resolve(fetchCodeContext(appArea.directory, keyTerms)),
    fetchRelatedIdeas(keyTerms, issue.title),
    fetchRelatedWorkItems(keyTerms, issue.title),
    fetchMarketplaceApps(keyTerms),
    fetchCommunityDiscussions(keyTerms, issue.title),
  ]);

  console.log(`Phase 2: Code context: ${codeContext.relevantFiles?.length || 0} files from ${appArea.directory}`);
  console.log(`Phase 2: Ideas Portal: ${(ideasResult.activeIdeas?.length || 0)} active + ${(ideasResult.closedIdeas?.length || 0)} closed ideas`);
  console.log(`Phase 2: ADO: ${(adoResult.activeItems?.length || 0)} active + ${(adoResult.closedItems?.length || 0)} closed work items`);
  console.log(`Phase 2: AppSource: search terms "${marketplaceResult.searchTerms}" (LLM will estimate)`);
  console.log(`Phase 2: Community: ${communityResult.discussions?.length || 0} discussions`);

  const codeContextBlock = formatCodeContext(codeContext);
  const ideasContextBlock = formatIdeasContext(ideasResult);
  const adoContextBlock = formatAdoContext(adoResult);
  const marketplaceContextBlock = formatMarketplaceContext(marketplaceResult);
  const communityContextBlock = formatCommunityContext(communityResult);

  const { issueBody, commentsBlock } = formatIssueBlock(issue);

  // Format precedents block
  let precedentsBlock = '';
  if (precedents.length > 0) {
    precedentsBlock = `### Similar resolved issues\n\nThese closed issues had significant keyword overlap and may provide context:\n\n`;
    for (const p of precedents) {
      precedentsBlock += `- #${p.number}: ${p.title} (${p.state_reason}, ${p.similarity}% similarity)\n`;
    }
    precedentsBlock += `\n`;
  }

  const issueHeader = `## Issue #${issue.number}: ${issue.title}

### Issue body

${issueBody}

${commentsBlock}### Phase 1 assessment

- **Quality score**: ${phase1Result.quality_score.total}/100
- **Verdict**: ${phase1Result.verdict}
- **Issue type**: ${phase1Result.issue_type}
- **Summary**: ${phase1Result.summary}
- **Detected app area**: ${phase1Result.detected_app_area}`;

  // ── Step 2a + 2b: Run code analysis and signal analysis in parallel ──
  console.log(`Phase 2: Starting code analysis and signal analysis in parallel...`);

  const codeAnalysisPrompt = buildCodeAnalysisPrompt(glossary, domainContext, enrichKnowledge);
  const codeAnalysisMessage = `${issueHeader}

### App area directory: ${appArea.directory}

${codeContextBlock}

Analyze the source code above and assess complexity, effort, risk, and implementation path for this issue.`;

  const signalAnalysisPrompt = buildSignalAnalysisPrompt(glossary);
  const signalAnalysisMessage = `${issueHeader}

### Key search terms: ${keyTerms.join(', ')}

${ideasContextBlock}

${adoContextBlock}

${marketplaceContextBlock}

${communityContextBlock}

Analyze all provided external signals and assess the business value of this issue.`;

  const [codeAnalysis, signalAnalysis] = await Promise.all([
    callGPT(codeAnalysisPrompt, codeAnalysisMessage).then(r => {
      validateCodeAnalysis(r);
      console.log(`Phase 2a: Code analysis complete — Complexity: ${r.complexity.rating}, Effort: ${r.effort.rating}, Risk: ${r.risk.rating}`);
      return r;
    }),
    callGPT(signalAnalysisPrompt, signalAnalysisMessage).then(r => {
      validateSignalAnalysis(r);
      console.log(`Phase 2b: Signal analysis complete — Value: ${r.value.rating}`);
      return r;
    }),
  ]);

  // ── Step 2c: Synthesis ──
  console.log(`Phase 2c: Synthesizing final triage recommendation...`);

  const synthesisPrompt = buildSynthesisPrompt(enrichKnowledge);
  const synthesisMessage = `${issueHeader}

${precedentsBlock}### Code analysis results

- **Complexity**: ${codeAnalysis.complexity.rating} — ${codeAnalysis.complexity.rationale}
- **Effort**: ${codeAnalysis.effort.rating} — ${codeAnalysis.effort.rationale}
- **Risk**: ${codeAnalysis.risk.rating} — ${codeAnalysis.risk.rationale}
- **Implementation path**: ${codeAnalysis.implementation_path.rating} — ${codeAnalysis.implementation_path.rationale}
- **Code areas**: ${(codeAnalysis.code_areas || []).map(a => a.path).join(', ') || 'none identified'}

### Signal analysis results

- **Value**: ${signalAnalysis.value.rating} — ${signalAnalysis.value.rationale}
- **Ideas Portal matches**: ${(signalAnalysis.ideas_portal || []).length} relevant ideas found
- **ADO work items**: ${(signalAnalysis.ado_work_items || []).length} related items found
- **Community discussions**: ${(signalAnalysis.community || []).length} relevant discussions found
- **Documentation**: ${(signalAnalysis.documentation || []).length} relevant articles found

Synthesize the code analysis and signal analysis into a final triage recommendation.`;

  const synthesis = await callGPT(synthesisPrompt, synthesisMessage);
  validateSynthesis(synthesis);

  console.log(`Phase 2c: Synthesis complete — Priority ${synthesis.priority_score.score}/10, Action: ${synthesis.recommended_action.action}`);

  // ── Assemble final result in the same shape downstream consumers expect ──
  const result = {
    enrichment: {
      documentation: signalAnalysis.documentation || [],
      ideas_portal: signalAnalysis.ideas_portal || [],
      community: signalAnalysis.community || [],
      ado_work_items: signalAnalysis.ado_work_items || [],
      code_areas: codeAnalysis.code_areas || [],
    },
    triage: {
      complexity: codeAnalysis.complexity,
      value: signalAnalysis.value,
      risk: codeAnalysis.risk,
      effort: codeAnalysis.effort,
      implementation_path: codeAnalysis.implementation_path,
      priority_score: synthesis.priority_score,
      confidence: synthesis.confidence,
      recommended_action: synthesis.recommended_action,
    },
    executive_summary: synthesis.executive_summary,
  };

  // Validate the assembled result with the same checks as before
  validatePhase2Response(result);

  console.log(`Phase 2 complete: Priority ${result.triage.priority_score?.score}/10 - ${result.triage.recommended_action?.action}`);

  // Attach analyzed file metadata so the comment formatter can display it
  result.enrichment.analyzed_files = codeContext.relevantFiles.map(f => f.path);
  result.enrichment.analyzed_directory = codeContext.directory;

  // Merge LLM relevance explanations into the Ideas from the search
  const llmIdeaRelevance = new Map();
  for (const item of (result.enrichment.ideas_portal || [])) {
    if (item.title) {
      llmIdeaRelevance.set(item.title.toLowerCase(), item.relevance);
    }
  }
  result.enrichment.matched_ideas = [...(ideasResult.activeIdeas || []), ...(ideasResult.closedIdeas || [])].map(i => ({
    title: i.title, votes: i.votes, status: i.status, url: i.url,
    relevance: llmIdeaRelevance.get((i.title || '').toLowerCase()) || '',
  }));

  // Merge LLM relevance explanations into the ADO work items from the search
  const llmAdoRelevance = new Map();
  for (const item of (result.enrichment.ado_work_items || [])) {
    if (item.id && item.relevance) {
      llmAdoRelevance.set(item.id, item.relevance);
    }
  }
  result.enrichment.ado_work_items = [...(adoResult.activeItems || []), ...(adoResult.closedItems || [])].map(wi => ({
    ...wi,
    relevance: llmAdoRelevance.get(wi.id) || wi.matchReason,
  }));

  result.enrichment.marketplace = {
    searchTerms: marketplaceResult.searchTerms,
    searchUrl: marketplaceResult.searchUrl,
  };
  result.enrichment.precedents = precedents;

  // Merge LLM relevance explanations into community discussions from the search
  const llmCommunityRelevance = new Map();
  for (const item of (result.enrichment.community || [])) {
    if (item.title) {
      llmCommunityRelevance.set(item.title.toLowerCase(), item.relevance);
    }
  }
  result.enrichment.community_discussions = (communityResult.discussions || []).map(d => ({
    ...d,
    relevance: llmCommunityRelevance.get((d.title || '').toLowerCase()) || '',
  }));
  result.enrichment.community_search_url = communityResult.dynamicsCommunityUrl;

  return result;
}

// ─── Validation helpers ───

const VALID_COMPLEXITY = new Set(['Low', 'Medium', 'High', 'Very High']);
const VALID_VALUE = new Set(['Low', 'Medium', 'High', 'Critical']);
const VALID_RISK = new Set(['Low', 'Medium', 'High']);
const VALID_EFFORT = new Set(['XS', 'S', 'M', 'L', 'XL']);
const VALID_PATH = new Set(['Manual', 'Copilot-Assisted', 'Agentic']);
const VALID_CONFIDENCE = new Set(['High', 'Medium', 'Low']);
const VALID_ACTION = new Set(['Implement', 'Defer', 'Investigate', 'Reject']);

function coerceRating(obj, field, validSet, defaultVal) {
  if (!obj[field] || typeof obj[field] !== 'object') {
    obj[field] = { rating: defaultVal, rationale: 'No rationale provided' };
  }
  if (!validSet.has(obj[field].rating)) {
    const match = [...validSet].find(v => v.toLowerCase() === String(obj[field].rating).toLowerCase());
    obj[field].rating = match || defaultVal;
  }
  if (typeof obj[field].rationale !== 'string') {
    obj[field].rationale = String(obj[field].rationale || '');
  }
}

function validateCodeAnalysis(r) {
  if (!r || typeof r !== 'object') throw new Error('Phase 2a: Invalid code analysis response');
  coerceRating(r, 'complexity', VALID_COMPLEXITY, 'Medium');
  coerceRating(r, 'effort', VALID_EFFORT, 'M');
  coerceRating(r, 'risk', VALID_RISK, 'Medium');
  coerceRating(r, 'implementation_path', VALID_PATH, 'Copilot-Assisted');
  if (!Array.isArray(r.code_areas)) r.code_areas = [];
}

function validateSignalAnalysis(r) {
  if (!r || typeof r !== 'object') throw new Error('Phase 2b: Invalid signal analysis response');
  coerceRating(r, 'value', VALID_VALUE, 'Medium');
  if (!Array.isArray(r.documentation)) r.documentation = [];
  if (!Array.isArray(r.ideas_portal)) r.ideas_portal = [];
  if (!Array.isArray(r.community)) r.community = [];
  if (!Array.isArray(r.ado_work_items)) r.ado_work_items = [];
}

function validateSynthesis(r) {
  if (!r || typeof r !== 'object') throw new Error('Phase 2c: Invalid synthesis response');

  // priority_score
  if (!r.priority_score || typeof r.priority_score !== 'object') {
    r.priority_score = { score: 5, rationale: 'Default score' };
  }
  if (typeof r.priority_score.score !== 'number') {
    const parsed = Number(r.priority_score.score);
    r.priority_score.score = isNaN(parsed) ? 5 : parsed;
  }
  r.priority_score.score = Math.max(1, Math.min(10, Math.round(r.priority_score.score)));
  if (typeof r.priority_score.rationale !== 'string') {
    r.priority_score.rationale = String(r.priority_score.rationale || '');
  }

  // confidence
  coerceRating(r, 'confidence', VALID_CONFIDENCE, 'Medium');

  // recommended_action
  if (!r.recommended_action || typeof r.recommended_action !== 'object') {
    r.recommended_action = { action: 'Investigate', rationale: 'No rationale provided' };
  }
  if (!VALID_ACTION.has(r.recommended_action.action)) {
    const match = [...VALID_ACTION].find(v => v.toLowerCase() === String(r.recommended_action.action).toLowerCase());
    r.recommended_action.action = match || 'Investigate';
  }
  if (typeof r.recommended_action.rationale !== 'string') {
    r.recommended_action.rationale = String(r.recommended_action.rationale || '');
  }

  // executive_summary
  if (typeof r.executive_summary !== 'string') {
    r.executive_summary = String(r.executive_summary || 'No summary provided.');
  }
}

/**
 * Validate and coerce the assembled Phase 2 response (same contract as before).
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
  coerceRating(t, 'complexity', VALID_COMPLEXITY, 'Medium');
  coerceRating(t, 'value', VALID_VALUE, 'Medium');
  coerceRating(t, 'risk', VALID_RISK, 'Medium');
  coerceRating(t, 'effort', VALID_EFFORT, 'M');
  coerceRating(t, 'implementation_path', VALID_PATH, 'Copilot-Assisted');
  coerceRating(t, 'confidence', VALID_CONFIDENCE, 'Medium');

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

  for (const field of ['documentation', 'ideas_portal', 'community', 'code_areas']) {
    if (!Array.isArray(result.enrichment[field])) {
      result.enrichment[field] = [];
    }
  }
}

// ─── Key term extraction (regex fallback when LLM terms unavailable) ───

// Known BC multi-word terms that should be kept intact during extraction.
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
  'service order', 'service item', 'service contract', 'service document', 'service documents',
  'service management', 'service price', 'service line',
  'approval workflow', 'approval entry', 'approval request',
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
const SORTED_PHRASES = [...BC_DOMAIN_PHRASES].sort((a, b) => b.length - a.length);

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
    'procedure', 'var', 'begin', 'end', 'local', 'trigger', 'true', 'false',
    'then', 'else', 'exit', 'repeat', 'until', 'case', 'with', 'rec',
    'text', 'integer', 'boolean', 'decimal', 'guid', 'enum', 'interface',
    'try', 'catch', 'throw', 'return', 'call', 'method', 'parameter',
    'log', 'logging', 'message', 'result', 'response', 'context',
    'init', 'setup', 'handler', 'helper', 'util', 'utils',
    'file', 'files', 'path', 'string', 'object', 'class', 'module',
    'something', 'anything', 'everything', 'nothing', 'thing', 'things',
    'however', 'therefore', 'instead', 'already', 'currently', 'actually',
    'basically', 'simply', 'really', 'always', 'never', 'sometimes',
    'able', 'unable', 'possible', 'impossible', 'necessary', 'specific',
  ]);

  const domainMatches = [];
  for (const phrase of SORTED_PHRASES) {
    if (text.includes(phrase)) {
      domainMatches.push(phrase);
      if (domainMatches.length >= 5) break;
    }
  }

  const words = text
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.has(w));

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

  const freq = {};
  for (const w of words) {
    freq[w] = (freq[w] || 0) + 1;
  }

  const singleTerms = Object.entries(freq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .map(([word]) => word);

  const bigramFreq = {};
  for (const bg of bigrams) {
    bigramFreq[bg] = (bigramFreq[bg] || 0) + 1;
  }
  const topBigrams = Object.entries(bigramFreq)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([phrase]) => phrase);

  const titleCleaned = title.toLowerCase()
    .replace(/[^a-z0-9\s-]/g, ' ')
    .split(/\s+/)
    .filter(w => w.length > 2 && !stopWords.has(w))
    .join(' ')
    .trim();
  const titleTerms = titleCleaned.length > 5 ? [titleCleaned] : [];

  const combined = [...titleTerms, ...domainMatches, ...topBigrams, ...singleTerms];

  const seen = new Set();
  return combined.filter(term => {
    if (seen.has(term)) return false;
    seen.add(term);
    return true;
  }).slice(0, 12);
}
