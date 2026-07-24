# Quality Management - Product Features

## Feature Overview

Quality Management enables systematic quality control by allowing companies to define what to inspect, when to inspect, and what to do with inspected inventory.

## Feature 1: Inspection Template Management

**What users do:** Create and maintain reusable inspection templates that define the structure of a quality inspection — what questions to ask, what tests to run, and what results are acceptable.

**Key objects:**
- Page: `Qlty. Inspection Template List` → `Qlty. Inspection Template Edit`
- Tables: `Qlty. Inspection Template Hdr.`, `Qlty. Inspection Template Line`, `Qlty. Test`, `Qlty. Test Lookup Value`

**Capabilities:**
- Define named tests with value types (numeric measurement, text, boolean pass/fail, lookup from list)
- Configure result options per template line (Pass/Fail/N/A with conditional behaviors)
- Set visibility and finish-allowed rules per result value
- Copy templates with `Qlty. Inspection - Copy Template` report
- Configure sample size source (fixed count, percentage of source quantity, etc.)

## Feature 2: Inspection Generation Rules

**What users do:** Configure when inspections should be automatically or manually triggered for specific source documents/records, and which template to use.

**Key objects:**
- Page: `Qlty. Inspection Gen. Rules`
- Table: `Qlty. Inspection Gen. Rule`
- Codeunit: `Qlty. Inspec. Gen. Rule Mgmt.`

**Capabilities:**
- Map source tables (Purchase Order, Transfer Order, Production Output, etc.) to templates
- Set filter criteria (by item, vendor, location, etc.) for rule matching
- Define trigger point (on release, on post, on receive, scheduled)
- Schedule inspections via job queue using `Schedule Group`
- Priority ordering via `Sort Order`
- Guided setup pages per module: `QltyRecGenRuleSGuide`, `QltyProdGenRuleSGuide`, `QltyAsmGenRuleSGuide`, `QltyWhseGenRuleSGuide`

## Feature 3: Quality Inspection Processing

**What users do:** Open, fill in, and finish quality inspections. Record measurements and test results against each template line.

**Key objects:**
- Page: `Qlty. Inspection` (card) + `Qlty. Inspection List`
- Tables: `Qlty. Inspection Header`, `Qlty. Inspection Line`
- Codeunit: `Qlty. Inspection - Create`

**Capabilities:**
- Create inspections manually or automatically from source documents
- Fill in test results on each inspection line
- Attach photos/documents via attachment integration
- Navigate back to source document
- Finish or re-open inspections
- Re-inspect: create follow-up inspection in a chain (linked by `Re-inspection No.`)
- View inspection status directly on source documents (transfer orders, lot/serial/package info cards)

## Feature 4: Source Configuration

**What users do:** Configure which fields from source tables (Purchase Line, Transfer Line, etc.) automatically populate inspection header fields (item no., quantity, location, lot, etc.).

**Key objects:**
- Page: `Qlty. Inspect. Source Config.`, `Qlty. Ins. Source Config. List`
- Tables: `Qlty. Inspect. Source Config.`, `Qlty. Inspect. Src. Fld. Conf.`
- Codeunit: `Qlty. Traversal`

**Capabilities:**
- Map any BC table's fields to inspection header fields
- Handle complex document/line relationships via traversal logic
- Auto-configure common source tables with `QltyAutoConfigure` codeunit

## Feature 5: Disposition Actions

**What users do:** After finishing an inspection (especially a failed one), take action on the inspected inventory.

**Key objects:**
- Interface: `IQltyDisposition`
- Pages: Triggered from inspection card
- Reports: `QltyCreateTransferOrder`, `QltyCreatePurchaseReturn`, `QltyCreateNegativeAdjmt`, `QltyMoveInventory`, `QltyCreateInternalPutaway`, `QltyChangeItemTracking`

**Available dispositions:**
- Transfer inventory to another location/bin
- Create warehouse or internal put-away
- Create purchase return order
- Post negative inventory adjustment
- Change item tracking (lot/serial/package reassignment)
- Move via reclassification journal or movement worksheet

## Feature 6: Item Tracking Integration

**What users do:** Inspect inventory tracked by lot, serial, or package numbers. Block or unblock item tracking entries based on inspection results.

**Key objects:**
- Codeunit: `Qlty. Item Tracking Mgmt.`, `Qlty. Tracking Integration`
- Table extensions: `QltyLotNoInformation`, `QltySerialNoInformation`, `QltyPackageNoInformation`
- Page extensions: Lot/Serial/Package info cards and lists

**Capabilities:**
- View inspection history from lot/serial/package info pages
- Automatically block item tracking entries when inspection fails (configurable in Setup)
- Unblock on re-inspection pass

## Feature 7: Workflow Approvals

**What users do:** Route inspections through an approval process before they can be finished.

**Key objects:**
- Codeunit: `Qlty. Workflow Setup`, `Qlty. Workflow Approvals`, `Qlty. Workflow Response`
- Page extension: `QltyWorkflowRespOptions`

**Capabilities:**
- Register quality inspection as a workflow-enabled document
- Set up approval chains using standard BC workflow engine
- Configure approval responses (approve, reject, delegate)

## Feature 8: Reporting

**Key reports:**
- `Qlty. Certificate of Analysis` - Formal inspection certificate (2 RDLC layouts: Default, Alternate)
- `Qlty. Non-Conformance` - Non-conformance report for failed inspections (2 RDLC layouts)
- `Qlty. General Purpose Inspection` - General inspection output (2 RDLC layouts)
- `Qlty. Create Inspection` - Batch create inspections from source records
- `Qlty. Schedule Inspection` - Job-queue triggered inspection creation

## Feature 9: API

**Key objects:**
- `Qlty. Inspections API` (page) - Query existing inspections
- `Qlty. Create Inspection API` (page) - Create inspections via API

## Feature 10: Quality Manager Role Center

**Key objects:**
- Profile: `Qlty. Manager`
- Page: `Qlty. Manager Role Center` + `Qlty. Inspection Activities` (cue group)
- Table: `Qlty. Management Role Center Cue`

Shows open/overdue/finished inspection counts and quick navigation to key lists.
