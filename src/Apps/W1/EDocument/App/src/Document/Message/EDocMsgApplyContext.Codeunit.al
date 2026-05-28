// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

/// <summary>
/// The intent-declaration surface for "IEDocumentMessageType.ApplyMessage". Passed by the
/// framework into ApplyMessage; the Type uses it to declare what should happen — set parent
/// status, signal ignored, signal error, add a log note. The framework reads the context
/// after ApplyMessage returns and executes the intent uniformly (lock, persist, log, fire
/// event). The Type does NOT mutate parent records directly.
///
/// Mirrors the existing ActionContext pattern used by IDocumentAction.
/// </summary>
codeunit 6340 "E-Doc. Msg. Apply Context"
{
    var
        NewParentStatusSet: Boolean;
        NewParentStatusValue: Enum "E-Document Service Status";

        IgnoredFlag: Boolean;
        IgnoredReason: Text;

        ErrorFlag: Boolean;
        ErrorStatusValue: Enum "E-Document Service Status";
        ErrorText: Text;

        LogNotes: List of [Text];

    /// <summary>
    /// Type tells the framework: advance the parent's Service Status to this value.
    /// Calling more than once overwrites the previous intent.
    /// </summary>
    procedure SetParentStatus(NewStatus: Enum "E-Document Service Status")
    begin
        NewParentStatusSet := true;
        NewParentStatusValue := NewStatus;
    end;

    /// <summary>
    /// Type tells the framework: this message has no effect on parent state (e.g., a backward
    /// transition under PEPPOL BIS 63 advancement rules, or a duplicate). Message row will be
    /// marked Ignored; the reason is logged.
    /// </summary>
    procedure SignalIgnored(Reason: Text)
    begin
        IgnoredFlag := true;
        IgnoredReason := Reason;
    end;

    /// <summary>
    /// Type tells the framework: applying this message hit an error worth surfacing as a parent
    /// status (e.g., MLR RE → "Receiver Rejected (Validation)"). Message row will be marked
    /// Apply Failed; error text is logged.
    /// </summary>
    procedure SetErrorStatus(NewStatus: Enum "E-Document Service Status"; ErrText: Text)
    begin
        ErrorFlag := true;
        ErrorStatusValue := NewStatus;
        ErrorText := ErrText;
    end;

    /// <summary>
    /// Optional format-specific log enrichment. Appended to the framework log entries the
    /// framework writes for this apply. Implementer does not call EDocumentLog directly.
    /// </summary>
    procedure AddLogNote(Description: Text)
    begin
        LogNotes.Add(Description);
    end;

    // ----- Read-back surface — used by the framework after Type.ApplyMessage returns. -----

    internal procedure HasNewParentStatus(): Boolean
    begin
        exit(NewParentStatusSet);
    end;

    internal procedure GetNewParentStatus(): Enum "E-Document Service Status"
    begin
        exit(NewParentStatusValue);
    end;

    internal procedure IsIgnored(): Boolean
    begin
        exit(IgnoredFlag);
    end;

    internal procedure GetIgnoredReason(): Text
    begin
        exit(IgnoredReason);
    end;

    internal procedure HasError(): Boolean
    begin
        exit(ErrorFlag);
    end;

    internal procedure GetErrorStatus(): Enum "E-Document Service Status"
    begin
        exit(ErrorStatusValue);
    end;

    internal procedure GetErrorText(): Text
    begin
        exit(ErrorText);
    end;

    internal procedure GetLogNotes(): List of [Text]
    begin
        exit(LogNotes);
    end;
}
