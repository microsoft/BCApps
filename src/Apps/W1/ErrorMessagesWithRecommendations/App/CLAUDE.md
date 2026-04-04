# Error Messages with Recommendations

Framework that makes error messages actionable by attaching fix implementations that can be executed directly from the Error Messages page. Users see recommended actions alongside errors and can apply fixes with one click.

## Quick reference

- **ID range**: 7900-7920
- **Dependencies**: Base Application (extends Error Message table)

## How it works

The framework uses a polymorphic pattern where each type of fixable error implements the ErrorMessageFix interface. When an error is logged, event subscribers attach fix metadata to the error message record, specifying which implementation should handle it. The Error Messages page then shows recommended actions, and when the user clicks "Fix Error," the framework routes to the correct implementation via the Error Msg. Fix Implementation enum.

The ErrorMessageFix interface defines three methods that form the fix lifecycle. OnSetErrorMessageProps is called first to validate whether the error can be fixed and populate UI captions. OnFixError performs the actual correction (e.g., updating a dimension value). OnSuccessMessage generates confirmation text after a successful fix. The same interface instance flows through all three methods, allowing implementations to cache expensive lookups between calls.

Bulk operations are supported through ErrorBehavior::Collect and CommitBehavior::Ignore. When fixing multiple errors, the framework attempts each fix independently, collecting failures without rolling back successful fixes. This enables partial batch processing where some errors can be resolved even if others fail.

Event-driven enrichment happens when errors are logged. The framework subscribes to OnAddSubContextToLastErrorMessage, which fires after base error logging. Subscribers inspect the error context (record ID, field number) and attach the appropriate fix implementation enum value if they recognize the error pattern. This keeps fix logic decoupled from error generation sites.

## Structure

- **Interface/** -- ErrorMessageFix contract defining OnSetErrorMessageProps, OnFixError, OnSuccessMessage
- **Implementation/** -- Concrete fixes (dimension code corrections) plus default no-op handler
- **root src/** -- Event subscribers, Execute Error Action orchestrator, UI extensions, table extension

## Documentation

See Error Messages page and Error Message Management codeunit in Base Application for the underlying error collection framework.

## Things to know

- Table extension adds fix-specific fields to Error Message: Title, Recommended Action Caption, Fix Implementation enum, Message Status, Sub-Context Record ID, Sub-Context Field Number
- Error Msg. Fix Implementation enum is the routing table -- each value maps to a codeunit ID that implements ErrorMessageFix
- Execute Error Action codeunit wraps OnFixError because ErrorBehavior and CommitBehavior attributes only work on OnRun triggers, not interface methods
- Three concrete implementations ship in the box: DimensionCodeSameError (replace wrong value), DimensionCodeMustBeBlank (remove unwanted value), DimCodeSameButMissingErr (add missing value)
- OnSetErrorMessageProps must return false if the error is not fixable in the current state (e.g., source record was deleted)
- Sub-Context fields store the exact record and field that caused the error, allowing fixes to target the right data even when multiple records share the same error text
- The framework assumes errors are already logged -- it enriches existing Error Message records, does not create them
- Interface methods receive the Error Message record by var, allowing implementations to read context and update status in one pass
- Stateful pattern: implementations can populate internal variables during OnSetErrorMessageProps and reuse them in OnFixError, avoiding duplicate database lookups
- Default Error Msg. Fix Implementation is DoNothing, which shows no recommended action -- this is the fallback for unfixable errors
