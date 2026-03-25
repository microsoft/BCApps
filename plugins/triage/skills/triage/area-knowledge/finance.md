# Finance Domain Knowledge

## Chart of Accounts & G/L Posting

- The **Chart of Accounts** (T15) is the backbone of all financial reporting. Each G/L Account has an Account Category and Account Subcategory used by financial reports.
- **G/L Entries** (T17) are the ultimate destination of every posting. All sub-ledger entries (customer, vendor, item, FA) eventually create corresponding G/L entries.
- **General Journal Lines** (T81) are the intermediary — Codeunit 12 (Gen. Jnl.-Post Line) processes them into ledger entries.
- **Journal types**: General, Payment, Cash Receipt, Recurring, IC General. Each uses T81 but with different template/batch configurations.
- **Recurring Journals** support allocation methods: fixed, variable, and balance — commonly used for cost distribution and accruals.

## Dimensions — The #1 Source of Finance Issues

- **Default Dimensions** (T352) are set on master data with rules: Code Mandatory, Same Code, No Code, or blank.
- **Dimension Set Entries** (T480) store the actual dimension combinations. Every posting creates or reuses a dimension set via Codeunit 408 (Dimension Management).
- During posting, dimensions merge from: header defaults, line defaults, G/L account defaults, customer/vendor defaults, and item defaults. **Conflicts between these sources are the most common posting error users encounter.**
- **Dimension Combinations** (T350/T351) restrict which dimension values can pair together — these are checked during posting and often cause hard-to-diagnose errors.
- Any change to dimension logic has an extremely wide blast radius — it affects every document type that posts.

## VAT Calculation

- **VAT Posting Setup** (T325) defines rates per Business/Product group combination.
- Three calculation types: **Normal** (percentage), **Reverse Charge** (buyer pays VAT), **Full VAT** (entire amount is VAT).
- **VAT on prepayments** is a common edge case — the VAT must be calculated on the prepayment percentage, then adjusted when the final invoice posts.
- Multi-currency VAT requires converting at the VAT exchange rate, which may differ from the document exchange rate.
- **VAT Entries** (T254) link to G/L entries and are used for VAT returns. Corrections require reversal entries, not modifications.

## Entry Application

- **Applying entries** (payments to invoices, credits to debits) is managed by Codeunit 12 and Codeunit 226 (CustEntry-Apply Posted Entries) / Codeunit 227 (VendEntry-Apply Posted Entries).
- **Remaining Amount** on ledger entries tracks unapplied balances. Fully applied entries have Remaining Amount = 0.
- Applying across currencies triggers exchange rate adjustments via the **Adjust Exchange Rates** batch job.
- **Payment Discount** tolerance and **Payment Tolerance** add complexity — they allow slight underpayments to still close entries.

## Deferrals, Intercompany & Consolidation

- **Deferral Templates** (T1740) spread recognition over periods using straight-line, equal per period, or user-defined methods.
- **Intercompany** posting creates mirror documents in partner companies — the IC Inbox/Outbox mechanism handles this asynchronously.
- **Consolidation** aggregates data from business units, with dimension and account mapping between companies.

## High-Risk Areas

- **Codeunit 80** (Sales-Post), **Codeunit 81** (Sales-Post + Print), **Codeunit 12** (Gen. Jnl.-Post Line), **Codeunit 13** (Gen. Jnl.-Check Line) — changes here affect all financial posting.
- **Dimension Set logic** (Codeunit 408) — any modification can break posting across all modules.
- **Rounding in multi-currency** — the Invoice Rounding precision and currency rounding rules interact in complex ways.

## Common Issues

- Rounding differences when posting in foreign currencies with different LCY rounding precision
- VAT calculation errors on prepayment chains (prepayment invoice -> final invoice -> credit memo)
- Dimension conflicts between customer/vendor defaults and G/L account defaults during posting
- Bank reconciliation matching failures when statement amounts differ slightly from ledger entries
- Payment discount calculation when applying partial payments across multiple invoices
