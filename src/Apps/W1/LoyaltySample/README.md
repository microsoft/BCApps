# Loyalty Sample

A small, self-contained loyalty-program module (members, point entries, a card/list
UI, API pages, a control add-in, install/upgrade codeunits, interfaces, events, and a
permission set).

It is intended as review-target sample code for exercising the Copilot PR review
end to end across **all** BCQuality review domains. The code deliberately contains
realistic mistakes — it is not meant to be shipped or to represent good practice.

## Domains exercised

Security, Privacy, Performance, Style, Accessibility (UI), Upgrade, Breaking Changes,
Error Handling, Events, Interfaces, and Web Services.

## Objects

| Object | ID | Purpose |
|---|---|---|
| `Loyalty Member` (table) | 50100 | Member master record |
| `Loyalty Point Entry` (table) | 50101 | Point ledger entries |
| `Loyalty Tier` (enum) | 50100 | Member tier |
| `Loyalty Channel` (enum) | 50101 | Notification channel (`implements INotificationSender`) |
| `INotificationSender` (interface) | — | Notification dispatch contract |
| `ILoyaltyTierPolicy` (interface) | — | Tier pricing/label contract |
| `Loyalty Management` (codeunit) | 50100 | Balance recalculation, gateway, telemetry |
| `Loyalty Upgrade` (codeunit) | 50101 | Per-company upgrade |
| `Loyalty Install` (codeunit) | 50102 | First-install setup |
| `Loyalty Email Sender` (codeunit) | 50103 | `INotificationSender` implementation |
| `Loyalty SMS Sender` (codeunit) | 50104 | `INotificationSender` implementation |
| `Loyalty Tier Pricing` (codeunit) | 50105 | Tier discount/label via `case` branching |
| `Loyalty Order Validator` (codeunit) | 50106 | Applies tier discount |
| `Loyalty Validation` (codeunit) | 50107 | Member/batch validation errors |
| `Loyalty Events` (codeunit) | 50108 | Integration-event publisher |
| `Loyalty Audit Subscriber` (codeunit) | 50109 | Event subscriber |
| `Loyalty Public Api` (codeunit) | 50110 | Public API surface |
| `Loyalty Member Card` (page) | 50100 | Member card |
| `Loyalty Member API` (page) | 50101 | OData API |
| `Loyalty Member List` (page) | 50102 | Member list |
| `Loyalty Member Data` (page) | 50103 | API endpoint |
| `Loyalty Badge` (controladdin) | — | Card badge widget |
| `Loyalty Full Access` (permissionset) | 50100 | Access to the module |
