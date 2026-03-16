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
  { keywords: ['copilot', 'ai', 'journal entry'], directory: 'src/Apps/W1/', name: 'General / AI' },
];

// Detect app area from issue text
export function detectAppArea(title, body) {
  const text = `${title} ${body}`.toLowerCase();
  for (const area of APP_AREAS) {
    if (area.keywords.some(kw => text.includes(kw))) {
      return area;
    }
  }

  // Fallback: scan all directories under src/ (2 levels deep) and match by name
  try {
    const repoRoot = process.env.GITHUB_WORKSPACE || join(process.cwd(), '..', '..', '..');
    const srcDir = join(repoRoot, 'src');
    const topDirs = readdirSync(srcDir, { withFileTypes: true })
      .filter(d => d.isDirectory() && !d.name.startsWith('.'));

    for (const topDir of topDirs) {
      const topPath = join(srcDir, topDir.name);
      // Check top-level name (e.g. "System Application", "Business Foundation")
      const topLower = topDir.name.toLowerCase();
      if (topLower.split(/\s+/).some(w => w.length > 3 && text.includes(w))) {
        return { keywords: [], directory: `src/${topDir.name}/`, name: topDir.name };
      }
      // Check second-level subdirectories
      try {
        const subDirs = readdirSync(topPath, { withFileTypes: true })
          .filter(d => d.isDirectory() && !d.name.startsWith('.'));
        for (const sub of subDirs) {
          const subLower = sub.name.toLowerCase().replace(/[^a-z0-9]/g, ' ');
          const subWords = subLower.split(/\s+/).filter(w => w.length > 3);
          if (subWords.some(word => text.includes(word))) {
            return { keywords: [], directory: `src/${topDir.name}/${sub.name}/`, name: sub.name };
          }
        }
      } catch { /* skip unreadable subdirectories */ }
    }
  } catch { /* directory listing not available */ }

  // Last resort: scan all of src/
  return { keywords: [], directory: 'src/', name: 'Unknown' };
}
