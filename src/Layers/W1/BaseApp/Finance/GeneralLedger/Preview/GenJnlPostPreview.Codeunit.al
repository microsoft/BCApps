// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Preview;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using System.Telemetry;
using System.Utilities;

/// <summary>
/// Core preview engine for general journal posting operations with comprehensive simulation and validation capabilities.
/// Provides posting preview functionality without database commits, enabling validation and analysis before actual posting.
/// </summary>
/// <remarks>
/// <para>
/// <b>Core Functionality:</b>
/// Executes posting procedures in preview mode using temporary records and transaction simulation.
/// Captures posting results, errors, and entry details for display and validation purposes.
/// </para>
/// <para>
/// <b>Integration:</b>
/// Works with posting codeunits through event subscription, capturing entries through PostingPreviewEventHandler.
/// Supports multiple posting scenarios including general journals, sales, purchase, and service documents.
/// </para>
/// <para>
/// <b>Extensibility:</b>
/// Provides integration events for custom preview logic and specialized entry handling.
/// Enables custom preview scenarios through event-driven architecture.
/// </para>
/// </remarks>
codeunit 19 "Gen. Jnl.-Post Preview"
{

    trigger OnRun()
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        HideDialogs := true;
        CLEAR(PostingPreviewEventHandler);
        Preview(PreviewSubscriber, PreviewRecord);
        HideDialogs := false;
        LastErrorText := GetLastErrorText();
        if not IsSuccess() then
            ErrorMessageMgt.LogError(PreviewRecord, LastErrorText, '');
        Error('');
    end;

    var
        JournalErrorsMgt: Codeunit "Journal Errors Mgt.";
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        PreviewSubscriber: Variant;
        PreviewRecord: Variant;
        LastErrorText: Text;
        HideDialogs: Boolean;

        PreviewModeErr: Label 'Preview mode.';
        SubscriberTypeErr: Label 'Invalid Subscriber type. The type must be CODEUNIT.';
        RecVarTypeErr: Label 'Invalid RecVar type. The type must be RECORD.';
        PreviewExitStateErr: Label 'The posting preview has stopped because of a state that is not valid.';
        TelemetryFeatureNameTxt: Label 'Posting Preview on journals and documents', Locked = true;
        EventNameTxt: Label 'Posting Preview called', Locked = true;
        PreviewCalledForMultipleDocumentsMsg: Label 'You selected multiple documents. Posting Preview is shown for document no. %1 only.', Comment = '%1 = Document No.';

    /// <summary>
    /// Initiates posting preview for the specified document record using the provided posting codeunit.
    /// Executes posting logic in simulation mode without committing database transactions.
    /// </summary>
    /// <param name="Subscriber">Posting codeunit variant that will execute the posting logic</param>
    /// <param name="RecVar">Document record variant to be previewed for posting</param>
    procedure Preview(Subscriber: Variant; RecVar: Variant)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        OnBeforeRunPreview(Subscriber, RecVar);
        FeatureTelemetry.LogUsage('0000JBO', TelemetryFeatureNameTxt, EventNameTxt);

        PreviewStart(Subscriber, RecVar);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PreviewStart(Subscriber: Variant; RecVar: Variant)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
        RunResult: Boolean;
    begin
        if not Subscriber.IsCodeunit then
            Error(SubscriberTypeErr);
        if not RecVar.IsRecord then
            Error(RecVarTypeErr);

        BindSubscription(PostingPreviewEventHandler);
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, RecVar, 0, PreviewModeErr);
        OnAfterBindSubscription(PostingPreviewEventHandler);

        RunResult := RunPreview(Subscriber, RecVar);

        SequenceNoMgt.StopPreviewMode();
        UnbindSubscription(PostingPreviewEventHandler);
        OnAfterUnbindSubscription();

        // The OnRunPreview event expects subscriber following template: Result := <Codeunit>.RUN
        // So we assume RunPreview returns FALSE with the error.
        // To prevent return FALSE without thrown error we check error call stack.
        if RunResult or (GetLastErrorCallstack = '') then
            Error(PreviewExitStateErr);

        if not HideDialogs then begin
            if GetLastErrorText <> PreviewModeErr then
                if ErrorMessageHandler.ShowErrors() then
                    Error('');
            ShowAllEntries();
            Error('');
        end;
    end;

    /// <summary>
    /// Retrieves the current posting preview event handler instance for external processing.
    /// Enables access to captured preview entries and transaction details.
    /// </summary>
    /// <param name="ResultPostingPreviewEventHandler">Output parameter receiving the active event handler instance</param>
    procedure GetPreviewHandler(var ResultPostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        ResultPostingPreviewEventHandler := PostingPreviewEventHandler;
    end;

    /// <summary>
    /// Determines whether posting preview mode is currently active.
    /// Checks both system-level and extension-specific preview activation status.
    /// </summary>
    /// <returns>True if posting preview is active, false otherwise</returns>
    procedure IsActive(): Boolean
    var
        Result: Boolean;
    begin
        // The lookup to event subscription system virtual table is the performance killer.
        // We call subscriber CU 20 to get active state of posting preview context.
        OnSystemSetPostingPreviewActive(Result);

        OnAfterIsActive(Result);
        exit(Result);
    end;

    /// <summary>
    /// Determines whether the posting preview operation completed successfully.
    /// Validates that preview execution finished without posting errors.
    /// </summary>
    /// <returns>True if preview completed successfully, false if errors occurred</returns>
    procedure IsSuccess(): Boolean;
    begin
        exit(LastErrorText = PreviewModeErr);
    end;

    local procedure RunPreview(Subscriber: Variant; RecVar: Variant): Boolean
    var
        Result: Boolean;
    begin
        OnRunPreview(Result, Subscriber, RecVar);
        exit(Result);
    end;

    /// <summary>
    /// Sets the context for posting preview operations with the specified posting codeunit and record.
    /// Configures preview environment for later execution without immediate preview processing.
    /// </summary>
    /// <param name="Subscriber">Posting codeunit variant that will handle the posting operation</param>
    /// <param name="RecVar">Document record variant to be processed in preview mode</param>
    procedure SetContext(Subscriber: Variant; RecVar: Variant)
    begin
        PreviewSubscriber := Subscriber;
        PreviewRecord := RecVar;
    end;

    local procedure ShowAllEntries()
    var
        GLSetup: Record "General Ledger Setup";
        TempDocumentEntry: Record "Document Entry" temporary;
        GLPostingPreview: Page "G/L Posting Preview";
        ExtendedGLPostingPreview: Page "Extended G/L Posting Preview";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowAllEntries(TempDocumentEntry, IsHandled, PostingPreviewEventHandler);
        if IsHandled then
            exit;

        PostingPreviewEventHandler.FillDocumentEntry(TempDocumentEntry);
        if not TempDocumentEntry.IsEmpty() then begin
            GLSetup.Get();
            case GLSetup."Posting Preview Type" of
                Enum::"Posting Preview Type"::Standard:
                    begin
                        GLPostingPreview.Set(TempDocumentEntry, PostingPreviewEventHandler);
                        GLPostingPreview.Run();
                    end;
                Enum::"Posting Preview Type"::Extended:
                    begin
                        ExtendedGLPostingPreview.Set(TempDocumentEntry, PostingPreviewEventHandler);
                        ExtendedGLPostingPreview.Run();
                    end;
                else
                    OnShowAllEntriesOnCaseElse(TempDocumentEntry, PostingPreviewEventHandler);
            end;
        end else
            Message(JournalErrorsMgt.GetNothingToPostErrorMsg());

        OnAfterShowAllEntries();
    end;

    /// <summary>
    /// Displays dimension information for a specific entry during posting preview operations.
    /// Shows dimension set details associated with preview entries for validation and analysis.
    /// </summary>
    /// <param name="TableID">Table identifier for the entry type</param>
    /// <param name="EntryNo">Entry number for caption display</param>
    /// <param name="DimensionSetID">Dimension set identifier to display</param>
    procedure ShowDimensions(TableID: Integer; EntryNo: Integer; DimensionSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        DimMgt.ShowDimensionSet(DimensionSetID, StrSubstNo('%1 %2', RecRef.Caption, EntryNo));
    end;

    /// <summary>
    /// Triggers the preview mode error to exit posting preview operations gracefully.
    /// Used to terminate preview processing and return to normal application flow.
    /// </summary>
    procedure ThrowError()
    begin
        OnBeforeThrowError();
        Error(PreviewModeErr);
    end;

    /// <summary>
    /// Displays a message when posting preview is requested for multiple documents.
    /// Informs users that preview will only show results for the first document in the selection.
    /// </summary>
    /// <param name="RecordRefToPreview">Record reference containing multiple documents</param>
    /// <param name="DocumentNo">Document number that will be previewed</param>
    procedure MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview: RecordRef; DocumentNo: Code[20])
    begin
        if not GuiAllowed() then
            exit;

        if RecordRefToPreview.Count() <= 1 then
            exit;

        Message(PreviewCalledForMultipleDocumentsMsg, DocumentNo);
    end;

    /// <summary>
    /// Integration event raised before executing posting preview operations.
    /// Enables custom preprocessing or validation before preview execution begins.
    /// </summary>
    /// <param name="Subscriber">Posting codeunit variant that will handle the preview operation</param>
    /// <param name="RecVar">Document record variant to be previewed</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPreview(Subscriber: Variant; RecVar: Variant)
    begin
    end;

    /// <summary>
    /// Integration event raised to execute the actual posting preview operation.
    /// Allows custom posting codeunits to participate in the preview execution workflow.
    /// </summary>
    /// <param name="Result">Output parameter indicating whether the preview execution was successful</param>
    /// <param name="Subscriber">Posting codeunit variant that will execute the posting logic</param>
    /// <param name="RecVar">Document record variant to be processed in preview mode</param>
    [IntegrationEvent(false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    begin
    end;

    /// <summary>
    /// Integration event raised after binding the posting preview event handler subscription.
    /// Enables custom initialization or configuration of the preview event handler.
    /// </summary>
    /// <param name="PostingPreviewEventHandler">The event handler instance that was bound for preview processing</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterBindSubscription(var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;

    /// <summary>
    /// Integration event raised after unbinding the posting preview event handler subscription.
    /// Enables custom cleanup or finalization after preview processing completes.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterUnbindSubscription()
    begin
    end;

    /// <summary>
    /// Integration event raised to determine if posting preview mode is active at system level.
    /// Allows extensions to indicate whether preview operations should be enabled.
    /// </summary>
    /// <param name="Result">Output parameter indicating whether posting preview is active</param>
    [IntegrationEvent(false, false)]
    local procedure OnSystemSetPostingPreviewActive(var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised after checking if posting preview is active.
    /// Enables extensions to modify the active state determination logic.
    /// </summary>
    /// <param name="Result">Current result of preview active status check, can be modified</param>
    [IntegrationEvent(false, false)]
    local procedure OnAfterIsActive(var Result: Boolean)
    begin
    end;

    /// <summary>
    /// Integration event raised before displaying all preview entries to the user.
    /// Enables custom entry filtering, modification, or alternative display handling.
    /// </summary>
    /// <param name="TempDocumentEntry">Temporary document entry records to be displayed</param>
    /// <param name="IsHandled">Set to true to skip standard entry display processing</param>
    /// <param name="PostingPreviewEventHandler">Event handler containing captured preview entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAllEntries(var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;

    /// <summary>
    /// Integration event raised before throwing the preview mode error to exit gracefully.
    /// Enables custom cleanup or finalization before preview termination.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowError()
    begin
    end;

    /// <summary>
    /// Integration event raised after displaying all preview entries to the user.
    /// Enables custom post-display processing or additional user interactions.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterShowAllEntries()
    begin
    end;

    /// <summary>
    /// Integration event raised when no standard preview type matches the configuration.
    /// Enables custom preview display handling for extended preview scenarios.
    /// </summary>
    /// <param name="TempDocumentEntry">Temporary document entry records to be displayed</param>
    /// <param name="PostingPreviewEventHandler">Event handler containing captured preview entries</param>
    [IntegrationEvent(false, false)]
    local procedure OnShowAllEntriesOnCaseElse(var TempDocumentEntry: Record "Document Entry" temporary; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;
}

