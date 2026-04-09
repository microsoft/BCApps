## REMOVED Requirements

### Requirement: AU CSV export codeunit exists
**Reason**: C694 is an AU-only object removed from the W1/GB branch. The `ExportAUCSV` action on the Payment Practice Card is also removed.
**Migration**: Colleague recreates C694 and the card action from au-complete spec section 9.

### Requirement: AU export includes header-level totals
**Reason**: C694 removed.
**Migration**: No action required.

### Requirement: AU export includes period-aggregated invoice data
**Reason**: C694 removed.
**Migration**: No action required.

### Requirement: AU declaration document
**Reason**: R680 (report + Word layout) are AU-only objects removed from the W1/GB branch.
**Migration**: Colleague recreates from au-complete spec section 10.

### Requirement: Export format details deferred
**Reason**: C694 removed. Format details are moot until the codeunit is recreated.
**Migration**: No action required.
