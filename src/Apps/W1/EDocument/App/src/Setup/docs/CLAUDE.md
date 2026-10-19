# Setup

Installation, upgrade, and consent management for the E-Document Core app. This module handles one-time setup tasks that run when the extension is first installed or upgraded to a new version.

## How it works

*Updated: 2026-07-29 -- Added the new upgrade actions for v2 Data Exchange definitions, process-draft enum migration, and purchase VAT defaults.*

**`EDocumentSetup`** (Install codeunit) runs `OnInstallAppPerCompany` and does two things: (1) creates the Workflow Table Relation records that link `E-Document` and `E-Document Service Status` tables bidirectionally by entry number -- this is required for the Workflow engine to navigate between the two tables during event processing; (2) registers four tables (`E-Document Log`, `E-Document Integration Log`, `E-Doc. Data Storage`, `E-Doc. Mapping Log`) with the Retention Policy framework so administrators can configure automatic cleanup of historical data.

**`EDocumentUpgrade`** runs on version upgrades. It still performs `UpgradeLogURLMaxLength`, which copies the old `URL` field to a new `"Request URL"` field on `E-Document Integration Log` using `DataTransfer` (bulk copy, no row-by-row loop). It now also imports the v2 PEPPOL invoice and credit memo Data Exchange definitions, migrates existing E-Documents from the old generic purchase-draft enum value to `Purchase Invoice` while the compatibility code is present, and enables the purchase E-Document VAT difference and VAT group resolution options in Purchases & Payables Setup.

**`ConsentManagerDefaultImpl`** implements the `IConsentManager` interface with a standard privacy consent dialog. When a user first configures an E-Document connector, this prompts them to acknowledge that third-party systems may have different compliance and privacy standards. Connector implementations can substitute their own consent manager via the interface.

## Things to know

*Updated: 2026-07-29 -- Listed the additional upgrade tags now registered per company.*

- The install codeunit uses `if Insert() then;` (swallow-failure pattern) for workflow table relations because the install runs on every upgrade, not just first install, and the records may already exist.
- Retention policies are created disabled by default (`Enabled = false`) with `"Apply to all records" = true`. Administrators must explicitly enable them and set retention periods.
- The upgrade tag format includes a work item number and date (`MS-540448-LogURLMaxLength-20240813`), following BC's standard upgrade tag conventions. Newer tags follow the same purpose-and-date style, for example `MS-EDoc-DataExchV2Defs-20260521` and `MS-EDoc-EnableVATOptionsForPurchEDoc-20260520`.
- `DataTransfer.CopyFields` is used instead of record-by-record modification for the URL migration -- this is significantly faster on large log tables.
- The consent text is a single hardcoded label. It does not vary by connector -- connectors that need specific consent language should implement their own `IConsentManager`.

See the [app-level CLAUDE.md](../../docs/CLAUDE.md) for broader architecture context.
