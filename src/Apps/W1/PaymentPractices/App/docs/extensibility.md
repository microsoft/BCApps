# Extensibility

The Payment Practices app is designed as an open framework for localization and ISV extensions. Both core enums are marked `Extensible = true`, and the architecture uses interfaces to support custom implementations.

## Extension points

### Add a new aggregation type

Aggregation types control how payment practice data is grouped and presented in reports. The app ships with two aggregation types: by period and by vendor size.

To add a new aggregation type:

1. Create a codeunit implementing the `PaymentPracticeLinesAggregator` interface. You must implement three methods:
   - `PrepareLayout()` -- registers the Word report layout for this aggregation type
   - `GenerateLines()` -- produces aggregated lines from header data
   - `ValidateHeader()` -- validates header fields before generation

2. Add an enum value to `Paym. Prac. Aggregation Type` and bind it to your codeunit.

3. Create a Word report layout for your aggregation type. Register it in `PrepareLayout()`.

The report will automatically use your codeunit when the user selects your aggregation type.

### Add a new data source

Data sources define where payment practice data originates. The app ships with two sources: vendor ledger entries and customer ledger entries.

To add a new data source:

1. Create a codeunit implementing the `PaymentPracticeDataGenerator` interface. You must implement one method:
   - `GenerateData()` -- reads source data and populates payment practice header records

2. Add an enum value to `Paym. Prac. Header Type` and bind it to your codeunit.

The framework will invoke your generator when creating headers of your type.

### Integration events

**OnBeforeSetupDefaults** on the `PaymentPeriod` table allows custom period setup per region. This event uses the `IsHandled` pattern -- set `IsHandled := true` to prevent default period creation.

### External dependencies

The app references fields defined in base app extensions but not included in this app:

- **Exclude from Pmt. Practices** flag on Vendor and Customer tables -- must be defined by base app or localization layer
- **Company Size Code** on Vendor and Customer tables -- must be populated externally before aggregation by size will produce meaningful results

### Layouts

The report has two Word layouts:

- `PaymentPractice_PeriodLayout` -- used by period aggregation
- `PaymentPractice_VendorSizeLayout` -- used by size aggregation

New aggregators must provide their own layouts. Layouts are registered in the `PrepareLayout()` method.

### Access modifiers

All core codeunits are marked `Internal` access. The public API consists of:

- The two extensible enums (`Paym. Prac. Aggregation Type`, `Paym. Prac. Header Type`)
- The two interfaces (`PaymentPracticeLinesAggregator`, `PaymentPracticeDataGenerator`)
- The table objects (Header, Lines, PaymentPeriod)
- The report object

Extensions should interact with the framework through these public contracts, not by calling internal codeunits directly.

### Telemetry

The app emits Feature Telemetry events for key operations:

- `0000KSW` -- Payment Practices list page discovered
- `0000KSV` -- Report printed
- `0000KSU` -- Period aggregation completed
- `0000KSX` -- Size aggregation completed

Extensions can emit their own telemetry using the same FeatureTelemetry codeunit.

## Summary

This is an open framework. Partners can add jurisdiction-specific aggregation types and data sources without modifying core code. Extend the enums, implement the interfaces, and register your layouts -- the framework handles the rest.
