## REMOVED Requirements

### Requirement: Dispute & Retention detail table exists
**Reason**: The ~40 manually-entered qualitative GB fields are descoped from this deliverable. Table T689 is removed entirely.
**Migration**: No action required. Fields 20-23 (payment statistics) remain on the Payment Practice Header.

### Requirement: Detail table contains payment policy fields
**Reason**: Table T689 removed — GB manual fields descoped.
**Migration**: No action required.

### Requirement: Detail table contains qualifying contract fields
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: Detail table contains payment terms fields
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: Detail table contains construction retention fields
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: Detail table contains retention statistics fields
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: Detail table contains dispute resolution field
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: Detail table contains deduction charges field
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: Detail record created on header insert
**Reason**: Table T689 removed. The `OnInsert` trigger on Payment Practice Header SHALL no longer create a T689 record.
**Migration**: No action required.

### Requirement: Detail record deleted with header
**Reason**: Table T689 removed. The `DeleteLinkedRecords` procedure on Payment Practice Header SHALL no longer reference T689.
**Migration**: No action required.

### Requirement: Copy from previous period
**Reason**: Table T689 removed.
**Migration**: No action required.

### Requirement: CalculateRetentionPercentages on detail table
**Reason**: Table T689 removed.
**Migration**: No action required.
