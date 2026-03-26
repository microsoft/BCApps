// Label definitions, scoring thresholds, and app area mappings
// See: docs/features/issue-triage-agent/design.md (FR7, FR19, FR22)

import { readdirSync } from 'fs';
import { join } from 'path';

export const MODEL_NAME = 'gpt-5.4';
export const MODEL_TEMPERATURE = 1;

// Quality score verdicts (FR7)
export const VERDICT = {
  READY: 'READY',
  NEEDS_WORK: 'NEEDS WORK',
  INSUFFICIENT: 'INSUFFICIENT',
};

export const SCORE_THRESHOLDS = {
  READY: 75,
  NEEDS_WORK: 40,
};

// Label definitions with colors (FR19)
export const LABELS = {
  triage: [
    { name: 'triage/ready', color: '0E8A16', description: 'Issue is well-specified and ready for development' },
    { name: 'triage/needs-info', color: 'FBCA04', description: 'Issue needs more information before development' },
    { name: 'triage/insufficient', color: 'E11D48', description: 'Issue lacks critical information' },
  ],
  priority: [
    { name: 'priority/critical', color: 'B60205', description: 'Priority score 9-10' },
    { name: 'priority/high', color: 'D93F0B', description: 'Priority score 7-8' },
    { name: 'priority/medium', color: 'F9D0C4', description: 'Priority score 4-6' },
    { name: 'priority/low', color: 'C2E0C6', description: 'Priority score 1-3' },
  ],
  complexity: [
    { name: 'complexity/low', color: 'BFD4F2', description: 'Low technical complexity' },
    { name: 'complexity/medium', color: 'D4C5F9', description: 'Medium technical complexity' },
    { name: 'complexity/high', color: '7057FF', description: 'High or very high technical complexity' },
  ],
  effort: [
    { name: 'effort/xs-s', color: 'E6F5D0', description: 'Extra-small or small effort estimate' },
    { name: 'effort/m', color: 'FEF2C0', description: 'Medium effort estimate' },
    { name: 'effort/l-xl', color: 'F9D0C4', description: 'Large or extra-large effort estimate' },
  ],
  path: [
    { name: 'path/manual', color: 'BFDADC', description: 'Best implemented manually' },
    { name: 'path/copilot-assisted', color: 'C5DEF5', description: 'Best implemented with Copilot assistance' },
    { name: 'path/agentic', color: 'D4C5F9', description: 'Can be fully implemented by an AI agent' },
  ],
  team: [
    { name: 'Finance', color: 'FBCA04', description: 'Owned by the Finance team' },
    { name: 'SCM', color: '0E8A16', description: 'Owned by the SCM (Supply Chain Management) team' },
    { name: 'Integration', color: 'C5DEF5', description: 'Owned by the Integration team' },
  ],
};

// Flatten all labels for easy iteration
export const ALL_LABELS = Object.values(LABELS).flat();

// Map triage verdict to label name
export function getTriageLabelName(verdict) {
  switch (verdict) {
    case VERDICT.READY: return 'triage/ready';
    case VERDICT.NEEDS_WORK: return 'triage/needs-info';
    case VERDICT.INSUFFICIENT: return 'triage/insufficient';
    default: return 'triage/needs-info';
  }
}

// Map priority score to label name
export function getPriorityLabelName(score) {
  if (score >= 9) return 'priority/critical';
  if (score >= 7) return 'priority/high';
  if (score >= 4) return 'priority/medium';
  return 'priority/low';
}

// Map complexity rating to label name
export function getComplexityLabelName(rating) {
  const r = rating.toLowerCase();
  if (r === 'low') return 'complexity/low';
  if (r === 'medium') return 'complexity/medium';
  return 'complexity/high';
}

// Map effort rating to label name
export function getEffortLabelName(rating) {
  const r = rating.toUpperCase();
  if (r === 'XS' || r === 'S') return 'effort/xs-s';
  if (r === 'M') return 'effort/m';
  return 'effort/l-xl';
}

// Map implementation path to label name
export function getPathLabelName(rating) {
  const r = rating.toLowerCase();
  if (r.includes('manual')) return 'path/manual';
  if (r.includes('agentic')) return 'path/agentic';
  return 'path/copilot-assisted';
}

// Map Phase 1 issue_type classification to a GitHub issue type name.
// GitHub issue types for this repo: Bug, Feature, Task.
export function getIssueTypeName(issueType) {
  const t = (issueType || '').toLowerCase();
  if (t === 'bug') return 'Bug';
  if (t === 'feature') return 'Feature';
  if (t === 'enhancement') return 'Feature';
  if (t === 'question') return 'Task';
  return 'Bug'; // default
}

// Team ownership mapping based on Dynamics SMB Ownership Matrix.
// Finance: financial application, accounting, tax, cash, fixed assets, sustainability, billing
// SCM: purchase, sales, inventory, warehouse, manufacturing, CRM, service mgmt, HR, projects
// Integration: system app, business foundation, APIs, Dataverse, e-documents, Shopify, migrations, onboarding
const FINANCE_KEYWORDS = [
  'finance', 'general ledger', 'general journal', 'dimension', 'posting group', 'budget',
  'account schedule', 'consolidation', 'deferral', 'analysis view', 'responsibility center',
  'intercompany', 'account categor',
  'fixed asset', 'insurance', 'maintenance', 'reclassification',
  'cash management', 'bank account', 'bank reconciliation', 'check writing', 'cash receipt',
  'payment registration', 'vendor payment', 'amc extension',
  'tax', 'vat', 'withholding', 'excise', 'india tax',
  'payable', 'vendor ledger', 'receivable', 'customer ledger', 'reminder', 'finance charge',
  'payroll', 'ceridian', 'yodlee', 'paypal',
  'cash flow', 'cost accounting',
  'company hub', 'multi-entity', 'master data management',
  'sustainability', 'ghg', 'emission', 'csrd', 'esg', 'cbam', 'eudr',
  'subscription billing', 'subscription', 'recurring billing', 'billing', 'recurring',
  'late payment prediction', 'copilot bank', 'copilot regulatory', 'copilot esg',
  'localization', 'regulatory', 'audit file', 'saf-t', 'fatturaPA', 'cfdi',
  'making tax digital', 'digipoort', 'elster', '1099', 'qr-bill',
  'power bi report', 'excel report',
];

const SCM_KEYWORDS = [
  'purchase', 'purchase order', 'purchase invoice', 'drop shipment', 'incoming document',
  'sales', 'sales order', 'sales invoice', 'shipping agent', 'sales return', 'sales price',
  'campaign pricing', 'salesperson',
  'inventory', 'stockkeeping', 'location transfer', 'item tracking', 'item charge',
  'cycle counting', 'standard cost', 'item budget', 'item substitution', 'nonstock',
  'project', 'job', 'resource',
  'service management', 'service order', 'service price', 'service item', 'service contract',
  'warehouse', 'pick', 'put away', 'put-away', 'bin', 'receipt', 'shipment', 'adcs',
  'manufacturing', 'assembly', 'production order', 'bill of material', 'bom',
  'work center', 'machine center', 'finite loading',
  'demand forecast', 'requisition', 'order promising', 'planning worksheet', 'inventory planning',
  'crm', 'contact management', 'opportunity', 'campaign management',
  'intrastat', 'human resource', 'employee ledger',
  'copilot marketing text', 'copilot sales line', 'sales order agent', 'image analysis',
  'subcontract', 'quality management', 'quality inspection',
];

const INTEGRATION_KEYWORDS = [
  'system application', 'business foundation', 'email module', 'word template', 'mail merge',
  'number series', 'no. series', 'source code', 'reason code', 'audit trail',
  'job queue', 'workflow', 'permission', 'entitlement',
  'company creation', 'create company',
  'data exchange', 'recommended app',
  'user management', 'license management', 'service plan',
  'm365', 'collaboration', 'teams integration',
  'dataverse', 'al proxy', 'dynamics 365 sales',
  'api', 'webhook', 'microsoft graph', 'odata',
  'feature management', 'data privacy', 'gdpr', 'printer',
  'retention policy', 'isolated storage',
  'migration', 'quickbooks', 'nav cloud', 'gp cloud',
  'ai foundation', 'ml model', 'openai',
  'e-document', 'peppol', 'tradeshift',
  'onboarding', 'welcome banner', 'checklist',
  'connectivity', 'currency lookup',
  'performance toolkit', 'demo tool',
  'shopify', 'data archive', 'data search',
];

// Authoritative mapping from detected app area name to owning team.
// When Phase 1 identifies a specific app area, this map is definitive —
// no keyword counting needed.
const APP_AREA_TEAM_MAP = {
  // Finance team
  'BaseApp - Finance': 'Finance',
  'BaseApp - Financial Management': 'Finance',
  'BaseApp - Fixed Assets': 'Finance',
  'BaseApp - Cost Accounting': 'Finance',
  'BaseApp - Bank': 'Finance',
  'BaseApp - Cash Flow': 'Finance',
  'BaseApp - Projects': 'Finance',
  'Subscription Billing': 'Finance',
  'Data Correction FA': 'Finance',
  'API Reports Finance': 'Finance',
  'Payment Practices': 'Finance',
  'UK Send Remittance Advice': 'Finance',
  'Power BI Reports': 'Finance',
  'Excel Reports': 'Finance',

  // SCM team
  'BaseApp - Sales': 'SCM',
  'BaseApp - Purchases': 'SCM',
  'BaseApp - Inventory': 'SCM',
  'BaseApp - Warehouse': 'SCM',
  'BaseApp - Manufacturing': 'SCM',
  'BaseApp - Assembly': 'SCM',
  'BaseApp - Service': 'SCM',
  'BaseApp - CRM': 'SCM',
  'BaseApp - Human Resources': 'SCM',
  'BaseApp - Invoicing': 'SCM',
  'Pricing': 'SCM',
  'Subcontracting': 'SCM',
  'Quality Management': 'SCM',
  'Simplified Bank Statement Import': 'SCM',

  // Integration team
  'System Application': 'Integration',
  'Business Foundation': 'Integration',
  'No. Series': 'Integration',
  'No. Series Copilot': 'Integration',
  'Audit Codes': 'Integration',
  'BaseApp - Integration': 'Integration',
  'BaseApp - Foundation': 'Integration',
  'BaseApp - eServices': 'Integration',
  'BaseApp - Role Centers': 'Integration',
  'Shopify': 'Integration',
  'E-Document': 'Integration',
  'E-Document Connectors': 'Integration',
  'PEPPOL': 'Integration',
  'Data Archive': 'Integration',
  'Data Search': 'Integration',
  'Error Messages with Recommendations': 'Integration',
  'Essential Business Headlines': 'Integration',
  'Transaction Storage': 'Integration',
  'AI Test Toolkit': 'Integration',
  'Performance Toolkit': 'Integration',
  'Test Framework': 'Integration',
  'General / AI': 'Integration',
  'External File Storage - Azure Blob': 'Integration',
  'External File Storage - Azure File': 'Integration',
  'External File Storage - SFTP': 'Integration',
  'External File Storage - SharePoint': 'Integration',
  'External Storage - Document Attachments': 'Integration',
  'Send to Email Printer': 'Integration',
  'BaseApp': 'Integration',
};

// Determine team label from issue text and detected app area.
// If a known app area name is provided (from Phase 1 LLM detection), use
// the authoritative map directly. Fall back to keyword scoring only when
// no app area was detected.
export function getTeamLabel(title, body, appAreaName) {
  // Authoritative: if the LLM detected a known app area, use the map
  if (appAreaName && appAreaName !== 'Unknown') {
    const team = APP_AREA_TEAM_MAP[appAreaName];
    if (team) return team;
  }

  // Fallback: keyword scoring for unknown or unmapped areas
  const text = `${title} ${body} ${appAreaName}`.toLowerCase();

  let financeScore = 0;
  let scmScore = 0;
  let integrationScore = 0;

  for (const kw of FINANCE_KEYWORDS) {
    if (text.includes(kw)) financeScore++;
  }
  for (const kw of SCM_KEYWORDS) {
    if (text.includes(kw)) scmScore++;
  }
  for (const kw of INTEGRATION_KEYWORDS) {
    if (text.includes(kw)) integrationScore++;
  }

  if (financeScore === 0 && scmScore === 0 && integrationScore === 0) {
    return 'Integration'; // default for unknown areas
  }

  if (financeScore >= scmScore && financeScore >= integrationScore) return 'Finance';
  if (scmScore >= integrationScore) return 'SCM';
  return 'Integration';
}

// App area keyword mappings (FR22)
export const APP_AREAS = [
  // Business Foundation
  { keywords: ['no. series', 'no series', 'number series', 'noseries'], directory: 'src/Business Foundation/App/NoSeries/', name: 'No. Series' },
  { keywords: ['no. series copilot', 'noseries copilot'], directory: 'src/Business Foundation/App/NoSeriesCopilot/', name: 'No. Series Copilot' },
  { keywords: ['audit code'], directory: 'src/Business Foundation/App/AuditCodes/', name: 'Audit Codes' },
  { keywords: ['business foundation', 'entitlement'], directory: 'src/Business Foundation/', name: 'Business Foundation' },

  // System Application
  { keywords: ['system application', 'sysapp'], directory: 'src/System Application/App/', name: 'System Application' },

  // Tools
  { keywords: ['ai test toolkit', 'test toolkit'], directory: 'src/Tools/AI Test Toolkit/', name: 'AI Test Toolkit' },
  { keywords: ['performance toolkit', 'perf toolkit'], directory: 'src/Tools/Performance Toolkit/', name: 'Performance Toolkit' },
  { keywords: ['test framework', 'test runner'], directory: 'src/Tools/Test Framework/', name: 'Test Framework' },

  // Apps/W1
  { keywords: ['shopify', 'shop', 'e-commerce', 'ecommerce'], directory: 'src/Apps/W1/Shopify/', name: 'Shopify' },
  { keywords: ['data archive', 'archive', 'retention', 'cleanup job'], directory: 'src/Apps/W1/DataArchive/', name: 'Data Archive' },
  { keywords: ['e-document', 'edocument', 'einvoice', 'e-invoice'], directory: 'src/Apps/W1/EDocument/', name: 'E-Document' },
  { keywords: ['edocument connector', 'e-document connector'], directory: 'src/Apps/W1/EDocumentConnectors/', name: 'E-Document Connectors' },
  { keywords: ['subscription', 'billing', 'recurring'], directory: 'src/Apps/W1/Subscription Billing/', name: 'Subscription Billing' },
  { keywords: ['quality', 'inspection', 'quality management'], directory: 'src/Apps/W1/Quality Management/', name: 'Quality Management' },
  { keywords: ['api report', 'finance report', 'api reports'], directory: 'src/Apps/W1/APIReportsFinance/', name: 'API Reports Finance' },
  { keywords: ['data correction', 'fixed asset', 'fa correction'], directory: 'src/Apps/W1/DataCorrectionFA/', name: 'Data Correction FA' },
  { keywords: ['data search', 'search'], directory: 'src/Apps/W1/DataSearch/', name: 'Data Search' },
  { keywords: ['error message', 'recommendation', 'error recommendation'], directory: 'src/Apps/W1/ErrorMessagesWithRecommendations/', name: 'Error Messages with Recommendations' },
  { keywords: ['headline', 'essential business'], directory: 'src/Apps/W1/EssentialBusinessHeadlines/', name: 'Essential Business Headlines' },
  { keywords: ['excel report', 'excel'], directory: 'src/Apps/W1/ExcelReports/', name: 'Excel Reports' },
  { keywords: ['azure blob', 'blob storage'], directory: 'src/Apps/W1/External File Storage - Azure Blob Service Connector/', name: 'External File Storage - Azure Blob' },
  { keywords: ['azure file', 'file service'], directory: 'src/Apps/W1/External File Storage - Azure File Service Connector/', name: 'External File Storage - Azure File' },
  { keywords: ['sftp', 'sftp connector'], directory: 'src/Apps/W1/External File Storage - SFTP Connector/', name: 'External File Storage - SFTP' },
  { keywords: ['sharepoint', 'sharepoint connector'], directory: 'src/Apps/W1/External File Storage - SharePoint Connector/', name: 'External File Storage - SharePoint' },
  { keywords: ['document attachment', 'external storage'], directory: 'src/Apps/W1/External Storage - Document Attachments/', name: 'External Storage - Document Attachments' },
  { keywords: ['payment practice', 'payment reporting'], directory: 'src/Apps/W1/PaymentPractices/', name: 'Payment Practices' },
  { keywords: ['peppol', 'bis 3'], directory: 'src/Apps/W1/PEPPOL/', name: 'PEPPOL' },
  { keywords: ['power bi', 'powerbi'], directory: 'src/Apps/W1/PowerBIReports/', name: 'Power BI Reports' },
  { keywords: ['email printer', 'send to email'], directory: 'src/Apps/W1/SendToEmailPrinter/', name: 'Send to Email Printer' },
  { keywords: ['bank statement', 'bank import'], directory: 'src/Apps/W1/SimplifiedBankStatementImport/', name: 'Simplified Bank Statement Import' },
  { keywords: ['subcontract', 'subcontracting'], directory: 'src/Apps/W1/Subcontracting/', name: 'Subcontracting' },
  { keywords: ['transaction storage'], directory: 'src/Apps/W1/TransactionStorage/', name: 'Transaction Storage' },
  { keywords: ['remittance', 'remittance advice'], directory: 'src/Apps/W1/UKSendRemittanceAdvice/', name: 'UK Send Remittance Advice' },
  // Layers/W1/BaseApp sub-areas
  { keywords: ['assembly', 'assembly order', 'assembly bom'], directory: 'src/Layers/W1/BaseApp/Assembly/', name: 'BaseApp - Assembly' },
  { keywords: ['bank', 'bank account', 'bank reconciliation', 'check writing', 'payment journal'], directory: 'src/Layers/W1/BaseApp/Bank/', name: 'BaseApp - Bank' },
  { keywords: ['cash flow', 'cash flow forecast'], directory: 'src/Layers/W1/BaseApp/CashFlow/', name: 'BaseApp - Cash Flow' },
  { keywords: ['cost accounting', 'cost type', 'cost center', 'cost object', 'cost budget'], directory: 'src/Layers/W1/BaseApp/CostAccounting/', name: 'BaseApp - Cost Accounting' },
  { keywords: ['crm', 'contact', 'opportunity', 'campaign', 'segment', 'interaction'], directory: 'src/Layers/W1/BaseApp/CRM/', name: 'BaseApp - CRM' },
  { keywords: ['eservice', 'e-service', 'online map'], directory: 'src/Layers/W1/BaseApp/eServices/', name: 'BaseApp - eServices' },
  { keywords: ['general ledger', 'general journal', 'chart of accounts', 'dimension', 'posting group', 'vat', 'deferral', 'consolidation', 'intercompany'], directory: 'src/Layers/W1/BaseApp/Finance/', name: 'BaseApp - Finance' },
  { keywords: ['financial management', 'financial report', 'account schedule', 'analysis view', 'budget'], directory: 'src/Layers/W1/BaseApp/FinancialMgt/', name: 'BaseApp - Financial Management' },
  { keywords: ['fixed asset', 'depreciation', 'insurance', 'maintenance', 'fa journal'], directory: 'src/Layers/W1/BaseApp/FixedAssets/', name: 'BaseApp - Fixed Assets' },
  { keywords: ['foundation', 'company information', 'no. series', 'source code', 'reason code', 'reporting', 'batch processing'], directory: 'src/Layers/W1/BaseApp/Foundation/', name: 'BaseApp - Foundation' },
  { keywords: ['human resource', 'employee', 'absence', 'employment contract'], directory: 'src/Layers/W1/BaseApp/HumanResources/', name: 'BaseApp - Human Resources' },
  { keywords: ['integration', 'dataverse', 'dynamics 365 sales', 'graph', 'api', 'data exchange'], directory: 'src/Layers/W1/BaseApp/Integration/', name: 'BaseApp - Integration' },
  { keywords: ['inventory', 'item', 'stockkeeping', 'item tracking', 'item charge', 'location', 'transfer'], directory: 'src/Layers/W1/BaseApp/Inventory/', name: 'BaseApp - Inventory' },
  { keywords: ['invoicing', 'invoice'], directory: 'src/Layers/W1/BaseApp/Invoicing/', name: 'BaseApp - Invoicing' },
  { keywords: ['manufacturing', 'production order', 'production bom', 'routing', 'work center', 'machine center', 'capacity'], directory: 'src/Layers/W1/BaseApp/Manufacturing/', name: 'BaseApp - Manufacturing' },
  { keywords: ['pricing', 'price list', 'sales price', 'purchase price', 'line discount', 'price calculation'], directory: 'src/Layers/W1/BaseApp/Pricing/', name: 'BaseApp - Pricing' },
  { keywords: ['project', 'job', 'resource', 'time sheet', 'job journal'], directory: 'src/Layers/W1/BaseApp/Projects/', name: 'BaseApp - Projects' },
  { keywords: ['purchase', 'purchase order', 'purchase invoice', 'vendor', 'payable'], directory: 'src/Layers/W1/BaseApp/Purchases/', name: 'BaseApp - Purchases' },
  { keywords: ['role center', 'rolecenter', 'cue', 'activity'], directory: 'src/Layers/W1/BaseApp/RoleCenters/', name: 'BaseApp - Role Centers' },
  { keywords: ['sales', 'sales order', 'sales invoice', 'customer', 'receivable', 'reminder', 'finance charge'], directory: 'src/Layers/W1/BaseApp/Sales/', name: 'BaseApp - Sales' },
  { keywords: ['service management', 'service order', 'service item', 'service contract', 'service price'], directory: 'src/Layers/W1/BaseApp/Service/', name: 'BaseApp - Service' },
  { keywords: ['warehouse', 'pick', 'put away', 'put-away', 'bin', 'warehouse receipt', 'warehouse shipment'], directory: 'src/Layers/W1/BaseApp/Warehouse/', name: 'BaseApp - Warehouse' },

  // BaseApp catch-all (must be after specific sub-areas)
  { keywords: ['base app', 'baseapp', 'base application'], directory: 'src/Layers/W1/BaseApp/', name: 'BaseApp' },

  { keywords: ['copilot', 'ai', 'journal entry'], directory: 'src/Apps/W1/', name: 'General / AI' },
];

// Cache for the fallback directory tree (built once, reused across calls)
let _directoryCache = null;

/**
 * Build a flat list of { directory, name, words } entries from the src/ tree.
 * Scans up to 2 levels deep, plus up to 4 levels for src/Layers/.
 */
function buildDirectoryCache() {
  if (_directoryCache) return _directoryCache;

  const entries = [];
  try {
    const repoRoot = process.env.GITHUB_WORKSPACE || join(process.cwd(), '..', '..', '..');
    const srcDir = join(repoRoot, 'src');
    const topDirs = readdirSync(srcDir, { withFileTypes: true })
      .filter(d => d.isDirectory() && !d.name.startsWith('.'));

    for (const topDir of topDirs) {
      const topPath = join(srcDir, topDir.name);
      const topWords = topDir.name.toLowerCase().split(/\s+/).filter(w => w.length > 3);
      entries.push({ directory: `src/${topDir.name}/`, name: topDir.name, words: topWords });

      try {
        const subDirs = readdirSync(topPath, { withFileTypes: true })
          .filter(d => d.isDirectory() && !d.name.startsWith('.'));
        for (const sub of subDirs) {
          const subWords = sub.name.toLowerCase().replace(/[^a-z0-9]/g, ' ').split(/\s+/).filter(w => w.length > 3);
          entries.push({ directory: `src/${topDir.name}/${sub.name}/`, name: sub.name, words: subWords });

          // For Layers: scan deeper (3rd and 4th level)
          if (topDir.name === 'Layers') {
            try {
              const thirdDirs = readdirSync(join(topPath, sub.name), { withFileTypes: true })
                .filter(d => d.isDirectory() && !d.name.startsWith('.'));
              for (const third of thirdDirs) {
                const thirdWords = third.name.toLowerCase().replace(/[^a-z0-9]/g, ' ').split(/\s+/).filter(w => w.length > 3);
                entries.push({ directory: `src/Layers/${sub.name}/${third.name}/`, name: third.name, words: thirdWords });
                try {
                  const fourthDirs = readdirSync(join(topPath, sub.name, third.name), { withFileTypes: true })
                    .filter(d => d.isDirectory() && !d.name.startsWith('.'));
                  for (const fourth of fourthDirs) {
                    const fourthWords = fourth.name.toLowerCase().replace(/[^a-z0-9]/g, ' ').split(/\s+/).filter(w => w.length > 3);
                    entries.push({ directory: `src/Layers/${sub.name}/${third.name}/${fourth.name}/`, name: `${third.name} - ${fourth.name}`, words: fourthWords });
                  }
                } catch { /* skip */ }
              }
            } catch { /* skip */ }
          }
        }
      } catch { /* skip */ }
    }
  } catch { /* directory listing not available */ }

  _directoryCache = entries;
  return entries;
}

// Detect app area from issue text
export function detectAppArea(title, body) {
  const text = `${title} ${body}`.toLowerCase();
  for (const area of APP_AREAS) {
    if (area.keywords.some(kw => text.includes(kw))) {
      return area;
    }
  }

  // Fallback: match against cached directory names
  const dirEntries = buildDirectoryCache();
  for (const entry of dirEntries) {
    if (entry.words.some(word => text.includes(word))) {
      return { keywords: [], directory: entry.directory, name: entry.name };
    }
  }

  // Last resort: scan all of src/
  return { keywords: [], directory: 'src/', name: 'Unknown' };
}
