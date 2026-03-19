# Triage Reference Data

Use this knowledge to look up app area mappings, team ownership rules, and label definitions.

## App Area Keyword Mappings

The triage agent detects which app area an issue relates to by matching keywords in the issue title and body. First match wins (order matters).

### Business Foundation
| App Area | Keywords | Directory |
|----------|----------|-----------|
| No. Series | no. series, no series, number series, noseries | `src/Business Foundation/App/NoSeries/` |
| No. Series Copilot | no. series copilot, noseries copilot | `src/Business Foundation/App/NoSeriesCopilot/` |
| Audit Codes | audit code | `src/Business Foundation/App/AuditCodes/` |
| Business Foundation | business foundation, entitlement | `src/Business Foundation/` |

### System Application
| App Area | Keywords | Directory |
|----------|----------|-----------|
| System Application | system application, sysapp | `src/System Application/App/` |

### Tools
| App Area | Keywords | Directory |
|----------|----------|-----------|
| AI Test Toolkit | ai test toolkit, test toolkit | `src/Tools/AI Test Toolkit/` |
| Performance Toolkit | performance toolkit, perf toolkit | `src/Tools/Performance Toolkit/` |
| Test Framework | test framework, test runner | `src/Tools/Test Framework/` |

### Apps/W1
| App Area | Keywords | Directory |
|----------|----------|-----------|
| Shopify | shopify, shop, e-commerce, ecommerce | `src/Apps/W1/Shopify/` |
| Data Archive | data archive, archive, retention, cleanup job | `src/Apps/W1/DataArchive/` |
| E-Document | e-document, edocument, einvoice, e-invoice | `src/Apps/W1/EDocument/` |
| E-Document Connectors | edocument connector, e-document connector | `src/Apps/W1/EDocumentConnectors/` |
| Subscription Billing | subscription, billing, recurring | `src/Apps/W1/Subscription Billing/` |
| Quality Management | quality, inspection, quality management | `src/Apps/W1/Quality Management/` |
| API Reports Finance | api report, finance report, api reports | `src/Apps/W1/APIReportsFinance/` |
| Data Correction FA | data correction, fixed asset, fa correction | `src/Apps/W1/DataCorrectionFA/` |
| Data Search | data search, search | `src/Apps/W1/DataSearch/` |
| Error Messages with Recommendations | error message, recommendation, error recommendation | `src/Apps/W1/ErrorMessagesWithRecommendations/` |
| Essential Business Headlines | headline, essential business | `src/Apps/W1/EssentialBusinessHeadlines/` |
| Excel Reports | excel report, excel | `src/Apps/W1/ExcelReports/` |
| External File Storage - Azure Blob | azure blob, blob storage | `src/Apps/W1/External File Storage - Azure Blob Service Connector/` |
| External File Storage - Azure File | azure file, file service | `src/Apps/W1/External File Storage - Azure File Service Connector/` |
| External File Storage - SFTP | sftp, sftp connector | `src/Apps/W1/External File Storage - SFTP Connector/` |
| External File Storage - SharePoint | sharepoint, sharepoint connector | `src/Apps/W1/External File Storage - SharePoint Connector/` |
| External Storage - Document Attachments | document attachment, external storage | `src/Apps/W1/External Storage - Document Attachments/` |
| Payment Practices | payment practice, payment reporting | `src/Apps/W1/PaymentPractices/` |
| PEPPOL | peppol, bis 3 | `src/Apps/W1/PEPPOL/` |
| Power BI Reports | power bi, powerbi | `src/Apps/W1/PowerBIReports/` |
| Send to Email Printer | email printer, send to email | `src/Apps/W1/SendToEmailPrinter/` |
| Simplified Bank Statement Import | bank statement, bank import | `src/Apps/W1/SimplifiedBankStatementImport/` |
| Subcontracting | subcontract, subcontracting | `src/Apps/W1/Subcontracting/` |
| Transaction Storage | transaction storage | `src/Apps/W1/TransactionStorage/` |
| UK Send Remittance Advice | remittance, remittance advice | `src/Apps/W1/UKSendRemittanceAdvice/` |

### Layers/W1/BaseApp Sub-areas
| App Area | Keywords | Directory |
|----------|----------|-----------|
| BaseApp - Assembly | assembly, assembly order, assembly bom | `src/Layers/W1/BaseApp/Assembly/` |
| BaseApp - Bank | bank, bank account, bank reconciliation, check writing, payment journal | `src/Layers/W1/BaseApp/Bank/` |
| BaseApp - Cash Flow | cash flow, cash flow forecast | `src/Layers/W1/BaseApp/CashFlow/` |
| BaseApp - Cost Accounting | cost accounting, cost type, cost center, cost object, cost budget | `src/Layers/W1/BaseApp/CostAccounting/` |
| BaseApp - CRM | crm, contact, opportunity, campaign, segment, interaction | `src/Layers/W1/BaseApp/CRM/` |
| BaseApp - eServices | eservice, e-service, online map | `src/Layers/W1/BaseApp/eServices/` |
| BaseApp - Finance | general ledger, general journal, chart of accounts, dimension, posting group, vat, deferral, consolidation, intercompany | `src/Layers/W1/BaseApp/Finance/` |
| BaseApp - Financial Management | financial management, financial report, account schedule, analysis view, budget | `src/Layers/W1/BaseApp/FinancialMgt/` |
| BaseApp - Fixed Assets | fixed asset, depreciation, insurance, maintenance, fa journal | `src/Layers/W1/BaseApp/FixedAssets/` |
| BaseApp - Foundation | foundation, company information, no. series, source code, reason code, reporting, batch processing | `src/Layers/W1/BaseApp/Foundation/` |
| BaseApp - Human Resources | human resource, employee, absence, employment contract | `src/Layers/W1/BaseApp/HumanResources/` |
| BaseApp - Integration | integration, dataverse, dynamics 365 sales, graph, api, data exchange | `src/Layers/W1/BaseApp/Integration/` |
| BaseApp - Inventory | inventory, item, stockkeeping, item tracking, item charge, location, transfer | `src/Layers/W1/BaseApp/Inventory/` |
| BaseApp - Invoicing | invoicing, invoice | `src/Layers/W1/BaseApp/Invoicing/` |
| BaseApp - Manufacturing | manufacturing, production order, production bom, routing, work center, machine center, capacity | `src/Layers/W1/BaseApp/Manufacturing/` |
| BaseApp - Pricing | pricing, price list, sales price, purchase price, line discount, price calculation | `src/Layers/W1/BaseApp/Pricing/` |
| BaseApp - Projects | project, job, resource, time sheet, job journal | `src/Layers/W1/BaseApp/Projects/` |
| BaseApp - Purchases | purchase, purchase order, purchase invoice, vendor, payable | `src/Layers/W1/BaseApp/Purchases/` |
| BaseApp - Role Centers | role center, rolecenter, cue, activity | `src/Layers/W1/BaseApp/RoleCenters/` |
| BaseApp - Sales | sales, sales order, sales invoice, customer, receivable, reminder, finance charge | `src/Layers/W1/BaseApp/Sales/` |
| BaseApp - Service | service management, service order, service item, service contract, service price | `src/Layers/W1/BaseApp/Service/` |
| BaseApp - Warehouse | warehouse, pick, put away, put-away, bin, warehouse receipt, warehouse shipment | `src/Layers/W1/BaseApp/Warehouse/` |
| BaseApp (catch-all) | base app, baseapp, base application | `src/Layers/W1/BaseApp/` |

### Catch-all
| App Area | Keywords | Directory |
|----------|----------|-----------|
| General / AI | copilot, ai, journal entry | `src/Apps/W1/` |

If no keyword matches, the agent falls back to scanning the actual directory structure for name matches.

## Team Ownership Mapping

Issues are routed to one of three teams based on keyword scoring. The agent counts keyword matches in the issue title + body + detected app area name, then assigns to the team with the highest count. Default (no matches) = Integration.

### Finance Team Keywords
`finance`, `general ledger`, `general journal`, `dimension`, `posting group`, `budget`, `account schedule`, `consolidation`, `deferral`, `analysis view`, `responsibility center`, `intercompany`, `account categor`, `fixed asset`, `insurance`, `maintenance`, `reclassification`, `cash management`, `bank account`, `bank reconciliation`, `check writing`, `cash receipt`, `payment registration`, `vendor payment`, `amc extension`, `tax`, `vat`, `withholding`, `excise`, `india tax`, `payable`, `vendor ledger`, `receivable`, `customer ledger`, `reminder`, `finance charge`, `payroll`, `ceridian`, `yodlee`, `paypal`, `cash flow`, `cost accounting`, `company hub`, `multi-entity`, `master data management`, `sustainability`, `ghg`, `emission`, `csrd`, `esg`, `cbam`, `eudr`, `subscription billing`, `recurring billing`, `late payment prediction`, `copilot bank`, `copilot regulatory`, `copilot esg`, `localization`, `regulatory`, `audit file`, `saf-t`, `fatturaPA`, `cfdi`, `making tax digital`, `digipoort`, `elster`, `1099`, `qr-bill`, `power bi report`, `excel report`

### SCM Team Keywords
`purchase`, `purchase order`, `purchase invoice`, `drop shipment`, `incoming document`, `sales`, `sales order`, `sales invoice`, `shipping agent`, `sales return`, `sales price`, `campaign pricing`, `salesperson`, `inventory`, `stockkeeping`, `location transfer`, `item tracking`, `item charge`, `cycle counting`, `standard cost`, `item budget`, `item substitution`, `nonstock`, `project`, `job`, `resource`, `service management`, `service order`, `service price`, `service item`, `service contract`, `warehouse`, `pick`, `put away`, `put-away`, `bin`, `receipt`, `shipment`, `adcs`, `manufacturing`, `assembly`, `production order`, `bill of material`, `bom`, `work center`, `machine center`, `finite loading`, `demand forecast`, `requisition`, `order promising`, `planning worksheet`, `inventory planning`, `crm`, `contact management`, `opportunity`, `campaign management`, `intrastat`, `human resource`, `employee ledger`, `copilot marketing text`, `copilot sales line`, `sales order agent`, `image analysis`, `subcontract`, `quality management`, `quality inspection`

### Integration Team Keywords
`system application`, `business foundation`, `email module`, `word template`, `mail merge`, `number series`, `no. series`, `source code`, `reason code`, `audit trail`, `job queue`, `workflow`, `permission`, `entitlement`, `company creation`, `create company`, `data exchange`, `recommended app`, `user management`, `license management`, `service plan`, `m365`, `collaboration`, `teams integration`, `dataverse`, `al proxy`, `dynamics 365 sales`, `api`, `webhook`, `microsoft graph`, `odata`, `feature management`, `data privacy`, `gdpr`, `printer`, `retention policy`, `isolated storage`, `migration`, `quickbooks`, `nav cloud`, `gp cloud`, `ai foundation`, `ml model`, `openai`, `e-document`, `peppol`, `tradeshift`, `onboarding`, `welcome banner`, `checklist`, `connectivity`, `currency lookup`, `performance toolkit`, `demo tool`, `shopify`, `data archive`, `data search`

### Team Assignment Algorithm
1. Count keyword matches for each team in: `(issue title) + (issue body) + (detected app area name)`
2. All counts zero → default to **Integration**
3. Otherwise → assign to team with highest count
4. Ties: Finance > SCM > Integration

## Label Definitions

### Triage Status Labels
| Label | Color | When Applied |
|-------|-------|-------------|
| `triage/ready` | #0E8A16 (green) | Quality score ≥ 75 |
| `triage/needs-info` | #FBCA04 (yellow) | Quality score 40-74 |
| `triage/insufficient` | #E11D48 (red) | Quality score < 40 |

### Priority Labels
| Label | Color | When Applied |
|-------|-------|-------------|
| `priority/critical` | #B60205 | Priority score 9-10 |
| `priority/high` | #D93F0B | Priority score 7-8 |
| `priority/medium` | #F9D0C4 | Priority score 4-6 |
| `priority/low` | #C2E0C6 | Priority score 1-3 |

### Complexity Labels
| Label | Color | When Applied |
|-------|-------|-------------|
| `complexity/low` | #BFD4F2 | Complexity = Low |
| `complexity/medium` | #D4C5F9 | Complexity = Medium |
| `complexity/high` | #7057FF | Complexity = High or Very High |

### Effort Labels
| Label | Color | When Applied |
|-------|-------|-------------|
| `effort/xs-s` | #E6F5D0 | Effort = XS or S |
| `effort/m` | #FEF2C0 | Effort = M |
| `effort/l-xl` | #F9D0C4 | Effort = L or XL |

### Implementation Path Labels
| Label | Color | When Applied |
|-------|-------|-------------|
| `path/manual` | #BFDADC | Path = Manual |
| `path/copilot-assisted` | #C5DEF5 | Path = Copilot-Assisted |
| `path/agentic` | #D4C5F9 | Path = Agentic |

### Team Labels
| Label | Color | Description |
|-------|-------|-------------|
| `Finance` | #FBCA04 | Owned by the Finance team |
| `SCM` | #0E8A16 | Owned by the Supply Chain Management team |
| `Integration` | #C5DEF5 | Owned by the Integration team |

### Label Management Rules
- Labels are mutually exclusive within each category (e.g., only one `priority/*` label at a time)
- When applying a new label, old labels in the same category are removed first
- Label colors and descriptions are auto-created if they don't exist on the repo
