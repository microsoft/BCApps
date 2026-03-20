# Payment Practices

Regulatory reporting app that calculates and reports payment time metrics
for vendors and customers. Required by jurisdictions like Sweden (250+
employees), UK, Australia (AUD 100M+ turnover) to protect smaller
businesses from late payments by measuring and disclosing how quickly
companies pay their invoices.

## Quick reference

- **32 objects:** 8 codeunits, 4 tables, 2 interfaces, 2 enums, 5 pages, 1 report (with 2 Word layouts), 8 permission objects
- **Object ID range:** 685-694
- **No dependencies** on other apps
- **Key metrics:** Average Agreed Payment Period, Average Actual Payment Period, % Paid on Time
- **On-time definition:** Payment Posting Date <= Due Date for closed invoices. Open invoices with past due count toward total but not toward actual payment time.
- **Exclusions:** Vendors/Customers can be excluded via "Exclude from Pmt. Practices" flag on master record

## How it works

The app uses a **strategy pattern** with two extensible dimensions:

1. **Header Type** (Vendor/Customer/Vendor+Customer) implements `PaymentPracticeDataGenerator` interface -- controls which ledger entries to extract
2. **Aggregation Type** (Period/Company Size) implements `PaymentPracticeLinesAggregator` interface -- controls how results are grouped

**Data pipeline:**

1. Create Header (report configuration + region-aware defaults)
2. Generate -- extract raw data from vendor/customer ledger entries
3. Calculate totals using `PaymentPracticeMath` (pure math codeunit, no side effects)
4. Aggregate into lines by Period or Size
5. Print report using Word layout

**Period aggregation** groups by Payment Period ranges (e.g., 0-30 days,
31-60 days). **Size aggregation** groups by vendor Company Size Code --
only works for vendor data, not customer.

## Structure

```
src/
  Core/
    PaymentPracticeHeader.Codeunit.al        -- orchestration
    PaymentPracticeMath.Codeunit.al          -- pure math (averages, %)
    VendorDataGenerator.Codeunit.al          -- vendor ledger extraction
    CustomerDataGenerator.Codeunit.al        -- customer ledger extraction
    VendorAndCustDataGenerator.Codeunit.al   -- combined extraction
    PeriodLinesAggregator.Codeunit.al        -- group by period range
    SizeLinesAggregator.Codeunit.al          -- group by company size
    InstallPaymentPractices.Codeunit.al      -- setup default periods
    PaymentPracticeDataGenerator.Interface.al
    PaymentPracticeLinesAggregator.Interface.al
    PaymentPracticeHeaderType.Enum.al        -- extensible
    PaymentPracticeAggregationType.Enum.al   -- extensible
    Permissions/                             -- 8 permission objects
  Tables/
    PaymentPeriod.Table.al                   -- config, region defaults
    PaymentPracticeHeader.Table.al           -- report config + summary
    PaymentPracticeLine.Table.al             -- aggregated results
    PaymentPracticeData.Table.al             -- raw ledger data
  Pages/                                     -- 5 pages
  Reports/
    PaymentPractices.Report.al               -- 2 Word layouts
```

## Documentation

Business logic and UI are straightforward -- the app is a reporting tool
with minimal configuration. See `InstallPaymentPractices.Codeunit.al` for
default Payment Period setup per region (GB, FR, AU/NZ, generic).

`OnBeforeSetupDefaults` integration event allows custom period setup for
new regions or business requirements.

## Things to know

- **Strategy pattern extensibility:** Add new Header Types or Aggregation Types by implementing the interfaces and extending the enums
- **Math isolation:** `PaymentPracticeMath` is pure functions -- no database access, no side effects. Easy to test and reuse.
- **Region-aware defaults:** Install codeunit creates different Payment Period ranges for GB, FR, AU/NZ, and a generic fallback
- **Two report layouts:** Period-based (default) and Vendor Size-based. Layout selection must match the Aggregation Type set on the header.
- **Size aggregation limits:** Company Size Code only exists on Vendor master records, so Size aggregation is not meaningful for Customer or Vendor+Customer reports
- **Open invoice handling:** Open invoices with Due Date in the past count toward total invoices but do not contribute to Average Actual Payment Period (no payment date yet)
- **Ledger entry filters:** Excludes prepayments, credit memos, finance charge memos, and reminders. Vendor/Customer exclusion flag is respected during data extraction.
