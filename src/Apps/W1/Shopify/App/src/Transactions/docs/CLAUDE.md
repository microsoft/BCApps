# Transactions

Imports order-level payment transactions from Shopify, maps payment gateways and credit card companies to BC payment methods, and supports suggesting Shopify payments in cash receipt journals.

## Quick reference

- **Entry point(s)**: `Codeunits/ShpfyTransactions.Codeunit.al`, `Codeunits/ShpfySuggestPayments.Codeunit.al`
- **Key patterns**: GraphQL-based data import, auto-creation of gateway/credit card company records, event subscribers for journal posting

## Structure

- Codeunits (2): Transactions (import logic), SuggestPayments (journal line event subscribers)
- Tables (5): OrderTransaction, PaymentMethodMapping, SuggestPayment, TransactionGateway, CreditCardCompany
- Table Extensions (2): CustLedgerEntry (adds Shpfy Transaction Id), GenJournalLine (adds Shpfy Transaction Id)
- Enums (2): TransactionStatus, TransactionType
- Pages (5): CreditCardCompanies, OrderTransactions, PaymentMethodsMapping, TransactionGateways, Transactions
- Page Extensions (1): CashReceiptJournal
- Reports (1): SuggestPayments

## Key concepts

- `UpdateTransactionInfos` fetches all transactions for an order via GraphQL and upserts them, auto-creating gateway and credit card company records as needed
- `PaymentMethodMapping` links a (Shop, Gateway, CreditCardCompany) tuple to a BC payment method code
- `SuggestPayments` codeunit hooks into general journal posting events to carry the Shopify Transaction Id through to customer ledger entries, and resets it on reversal
- Order transactions store both shop money and presentment money amounts, plus rounding amounts
- Each transaction captures a raw JSON snapshot via DataCapture for debugging
