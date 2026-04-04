# Extensibility

## Event Subscriptions

The Transaction Storage extension subscribes to three platform events:

1. **OnAfterGLFinishPosting** (Gen. Jnl.-Post Line, codeunit 12)
   - Subscriber: TransStoragePostingState.OnAfterGLFinishPosting()
   - Purpose: Sets internal flag when GL entries are posted
   - Location: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransStoragePostingState.Codeunit.al

2. **OnAfterCompanyClose** (LogInManagement, codeunit 40)
   - Subscriber: TransStoragePostingState.OnAfterCompanyClose()
   - Purpose: Checks posting flag at user logout; if set, schedules export task
   - Location: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransStoragePostingState.Codeunit.al

3. **OnAfterDeleteEvent** (Scheduled Task, table 1254)
   - Subscriber: TransStorageScheduleTask.OnAfterDeleteScheduledTask()
   - Purpose: Logs telemetry when user manually deletes a scheduled export task
   - Location: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransStorageScheduleTask.Codeunit.al

## Custom Integration Events

The extension does not publish any custom integration events. It operates as a closed system with no exposed extension points for downstream apps.

## Configuration Limitations

### Hard-coded Table and Field Selection

The extension uses a fixed list of 29 tables and field whitelists defined in code:

- **Table list**: Defined in TransactStorageExportData.GetDataTables()
- **Field whitelists**: Defined per table in TransactStorageExportData.GetTableFieldSet()
- **Location**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactStorageExportData.Codeunit.al

No configuration-driven mechanism exists to add or remove tables, or to customize field selection. Extensions cannot modify the export scope.

### Non-extensible Enum

**TransStorageExportStatus** enum is not marked as extensible. Extensions cannot add custom export status values.

Location: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Enum\TransStorageExportStatus.Enum.al

## Azure Function Abstraction

Azure upload logic is centralized in **TransactionStorageABS** codeunit:

- **Text endpoint**: UploadJSONText() -- for transaction JSON and master data JSON
- **Base64 endpoint**: UploadBinaryData() -- for incoming documents
- **Location**: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactionStorageABS.Codeunit.al

These methods directly invoke Azure Function HTTP endpoints. Refactoring to an interface would enable:
- Custom storage backends (AWS S3, on-prem file shares)
- Test doubles for automated testing

Currently, Azure Blob Storage is the only supported backend.

## Access Modifiers

All codeunits are marked **Access = Internal**. The extension does not expose a public API for:
- Triggering exports programmatically
- Querying export status
- Customizing export logic

This design prevents unintended dependencies from other extensions.

## Environment Restrictions

The extension only operates in **SaaS production environments**:

- Checks: EnvironmentInformation.IsSaaS() and not EnvironmentInformation.IsSandbox() and not EnvironmentInformation.IsEvaluation()
- Location: TransStorageScheduleTask.ScheduleTask()
- Implication: Cannot be tested in sandbox or on-prem environments without code modification

## Country-specific Initialization

**TransactStorageInstall.OnInstallAppPerCompany()** reads **EnvironmentInformation.GetApplicationFamily()** to determine country code and initialize setup with country-specific defaults (e.g., CVR format for DK).

Location: C:\repos\NAV1\App\BCApps\src\Apps\W1\TransactionStorage\App\src\Codeunit\TransactStorageInstall.Codeunit.al

No extension point exists to override country detection or initialization logic.

## Summary

The Transaction Storage extension is designed as a closed system with minimal extensibility:

- 3 event subscribers (no custom events published)
- Hard-coded table and field selection (no config-driven export scope)
- Internal access modifiers (no public API)
- Azure-only storage backend (no interface abstraction)
- SaaS production restriction (no sandbox/on-prem support)
- Non-extensible enum

Extensions wishing to customize export behavior would need to fork the codebase rather than extend it.
