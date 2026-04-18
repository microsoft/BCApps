# Extensibility

The Error Messages with Recommendations framework is designed for extension. Third parties can add custom error fixes without modifying base objects or requiring source access. The extensibility model relies on interfaces, extensible enums, and event subscribers.

## ErrorMessageFix interface

The ErrorMessageFix interface defines the contract for fix implementations. It declares three methods:

**OnSetErrorMessageProps** populates Title and Recommended Action Caption fields on the error record. This method is called once during error enrichment, before the error appears in the UI. Implementations should cache any lookups needed for later methods to avoid redundant database queries.

**OnFixError** executes the actual fix logic. It receives the error record, which contains context record ID, sub-context record ID, and other metadata needed to locate and modify the source data. The method returns true if the fix succeeded, false otherwise. Implementations should not throw errors -- return false and let the caller handle failure.

**OnSuccessMessage** returns the acknowledgment text shown to users after successful fixes. The message should describe what changed, using values cached during OnSetErrorMessageProps or read during OnFixError. The same interface instance persists across all three method calls, enabling stateful implementations.

The interface contract assumes statefulness. Implementations can store temporary records, field values, or other context as member variables during OnSetErrorMessageProps, then reference those variables in OnFixError and OnSuccessMessage. This pattern reduces database round-trips and simplifies success message formatting.

## Adding a new fix

To add a custom error fix:

**Step 1:** Create a codeunit implementing ErrorMessageFix. The codeunit should be marked Access = Internal unless it needs to be callable from other apps.

```al
codeunit 50100 "My Custom Fix" implements ErrorMessageFix
{
    procedure OnSetErrorMessageProps(var ErrorMessage: Record "Error Message" temporary)
    begin
        // Populate Title and Recommended Action Caption
    end;

    procedure OnFixError(ErrorMessage: Record "Error Message" temporary): Boolean
    begin
        // Apply the fix, return success/failure
    end;

    procedure OnSuccessMessage(): Text
    begin
        // Return acknowledgment message
    end;
}
```

**Step 2:** Add an enum value to Error Msg. Fix Implementation. The enum is marked Extensible = true, allowing enum extensions in separate apps.

```al
enumextension 50100 "My Custom Fix Enum" extends "Error Msg. Fix Implementation"
{
    value(50100; MyCustomFix)
    {
        Implementation = ErrorMessageFix = "My Custom Fix";
    }
}
```

**Step 3:** Subscribe to OnAddSubContextToLastErrorMessage to populate fix metadata when your error is logged. The subscriber checks the Tag parameter to ensure it only processes errors meant for your fix.

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"Error Message Management",
    OnAddSubContextToLastErrorMessage, '', false, false)]
local procedure OnAddSubContextToLastErrorMessage(Tag: Text; VariantRec: Variant;
    var ErrorMessage: Record "Error Message" temporary)
var
    IErrorMessageFix: Interface ErrorMessageFix;
begin
    if Tag <> 'MyCustomFix' then
        exit;

    // Set sub-context and fix implementation
    ErrorMessage.Validate("Sub-Context Record ID", ...);
    ErrorMessage.Validate("Error Msg. Fix Implementation",
        Enum::"Error Msg. Fix Implementation"::MyCustomFix);

    // Populate title and caption via interface
    IErrorMessageFix := ErrorMessage."Error Msg. Fix Implementation";
    IErrorMessageFix.OnSetErrorMessageProps(ErrorMessage);
    ErrorMessage.Modify();
end;
```

The Tag parameter must match the enum value name exactly. The base framework converts enum values to strings using Names().Get() and passes the result as the tag. Case sensitivity matters -- use the same casing as the enum value name.

## Extensible enums

Both Error Msg. Fix Implementation and Error Message Status enums are marked Extensible = true. Third-party apps can add enum values without modifying base objects.

Error Msg. Fix Implementation uses DefaultImplementation to point to a no-op stub. This fallback ensures unknown enum values don't cause runtime errors. If an error record references a removed or uninstalled fix implementation, the system defaults to the stub, which returns "No fix available" for OnSuccessMessage.

Error Message Status doesn't use DefaultImplementation because it's a simple state enum. Third parties can add new states (e.g., "In Progress", "Skipped") if their workflows require tracking beyond Fixed/Failed to fix/blank. The page extension should check for unknown states and handle them gracefully.

## Event subscribers

Beyond OnAddSubContextToLastErrorMessage, the framework publishes events for serialization and navigation:

**OnAddToJsonFromErrorMessage** fires when error records are serialized to JSON. Subscribe to include extension fields in the serialized output. The base implementation already serializes Title, Recommended Action Caption, Fix Implementation, Message Status, Sub-Context Record ID, and Sub-Context Field Number.

**OnAddToErrorMessageFromJson** fires when error records are deserialized from JSON. Subscribe to populate extension fields from JSON properties. The base implementation handles all extension fields added by this app.

**OnDrillDown Source** fires when users click drill-down fields on error records. Subscribe to provide custom navigation for sub-context types not handled by the base implementation. Set IsHandled to true to prevent default drill-down behavior.

These events enable layered extensibility. Multiple apps can enrich errors with different metadata, serialize custom fields, and handle drill-down for their specific sub-context types without conflicting.

## ErrorBehavior wrapping

The ExecuteActionWithCollectErr method wraps OnFixError calls with ErrorBehavior::Collect. This attribute is AL's mechanism for error suppression and collection, similar to try-catch in C#.

ErrorBehavior::Collect only works on methods marked with the attribute -- you cannot apply it to interface methods. This AL limitation forces the indirect execution pattern: the interface method is called from a wrapper codeunit whose OnRun trigger has the attribute.

CommitBehavior::Ignore ensures fixes don't commit database changes mid-transaction. This prevents partial commits when a fix modifies multiple records. If the fix fails, all changes roll back automatically.

Third-party fixes should not attempt to manage ErrorBehavior or CommitBehavior themselves. The framework handles wrapping automatically when fixes are invoked via ExecuteAction. Custom fix logic should focus on reading context, applying changes, and returning success/failure.

## Common patterns

**Interface-based polymorphism via extensible enum:** The enum implements the interface, creating a type-safe registry of implementations. Resolving the interface from an enum value happens automatically -- assign the enum to an interface variable and AL dispatches to the correct codeunit.

**ErrorBehavior wrapping in separate codeunit:** AL only allows ErrorBehavior attributes on OnRun triggers and local procedures. The Execute Error Action codeunit provides the necessary OnRun trigger to wrap interface calls with error collection.

**Reflection-heavy dimension fixes:** RecordRef and FieldRef enable generic code that works across multiple table types. FindFieldByName locates fields by name string, avoiding hard-coded field references that would break across different document types.

**Tag-based event routing:** Subscribers check the Tag parameter to filter events. The tag contains a string representation of the enum value name, enabling multiple subscribers to coexist without conflicts. Each subscriber processes only errors tagged for its fix implementation.

The framework is OPEN by design. Unlike closed systems like e-document connectors, where Microsoft controls all implementations, this app allows third parties to add fixes on equal footing with Microsoft implementations. Any app can extend the enum, implement the interface, and subscribe to enrichment events.
