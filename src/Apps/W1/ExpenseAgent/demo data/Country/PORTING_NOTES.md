# Expense Agent — Country Demo Data Consolidation Notes

This file catalogs the technical workarounds applied while porting the ten
per-country Expense Agent demo-data extensions into the consolidated
`Expense Agent Demo Data` (W1) extension.

## Rationale

The consolidated demo data extension must be installable on **any** BC
localization — it can only depend on:

- `Expense Agent (Preview)` (base app)
- `Contoso Coffee Demo Dataset` (base W1 Contoso Coffee)
- `Expense Agent Demo Data` (itself, framework layer)

It cannot add hard dependencies on `Contoso Coffee Demo Dataset (<CC>)` or on
any country localization pack (which would restrict installability to that
country only).

The original per-country apps (`ExpenseAgent_<CC>/demo data`) freely referenced
`Create <CC> GL Accounts` codeunits from `Contoso Coffee Demo Dataset (<CC>)`
and, in the ES case, the `Income Stmt. Bal. Acc.` field added by the ES
localization. Neither is available here.

**All data written on the target locale (numbers, names, categories,
income/balance flags, posting types, etc.) is byte-identical to the original
per-country app output.** The workarounds change *how* a value is looked up,
not *what* value is written.

## Data preservation

For every country, the following are copied verbatim from the original
`CreateExpenseGLAccount<CC>.Codeunit.al` / `ExpenseEventSubscriber<CC>.Codeunit.al`:

- G/L account numbers (`AddAccountForLocalization(name, number)`)
- G/L account names (`Label` values)
- Income/Balance flag
- G/L Account Category + SubCategory
- Account Type (Posting / Begin-Total / End-Total)
- Begin-Total / End-Total Totaling ranges (CA, NZ)
- General Posting Type
- Direct Posting / Reconciliation / Blocked flags
- Expense Posting Group account mappings (Refundable/Non-refundable/Prepayment/Rounding)
- Employee Posting Group mappings
- Categories / SubCategories / Rule Header / Rule Condition / Expense /
  Posted Expense Report data (labels, dates, amounts, vendors, participants)

---

## Judgment calls (per country)

### Pattern A — Inlined `Contoso Coffee (CC)` name-lookup labels

**Problem:** original per-country apps look up G/L accounts by name using
`Create <CC> GL Account.<AccountName>()` from `Contoso Coffee Demo Dataset (<CC>)`.
The consolidated extension cannot depend on the country ContosoCoffee.

**Workaround:** create a per-country `<CC> GL Account Names` codeunit that
duplicates the `Tok`/`Lbl` string constants verbatim. The base W1
`Create Expense G/L Account.FindGLAccountByName(...)` resolves the account by
name at runtime, so on a `<CC>`-loc install where the ContosoCoffee-`<CC>` pack
is installed, the returned account is identical to the original code path.

**Alternative rejected:** adding `Contoso Coffee Demo Dataset (<CC>)` as a
dependency of the consolidated extension → would make the extension only
installable on `<CC>` loc.

#### US
| # | Label | Value |
|---|-------|-------|
| 1 | `BusinessEntertainingDeductibleName` | `Business Entertaining, deductible` |
| 2 | `OtherIncidentalRevenueName` | `Other Incidental Revenue` |
| 3 | `OtherPrepaidExpensesAndAccruedIncomeName` | `Other prepaid expenses and accrued income` |
| 4 | `PayableInvoiceRoundingName` | `Payable Invoice Rounding` |
| 5 | `MiscExternalExpensesName` | `Misc. external expenses` |
| 6 | `OtherTravelExpensesName` | `Other travel expenses` |
| 7 | `RentalVehiclesName` | `Rental vehicles` |
| 8 | `AccountsPayableDomesticName` | `Accounts Payable, Domestic` |
| 9 | `OtherBankAccountsName` | `Other bank accounts ` (trailing space) |
| 10 | `SaleofResourcesName` | `Sale of Resources` |

- **Before (original US):** `Create US GL Account.OtherIncidentalRevenue()` and siblings — from `src/Apps/US/ContosoCoffeeDemoDatasetUS/app/DemoData/Finance/1.Setup Data/CreateUSGLAccount.Codeunit.al`.
- **After (ported):** [demo data/Country/US/USGLAccountNames.Codeunit.al](demo%20data/Country/US/USGLAccountNames.Codeunit.al) — codeunit 8220.
- **Used by:** [demo data/Country/US/USExpGLAccount.Codeunit.al](demo%20data/Country/US/USExpGLAccount.Codeunit.al), [demo data/Country/US/USExpPostingGrp.Codeunit.al](demo%20data/Country/US/USExpPostingGrp.Codeunit.al), [demo data/Country/US/USUpdEmpPostingGrp.Codeunit.al](demo%20data/Country/US/USUpdEmpPostingGrp.Codeunit.al), [demo data/Country/US/USPostedExpReport.Codeunit.al](demo%20data/Country/US/USPostedExpReport.Codeunit.al).

#### GB
| # | Label | Value |
|---|-------|-------|
| 1 | `BusinessEntertainingDeductibleName` | `Business Entertaining, deductible` |
| 2 | `OtherIncidentalRevenueName` | `Other Incidental Revenue` |
| 3 | `OtherPrepaidExpensesAndAccruedIncomeName` | `Other prepaid expenses and accrued income` |
| 4 | `PayableInvoiceRoundingName` | `Payable Invoice Rounding` |
| 5 | `MiscExternalExpensesName` | `Misc. external expenses` |
| 6 | `OtherTravelExpensesName` | `Other travel expenses` |
| 7 | `RentalVehiclesName` | `Rental vehicles` |
| 8 | `OtherBankAccountsName` | `Other bank accounts ` (trailing space) |
| 9 | `SaleofResourcesName` | `Sale of Resources` |

- **Before (original GB):** `Create UK GL Account.<Name>()` from `src/Apps/GB/ContosoCoffeeDemoDatasetGB/app/DemoData/Finance/1.Setup Data/CreateUKGLAccount.Codeunit.al` (or equivalent).
- **After (ported):** [demo data/Country/GB/GBGLAccountNames.Codeunit.al](demo%20data/Country/GB/GBGLAccountNames.Codeunit.al) — codeunit 8235.
- **Used by:** [demo data/Country/GB/GBExpGLAccount.Codeunit.al](demo%20data/Country/GB/GBExpGLAccount.Codeunit.al), [demo data/Country/GB/GBExpPostingGrp.Codeunit.al](demo%20data/Country/GB/GBExpPostingGrp.Codeunit.al), [demo data/Country/GB/GBPostedExpReport.Codeunit.al](demo%20data/Country/GB/GBPostedExpReport.Codeunit.al).

#### CA
Single label inlined directly in [demo data/Country/CA/CAUpdEmpPostingGrp.Codeunit.al#L33](demo%20data/Country/CA/CAUpdEmpPostingGrp.Codeunit.al#L33):

```al
BankCheckingLbl: Label 'Bank, Checking', MaxLength = 100;
```

- **Before (original CA):** `Create CA GL Account.BankCheckingName()` from `src/Apps/CA/ContosoCoffeeDemoDatasetCA/app/DemoData/Finance/1.Setup Data/CreateCAGLAccount.Codeunit.al`.
- **After (ported):** [demo data/Country/CA/CAUpdEmpPostingGrp.Codeunit.al#L28](demo%20data/Country/CA/CAUpdEmpPostingGrp.Codeunit.al#L28) uses `ExpenseGLAccount.FindGLAccountByName(BankCheckingLbl)`.

#### ES
| # | Label | Value |
|---|-------|-------|
| 1 | `OtherBusinessExpensesName` | `Other Business Expenses` |
| 2 | `RemunerationAdvancesName` | `Remuneration Advances` |
| 3 | `BanksEuroName` | `Banks Euro` |
| 4 | `InternalResourcesName` | `Internal Resources` |
| 5 | `ProfitOrLossName` | `Profit or Loss` |

- **Before (original ES):** `Create ES GL Accounts.<Name>()` from `src/Apps/ES/ContosoCoffeeDemoDatasetES/app/DemoData/Finance/1.Setup Data/CreateESGLAccounts.Codeunit.al`.
- **After (ported):** [demo data/Country/ES/ESGLAccountNames.Codeunit.al](demo%20data/Country/ES/ESGLAccountNames.Codeunit.al) — codeunit 8276.
- **Used by:** [demo data/Country/ES/ESExpGLAccount.Codeunit.al](demo%20data/Country/ES/ESExpGLAccount.Codeunit.al), [demo data/Country/ES/ESExpPostingGrp.Codeunit.al](demo%20data/Country/ES/ESExpPostingGrp.Codeunit.al), [demo data/Country/ES/ESUpdEmployee.Codeunit.al](demo%20data/Country/ES/ESUpdEmployee.Codeunit.al), [demo data/Country/ES/ESUpdEmpPostingGrp.Codeunit.al](demo%20data/Country/ES/ESUpdEmpPostingGrp.Codeunit.al), [demo data/Country/ES/ESPostedExpReport.Codeunit.al](demo%20data/Country/ES/ESPostedExpReport.Codeunit.al).

#### DK
| # | Label | Value |
|---|-------|-------|
| 1 | `EntwinetobaccospiritsName` | `Ent., Wine / Tobacco / Spirits` |
| 2 | `PrepaymentsAccruedCostsName` | `Prepayments - Accrued Costs` |
| 3 | `CentdiscrepanciesName` | `Cent Discrepancies` |
| 4 | `RestaurantdiningName` | `Restaurant Dining` |
| 5 | `MileagerateName` | `Mileage Rate` |
| 6 | `TravelingtradefairsetcName` | `Traveling, Trade Fairs etc.` |
| 7 | `AccountsPayablePostingName` | `Accounts Payables` |
| 8 | `BankName` | `Bank` |
| 9 | `DomesticsalesofgoodsandservicesName` | `Domestic Sales of Goods and Services` |

- **Before (original DK):** `Create GL Acc. DK.<Name>()` from `src/Apps/DK/ContosoCoffeeDemoDatasetDK/app/DemoData/Finance/1.Setup Data/CreateGLAccDK.Codeunit.al`.
- **After (ported):** [demo data/Country/DK/DKGLAccountNames.Codeunit.al](demo%20data/Country/DK/DKGLAccountNames.Codeunit.al) — codeunit 8289.
- **Used by:** [demo data/Country/DK/DKExpGLAccount.Codeunit.al](demo%20data/Country/DK/DKExpGLAccount.Codeunit.al), [demo data/Country/DK/DKExpPostingGrp.Codeunit.al](demo%20data/Country/DK/DKExpPostingGrp.Codeunit.al), [demo data/Country/DK/DKUpdEmpPostingGrp.Codeunit.al](demo%20data/Country/DK/DKUpdEmpPostingGrp.Codeunit.al), [demo data/Country/DK/DKPostedExpReport.Codeunit.al](demo%20data/Country/DK/DKPostedExpReport.Codeunit.al).

#### NZ, AU
None. Both countries' original apps only reference base W1 Contoso Coffee names (`EmployeesPayableName`, `BankLCYName`, etc.) which are available via `Create G/L Account` in the base `Contoso Coffee Demo Dataset`.

#### FR
None (no ContosoCoffee-FR name-lookups). FR introduces three FR-unique local G/L accounts (`CompanyCreditCards=512900`, `ExpensePrepaymentAccount=486200`, `RentalCarExpenses=625130`) with local `Tok` labels declared inside [demo data/Country/FR/FRExpGLAccount.Codeunit.al](demo%20data/Country/FR/FRExpGLAccount.Codeunit.al) — same as the original per-country app's own local declarations.

#### DE
| # | Label | Value |
|---|-------|-------|
| 1 | `BusinessaccountOperatingDomesticName` | `Business account, Operating, Domestic` |
| 2 | `SaleofResourcesName` | `Sale of Resource` |
| 3 | `AssetsintheformofprepaidexpensesName` | `Assets in the form of prepaid expenses` |
| 4 | `SalesInvoiceRoundingName` | `Sales Invoice Rounding` |
| 5 | `BoardandlodgingName` | `Board and lodging` |
| 6 | `MiscexternalexpensesName` | `Misc. external expenses` |
| 7 | `OthertravelexpensesName` | `Other travel expenses` |
| 8 | `RentalvehiclesName` | `Rental vehicles` |
| 9 | `BusinessEntertainingdeductibleName` | `Business Entertaining, deductible` |

- **Before (original DE):** `Create DE GL Acc.<Name>()` from `src/Apps/DE/ContosoCoffeeDemoDatasetDE/app/DemoData/Finance/1.Setup data/CreateDEGLAcc.Codeunit.al`.
- **After (ported):** [demo data/Country/DE/DEGLAccountNames.Codeunit.al](demo%20data/Country/DE/DEGLAccountNames.Codeunit.al) — codeunit 8312.
- **Used by:** [demo data/Country/DE/DEExpPostingGrp.Codeunit.al](demo%20data/Country/DE/DEExpPostingGrp.Codeunit.al), [demo data/Country/DE/DEUpdEmpPostingGrp.Codeunit.al](demo%20data/Country/DE/DEUpdEmpPostingGrp.Codeunit.al), [demo data/Country/DE/DEPostedExpReport.Codeunit.al](demo%20data/Country/DE/DEPostedExpReport.Codeunit.al).

DE also introduces one DE-unique local G/L account (`CompanyCreditCardsClearingAccount=3510`, label `'Company credit card clearing account'`) declared inside [demo data/Country/DE/DEExpGLAccount.Codeunit.al](demo%20data/Country/DE/DEExpGLAccount.Codeunit.al) — same as the original per-country app's own local declaration.

#### AT
| # | Label | Value |
|---|-------|-------|
| 1 | `SettlementAccountCashBankName` | `Settlement account cash bank` |
| 2 | `SalesRevenuesResourcesExportName` | `Sales revenues resources export` |
| 3 | `TransportationThirdPartiesName` | `Transportation third parties` |
| 4 | `KilometerAllowanceName` | `Kilometer allowance` |
| 5 | `MealExpensesDomesticName` | `Meal expenses domestic` |
| 6 | `MealExpensesAbroadName` | `Meal expenses abroad` |
| 7 | `HospitalityDomesticDeductibleAmountName` | `Hospitality domestic deductible amount` |
| 8 | `OtherName` | `Other` |

- **Before (original AT):** `Create AT GL Account.<Name>()` from `src/Apps/AT/ContosoCoffeeDemoDatasetAT/app/DemoData/Finance/1. Setup Data/CreateATGLAccount.Codeunit.al`.
- **After (ported):** [demo data/Country/AT/ATGLAccountNames.Codeunit.al](demo%20data/Country/AT/ATGLAccountNames.Codeunit.al) — codeunit 8324.
- **Used by:** [demo data/Country/AT/ATExpPostingGrp.Codeunit.al](demo%20data/Country/AT/ATExpPostingGrp.Codeunit.al), [demo data/Country/AT/ATUpdEmpPostingGrp.Codeunit.al](demo%20data/Country/AT/ATUpdEmpPostingGrp.Codeunit.al), [demo data/Country/AT/ATPostedExpReport.Codeunit.al](demo%20data/Country/AT/ATPostedExpReport.Codeunit.al).

AT also introduces one AT-unique local G/L account (`CompanyCreditCardsClearingAccount=2830`, label `'Company credit card clearing account'`) declared inside [demo data/Country/AT/ATExpGLAccount.Codeunit.al](demo%20data/Country/AT/ATExpGLAccount.Codeunit.al) — same as the original per-country app's own local declaration.

### Pattern C — AT event subscribers bind/unbind gating

**Problem:** the original `ExpenseAgent_AT` app declared its
`OnDefineExpenseAccountNo` and `OnBeforeValidateCurrencyCodeInExpense`
subscribers as plain (non-Manual) event subscribers on
[AT Exp. Contoso Localization.Codeunit.al](../../../../AT/ExpenseAgent_AT/demo%20data/Demo%20Data/ATExpContosoLocalization.Codeunit.al) — safe because that app was only ever installed on the AT loc. In the
consolidated extension the same static registration would fire on every
locale, silently rewriting expense account numbers and currency codes for
non-AT companies.

**Workaround:** move both subscribers into Manual `SingleInstance` codeunits
([demo data/Country/AT/ATPostedExpReport.Codeunit.al](demo%20data/Country/AT/ATPostedExpReport.Codeunit.al) 8335 and [demo data/Country/AT/ATCurrencySwapSub.Codeunit.al](demo%20data/Country/AT/ATCurrencySwapSub.Codeunit.al) 8336) and let the AT orchestrator
[demo data/Country/AT/ATCountryData.Codeunit.al](demo%20data/Country/AT/ATCountryData.Codeunit.al) `BindSubscription` / `UnbindSubscription` them around `CreateHistoricalData`. Same technique used by FR and DE for their currency-swap and historical-account overrides.

### ID collision — 8333, 8334, 8347, 8348 reserved by System Application

The demo data extension's `idRanges` in [demo data/app.json](demo%20data/app.json) is `8201-8399`, but four codeunits inside that range are shipped by the base **System Application** and cannot be redefined here:

| ID | System Application object |
|---|---|
| 8333 | `VS Code Integration Impl.` |
| 8334 | `VS Code Integration` |
| 8347 | `Feature Configuration` |
| 8348 | `Feature Configuration Impl.` |

AT files that would naturally have received the next sequential IDs 8333/8334 were shifted to **8335 (`AT Posted Exp. Report`)** and **8336 (`AT Currency Swap Sub`)** for that reason.

---

### Pattern B — ES `"Income Stmt. Bal. Acc."` late-bound field write

**Problem:** the original `ExpenseAgent_ES` app strongly types
`GLAccount.Validate("Income Stmt. Bal. Acc.", <Account>)` on 11 G/L accounts.
That field is added to table `G/L Account` by the ES localization pack
(unavailable in W1). Adding a dep on that pack would restrict the whole
consolidated extension to ES loc.

**Before (original ES):**
`src/Apps/ES/ExpenseAgent_ES/demo data/Demo Data/1.Setup Data/CreateExpenseGLAccountES.Codeunit.al` line 78:
```al
GLAccount.Validate("Income Stmt. Bal. Acc.", IncomeStmtBalAcc);
```

**After (ported):** [demo data/Country/ES/ESExpGLAccount.Codeunit.al#L74-L96](demo%20data/Country/ES/ESExpGLAccount.Codeunit.al#L74-L96):
```al
local procedure UpdateIncomeStmtBalAcc(No: Code[20]; IncomeStmtBalAcc: Code[20])
var
    GLAccount: Record "G/L Account";
    RecRef: RecordRef;
    FieldRef: FieldRef;
    i: Integer;
begin
    // "Income Stmt. Bal. Acc." is added by the ES localization to table G/L Account.
    // Look it up dynamically via FieldRef so this demo data works without an ES-loc
    // compile-time dependency; silently skip when the field is not present.
    if not GLAccount.Get(No) then
        exit;

    RecRef.GetTable(GLAccount);
    for i := 1 to RecRef.FieldCount do begin
        FieldRef := RecRef.FieldIndex(i);
        if FieldRef.Name = 'Income Stmt. Bal. Acc.' then begin
            FieldRef.Validate(IncomeStmtBalAcc);
            RecRef.Modify();
            exit;
        end;
    end;
end;
```

**Behavior:**
- On an ES-loc install: the field is present, `FieldRef.Validate` fires,
  demo data written is byte-identical to the original.
- On a non-ES install: the loop completes without finding the field,
  `UpdateIncomeStmtBalAcc` no-ops. This is safe because on a non-ES install
  the country resolver returns something other than `ES` and this codepath
  is never reached anyway.

**Caveat:** field name comparison is against the English identifier
`'Income Stmt. Bal. Acc.'`. If a future BC build renames this field's
`Name` property (unlikely — captions are separate from names), this
lookup would miss and no `Income Stmt. Bal. Acc.` would be written.

---

## Countries with no judgment calls

Countries where the port is a pure 1:1 rename/renumber with no
technique changes:

- **NZ** ([demo data/Country/NZ/](demo%20data/Country/NZ/)): base W1 names only.
- **AU** ([demo data/Country/AU/](demo%20data/Country/AU/)): base W1 names only.
- **FR** ([demo data/Country/FR/](demo%20data/Country/FR/)): base W1 names only; three FR-local G/L accounts inlined verbatim from the original per-country app.

All ten countries ported.
