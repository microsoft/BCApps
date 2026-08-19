# Migrate existing Word report layouts to the composite document report structure

Splits the existing Word report layouts into **body-only layouts** that carry no header or footer of their own, and ships a set of **reusable header/footer designs and themes** that the platform merges onto them at render time. The old Word layouts stay in place and keep working; they are marked obsolete-pending so they can be removed in a later release.

168 files: 76 added, 92 modified.

## What the PR does

**1. A body-only Word layout per report.** Every migrated report gets a new `…Body.docx` layout declared with `Subtype = Body`, so the platform recognises it as the body of a composite document. **100 body layouts** across 46 reports and report extensions.

**2. The old Word layouts are marked obsolete-pending.** 149 layouts get `ObsoleteState = Pending` with `ObsoleteTag = '30.0'` and a reason pointing at the corresponding body layout. No layout is removed, and no `DefaultRenderingLayout` is changed, so existing tenants keep rendering exactly what they render today.

**3. Reusable header/footer designs and themes ship as app resources** under `src/Layers/W1/BaseApp/.resources/ReportParts/`:

- 12 header/footer designs — External Default, External Default Detailed, External Minimalistic, External Minimalistic Detailed, External Minimalist Detailed, External Modern, External Modern Logo, Internal Default, Internal Minimalistic, Internal Minimalistic Centered, Internal Modern, Internal Modern Maxi
- 3 themes — Default, Calm, Playful

They are read with `NavApp.GetResource`, so the binaries stay out of the AL source. Each design binds the report caption and the company metadata through `#BC:InsertDataItem` content controls.

**4. Three new codeunits in the Base Application:**

| Object | Purpose |
|---|---|
| Codeunit 9667 `Composite Report Parts Mgt.` | Seeds the shipped designs and themes into the shared pool (the platform's Tenant Report Defaults report, 2000000001) as approved, global parts. Re-runnable: a missing part is inserted, an existing one refreshed from the shipped file. |
| Codeunit 9668 `Composite Layout Assign. Mgt.` | Assigns a header/footer design to each body layout and the theme to every body layout, as layout-level `Tenant Report Layout Cfg` rows for all companies. Never overwrites an assignment that is already set. |
| Codeunit 104064 `Upgrade Composite Report Parts` | Re-seeds the parts on every upgrade so new parts appear and changed layout files take effect. |

**5. Install and upgrade seed only — they do not assign.** The platform validates every `Tenant Report Layout Cfg` row against the layout it names, and an error inside an install or upgrade trigger rolls back the whole publish. Seeding is therefore the only thing that runs automatically; the assignment is an explicit administrator action on the setup page.

**6. Changes to existing reporting objects:**

- **Page 9666 Report themes and header-footer setup** — new Publisher column (Microsoft for shipped parts, the publishing extension for parts from another app, Tenant-defined for uploaded ones), a new action *Assign default designs to report layouts* that runs the shipped assignment on demand, and a related action *Reports using this part* that opens the configuration list filtered on the selected part.
- **Page 9660 Report Layouts** — the subtype filter went from "only Default" to "not one of the part subtypes", so body layouts are listed instead of being hidden. The filter sits in `FilterGroup(2)` and could not be cleared from the UI.
- **Page 9667 Assign Theme and Header/Footer** — reads and writes the configuration row on the body layout's `<AppId>::<LayoutName>` reference.
- **Codeunit 9665 Composite Layout Lookup Helper** — resolves that reference, and filters the configuration table on the column that carries a part so a part's usage can be listed.

## Localizations changed

Localization layers declare their own versions of the sales documents and the reminder, so each one needs its own body layout. All of them follow the same pattern as W1: new `…Body.docx` layout with `Subtype = Body`, old Word layout marked obsolete-pending.

| Layer | Reports | New body layouts | Layouts marked obsolete |
|---|---|---|---|
| W1 | 36 | 44 | 57 |
| NA | 8 | 13 | 28 |
| ES | 6 | 12 | 20 |
| FR | 4 | 8 | 13 |
| NO | 3 | 6 | 10 |
| APAC | 2 | 2 | 2 |
| DACH | 1 | 1 | 1 |
| FI | 1 | 1 | 1 |
| GB | 1 | 1 | 1 |
| RU | 1 | 1 | 1 |

Per layer, the reports touched:

- **NA** — Standard Sales Invoice, Credit Memo, Quote, Draft Invoice, Order Confirmation, Standard Statement, Standard Purchase Order, Reminder
- **ES** — Standard Sales Invoice, Credit Memo, Quote, Draft Invoice, Order Confirmation, Reminder
- **FR** — Standard Sales Invoice, Credit Memo, Draft Invoice, Reminder
- **NO** — Standard Sales Invoice, Quote, Reminder
- **APAC** — Salesperson Sales Statistics, Reminder
- **DACH, FI, GB** — Reminder
- **RU** — Customer Order Summary

`DefaultRenderingLayout` is unchanged in every layer, RU included.

## Apps outside the layers

Four W1 apps declare report extensions or reports with their own Word layouts, and are migrated the same way.

| App | Object | New body layouts | Obsoleted |
|---|---|---|---|
| E-Document | `PostedSalesInvoiceWithQR.ReportExt` | 1 | 1 |
| E-Document | `PostedSalesCrdMemoWithQR.ReportExt` | 1 | 1 |
| E-Document | `EDocSamplePurchaseInvoice.Report` | 1 | 3 |
| Payment Practices | `PaymentPractice.Report` | 3 | 3 |
| Subscription Billing | `ContractStandardSalesInv.ReportExt` | 1 | 1 |
| Subscription Billing | `ContractSalesOrderConf.ReportExt` | 1 | 1 |
| Subscription Billing | `ContractStandardSalesQuote.ReportExt` | 1 | 1 |
| Sustainability | `SustStandardSalesInvoice.ReportExt` | 1 | 2 |
| Sustainability | `SustStandardSalesQuote.ReportExt` | 1 | 2 |

The body layout files live with their own app, not in the Base Application.

## Temporary code, marked for removal

The `Layout Name` key of `Tenant Report Layout Cfg` has to carry the owning application as `<AppId>::<LayoutName>`, because the table has no application ID field — its key is Report ID + Layout Name + Company Name. The platform will take over that resolution, so every site is marked:

```
grep -rn APPID-IN-LAYOUTNAME
```

Six sites in three objects (codeunits 9665 and 9668, page 9667). They have to be removed together: if one side writes the encoded form and another reads the plain name, the row is not found and the report renders without its parts.

## Not covered here

- No `DefaultRenderingLayout` is changed, so no tenant sees a different format for an existing report.
- No layout is deleted; the obsoletions are pending only.
- E-mail body layouts and label layouts get no header/footer, since they were never authored to carry one. They do get the theme, which is styling only.
