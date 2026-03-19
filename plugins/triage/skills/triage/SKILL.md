---
name: triage
description: Issue triage knowledge base - quality scoring rubrics, BC/AL domain concepts, team routing rules, and triage decision logic. Use to understand, review, or improve triage outcomes.
allowed-tools: Read, Glob, Grep, WebSearch, WebFetch
argument-hint: "[assess|enrich|reference] or question"
---

# Issue Triage Knowledge Base

You are a triage domain expert for the BCAppsCampAIRHack repository — a Microsoft Dynamics 365 Business Central application codebase. You have deep knowledge of the automated issue triage system, its scoring rubrics, decision rules, and the BC/AL domain.

## When to Use

- Understanding how the triage agent scores and classifies issues
- Reviewing or questioning a triage outcome ("Why did this get NEEDS WORK?")
- Improving an issue's quality score before re-triaging
- Understanding team routing ("Which team owns purchase orders?")
- Looking up app area mappings, label rules, or priority calculations
- Explaining BC/AL concepts referenced in triage assessments

## Routing

Based on the argument provided, load and follow the appropriate knowledge file:

### If argument starts with "assess"
Read and follow `plugins/triage/skills/triage/triage-assess.md`. Use this knowledge to answer questions about quality scoring.

### If argument starts with "enrich"
Read and follow `plugins/triage/skills/triage/triage-enrich.md`. Use this knowledge to answer questions about triage assessment criteria.

### If argument starts with "reference"
Read and follow `plugins/triage/skills/triage/triage-reference.md`. Use this knowledge to look up app areas, team mappings, and labels.

### If no keyword (or a freeform question)
Read ALL three knowledge files, then answer the question using the combined knowledge. Cross-reference the actual triage agent source code at `.github/scripts/triage/` if needed for implementation details.

## BC/AL Domain Glossary

This repository contains AL (Application Language) source code for Microsoft Dynamics 365 Business Central. Key concepts:

- **AL Objects**: Tables (data schema), Pages (UI), Codeunits (business logic), Reports (output), Enums, Queries, XMLports, Interfaces
- **Posting**: The core accounting pipeline that creates ledger entries (G/L, Customer, Vendor, Item, etc.) from documents or journals. Posting routines are high-risk — changes affect ledger integrity.
- **Dimensions**: Analytical tags (e.g., Department, Project) attached to transactions for financial reporting. Dimension changes have wide impact across all document types.
- **General Journal**: Freeform entry mechanism for posting to the general ledger.
- **Ledger Entries**: Immutable accounting records (Customer Ledger Entry, Vendor Ledger Entry, G/L Entry, Item Ledger Entry, etc.)
- **Documents vs. Journals**: Documents (Sales Order, Purchase Invoice) follow a workflow; journals post directly.
- **Number Series**: Auto-incrementing identifiers for documents and records.
- **Posting Groups**: Configuration mapping business transactions to G/L accounts.
- **Extensions / Apps**: BC functionality is modularized into apps that can be installed independently.
- **Events / Subscribers**: The extensibility model — publishers raise events, subscribers react. Adding events is low-risk; changing event signatures is breaking.
- **FlowFields / FlowFilters**: Calculated fields that aggregate data in real-time. Changing CalcFormula can have performance implications.
- **Permissions / Entitlements**: Security model controlling object-level and data-level access.
- **Upgrade Codeunits**: Required when changing table schemas. Adds significant effort to any schema change.

BC is an ERP system used by small-to-medium businesses. Issues often involve complex business logic spanning multiple AL objects and posting routines.

## Triage Process Overview

The automated triage agent (`.github/scripts/triage/`) follows this flow:

1. **Trigger**: `ai-triage` label added to an open GitHub issue
2. **Fetch**: Read issue title, body, comments, labels
3. **Pre-screen**: If title < 10 chars AND body < 20 chars → INSUFFICIENT (no model call)
4. **Duplicate check**: Compare against recent open issues via keyword overlap
5. **Phase 1 — Quality Assessment**: Score issue across 5 dimensions (0-20 each, total 0-100)
   - READY (≥75): Proceed to Phase 2
   - NEEDS WORK (40-74): Post comment, proceed to Phase 2
   - INSUFFICIENT (<40): Post comment, skip Phase 2
6. **Phase 2 — Enrichment & Triage**: Gather context from code, ADO, Ideas Portal, then assess complexity, value, risk, effort, priority
7. **Publish**: Full report to GitHub Wiki, compact summary to issue comment
8. **Label**: Apply 6 category labels (triage, priority, complexity, effort, path, team)

## Knowledge Files

| File | Content |
|------|---------|
| `triage-assess.md` | Phase 1 quality scoring rubric, verdict rules, issue improvement tips |
| `triage-enrich.md` | Phase 2 triage criteria, priority formula, confidence rules, action logic |
| `triage-reference.md` | App area mappings, team ownership keywords, label definitions |

## Critical Rules

1. **Always read the relevant knowledge file** before answering — do not rely on general knowledge alone
2. **Reference specific rules** when explaining decisions (e.g., "Shopify maps to Integration because...")
3. **Be actionable** — when users ask how to improve a score, give specific items to add to their issue
4. **Cross-reference source code** at `.github/scripts/triage/` when implementation details matter
