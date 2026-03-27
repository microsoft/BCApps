# Essential Business Headlines

Displays newspaper-style business insight headlines on Role Center pages.
Shows dynamic messages like "Most popular item sold," "Largest sale amount,"
and "Recently overdue invoices" with drill-down detail.

## Quick reference

- **27 objects**: 3 codeunits, 2 tables, 3 queries, 1 page, 7 page extensions, 11 permissions
- **ID range**: 1-49999 allocation
- **No dependencies** -- extends base app Role Center pages only
- **9 headline types**: MostPopularItem, BusiestResource, LargestSale, LargestOrder, SalesIncrease, TopCustomer, OpenVATReturn, OverdueVATReturn, RecentlyOverdueInvoices
- **Role-based**: Business Manager (9 headlines), Order Processor (2), Accountant (3), Relationship Mgr (1)

## How it works

**Trigger**: Computation starts when a user opens a Role Center page. The
RC Headlines Executor raises OnComputeHeadlines event, which headline
computation codeunits subscribe to.

**Time-window strategy**: Headlines attempt to find data in 7-day window
first, then 30 days, then 90 days. First window with sufficient data is
used. If no window has enough data, headline is skipped.

**Data thresholds**: Require minimum data volume to show a headline --
3+ items/resources or 5+ orders/invoices. Prevents showing meaningless
results from sparse data.

**Caching**: Computed headlines stored per-user in "Ess. Business Headline
Per Usr" table (composite PK: HeadlineName option + UserId GUID). Cache
invalidated when user changes language or work date.

**Drill-down**: Each headline stores detail records in HeadlineDetailsPerUser
table. Cleared and rebuilt on every computation. User can click headline
to see underlying data.

**SQL queries**: Three AL queries provide efficient aggregation --
BestSoldItemHeadline, TopCustomerHeadline, SalesIncreaseHeadline. Used
instead of iterating filtered records.

## Structure

```
App/BCApps/src/Apps/W1/EssentialBusinessHeadlines/App/
├── src/
│   ├── codeunits/
│   │   ├── EssBusHeadlinesCompute.Codeunit.al  -- Computation engine + time window logic
│   │   ├── EssBusHeadlinesInstall.Codeunit.al   -- Install subscriber (sets up defaults)
│   │   └── [headline-specific computation codeunits]
│   ├── tables/
│   │   ├── EssBusHeadlinePerUsr.Table.al        -- Per-user cache (PK: HeadlineName + UserId)
│   │   └── HeadlineDetailsPerUser.Table.al      -- Drill-down detail records
│   ├── queries/
│   │   ├── BestSoldItemHeadline.Query.al        -- Aggregates item sales by quantity
│   │   ├── TopCustomerHeadline.Query.al         -- Aggregates customer sales by amount
│   │   └── SalesIncreaseHeadline.Query.al       -- Compares sales periods
│   ├── pages/
│   │   ├── [headline detail page]
│   │   └── [7 RC page extensions inject headlines via addlast(Content)]
│   └── Permissions/
│       └── [11 permission objects -- Read/Insert/Modify/Delete per object]
└── app.json
```

## Documentation

No external docs -- code is self-documenting. See inline comments in
EssBusHeadlinesCompute codeunit for time-window algorithm and threshold
logic.

## Things to know

**Role Center injection**: Page extensions use `addlast(Content)` to
insert headline parts into 7 base app Role Centers. Changes to RC layout
in base app may require extension updates.

**Event-driven computation**: Does not poll or use background tasks.
Computation is synchronous when user opens RC page -- first load may
show delay if cache empty.

**Language/date invalidation**: Changing language or work date clears
all cached headlines for that user. Next RC open recomputes from scratch.

**No telemetry**: App does not emit usage telemetry. Cannot track which
headlines are most viewed or clicked.

**Query performance**: Three AL queries hit potentially large tables
(Item Ledger, Cust. Ledger, Sales Header/Line). Time-window filter
helps but computation can be slow on large datasets.

**No configuration UI**: Thresholds (3 items, 5 orders) and time windows
(7/30/90 days) are hard-coded. Users cannot customize sensitivity or
lookback period.

**Drill-down limitation**: HeadlineDetailsPerUser stores max 20 detail
records per headline. If more exist, user sees "top 20" without indication
of total count.
