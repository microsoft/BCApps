# Extensibility

The Simplified Bank Statement Import app is designed as a closed configuration wizard. It provides limited extensibility points for custom file sources and UI integration, but does not expose a public API for programmatic extension by ISVs.

## Integration Events

### OnBeforeUploadBankFile

**Codeunit 8850** publishes the **OnBeforeUploadBankFile** integration event, allowing external code to provide custom file sources instead of the standard file upload dialog.

**Parameters:**
- `FileName` (out, Text): The name of the file being imported
- `TempBlob` (out, Codeunit "Temp Blob"): The file content as a binary large object
- `IsHandled` (out, Boolean): Set to true to skip the standard upload dialog

**Use cases:**
- Loading bank statements from an API endpoint
- Injecting mock CSV files during automated testing (used by the app's test framework)
- Integrating with document management systems

**Example usage:**
```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Statement File Wizard", 'OnBeforeUploadBankFile', '', false, false)]
local procedure HandleCustomFileSource(var FileName: Text; var TempBlob: Codeunit "Temp Blob"; var IsHandled: Boolean)
begin
    if not ShouldHandleUpload() then
        exit;

    // Load file content into TempBlob
    LoadFileFromAPI(TempBlob);
    FileName := 'bank-statement.csv';
    IsHandled := true;
end;
```

## Guided Experience Integration

The wizard registers itself with the Guided Experience framework by subscribing to the **OnRegisterAssistedSetup** event.

**Registration details:**
- **Group**: "Ready for Business"
- **Object Type**: Page
- **Object ID**: 8850 (Bank Statement File Wizard)
- **Multi-language support**: Calls `AddTranslationForSetupObjectTitle()` to register translated titles for each language

This registration makes the wizard discoverable through the standard Assisted Setup page and related UI entry points.

## UI Entry Points

### Bank Account Card Notification

The **Bank Account Card** page extension creates a notification when a bank account has no import format assigned. The notification:

- Stores the bank account code in notification data
- Displays an action that triggers **RunBankStatementFileWizard()**
- Guides users directly to the wizard from the bank account card

### Bank Export/Import Setup Action

The **Bank Export/Import Setup** list page extension adds a **"Bank Statement File Format Wizard"** action, providing direct access to the wizard from the setup list.

## Design Philosophy

This app follows a **closed configuration wizard** pattern:

- All codeunit and page procedures are marked as `local` or `internal`
- No public API is exposed for ISVs to call
- The wizard is designed for end-user interaction, not programmatic automation
- The only extension point for external code is the **OnBeforeUploadBankFile** event

This design ensures a consistent user experience while allowing targeted integration for custom file sources. If you need to extend the import process beyond file sourcing, consider building a separate Data Exchange Definition using the standard Business Central framework rather than extending this wizard.
