# Extensibility

The Excel Reports app provides several extensibility points for customization:

## Caption Handler Events

Tables publish caption override events for dynamic column naming:
- `ExcelReportsTopCustomer` (table 4403) publishes `OnGetAmount1Caption` and `OnGetAmount2Caption`
- `ExcelReportsTopVendor` (table 4404) publishes `OnGetAmount1Caption` and `OnGetAmount2Caption`

Caption handlers in codeunits 4403 and 4404 subscribe with `EventSubscriberInstance=Manual`. Reports call `BindSubscription()` in `OnPreReport` to activate the subscription and pass state via `SetRankingBasedOn()`.

## Aging Override

`ExcelReportsAgedAccRec` (table 4401) publishes the `OnOverrideAgedBy` integration event. Subscribers can change the aging date basis at runtime, overriding the default document date calculation.

## Telemetry

`ExcelReportsTelemetry` (codeunit 4412) provides `LogReportUsage(ReportId)` for tracking report execution. All reports call this method in `OnPreReport` to record usage metrics.

## Page Extensions

The app includes 37 page extensions that add report actions to list pages and role centers. Partners can follow the same pattern to add custom Excel report actions to their own pages.

## Legacy Events

Trial Balance reports contain obsolete integration events for backward compatibility:
- `OnBeforeInsertDimensionFilters` -- marked for removal in CLEAN27

These events exist only to preserve behavior for existing subscribers and will be removed in a future release.

## Customization Surface

The extension surface is relatively narrow. The primary customization mechanism is Excel layout templates rather than AL code. The temporary buffer table architecture and query-based data loading limit the need for runtime hooks. Most partners will extend by modifying Excel layouts or adding new page actions rather than subscribing to events.
