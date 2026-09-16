namespace System.TestLibraries.Agents;

/// <summary>
/// Caller-owned execution result for one request. Assistant text and sanitized diagnostics are kept separate.
/// Execution success does not indicate that the answer passed evaluation.
/// </summary>
codeunit 130567 "AIT Request Result"
{
    Access = Public;
    SingleInstance = false;

    var
        ExecutionSuccessful: Boolean;
        AssistantText: Text;
        Diagnostics: JsonObject;

    procedure SetResult(NewExecutionSuccessful: Boolean; NewAssistantText: Text; SanitizedDiagnostics: JsonObject)
    begin
        ExecutionSuccessful := NewExecutionSuccessful;
        AssistantText := NewAssistantText;
        Diagnostics := SanitizedDiagnostics.Clone().AsObject();
    end;

    procedure GetExecutionSuccessful(): Boolean
    begin
        exit(ExecutionSuccessful);
    end;

    procedure GetAssistantText(): Text
    begin
        exit(AssistantText);
    end;

    procedure GetDiagnostics(): JsonObject
    begin
        exit(Diagnostics.Clone().AsObject());
    end;

    procedure Reset()
    begin
        ExecutionSuccessful := false;
        Clear(AssistantText);
        Clear(Diagnostics);
    end;
}