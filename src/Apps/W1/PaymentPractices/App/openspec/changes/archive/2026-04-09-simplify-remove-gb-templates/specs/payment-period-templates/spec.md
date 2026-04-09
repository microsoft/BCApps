## REMOVED Requirements

### Requirement: Payment Period Header table exists
**Reason**: Payment period templates are removed. The flat `Payment Period` table (T685) is kept as the single source for period definitions.
**Migration**: No action required for end users. Period definitions remain editable via the original Payment Periods page (P685).

### Requirement: Payment Period Line table exists
**Reason**: Payment period templates are removed.
**Migration**: No action required.

### Requirement: Payment Period Code on Payment Practice Header
**Reason**: The `Payment Period Code` field (16) on Payment Practice Header is removed. Period aggregation reads directly from the flat `Payment Period` table (T685).
**Migration**: No action required.

### Requirement: Period Aggregator uses Payment Period Line
**Reason**: Period aggregator reverts to reading from the flat `Payment Period` table (T685) instead of from `Payment Period Line`.
**Migration**: No action required.

### Requirement: Payment Period pages exist
**Reason**: Payment Period Card (P690), Payment Period List (P691), and Payment Period Subpage (P692) are removed along with the template tables.
**Migration**: Users edit periods via the original Payment Periods page (P685).

### Requirement: Old Payment Period table deprecated
**Reason**: Table 685 is no longer deprecated — it remains the active, current table for period definitions. Obsolete marking is reverted.
**Migration**: No action required.
