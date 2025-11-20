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

    procedure GetPreviewHandler(var ResultPostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
        ResultPostingPreviewEventHandler := PostingPreviewEventHandler;
    end;

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

    procedure ShowDimensions(TableID: Integer; EntryNo: Integer; DimensionSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        DimMgt.ShowDimensionSet(DimensionSetID, StrSubstNo('%1 %2', RecRef.Caption, EntryNo));
    end;

    procedure ThrowError()
    begin
        OnBeforeThrowError();
        Error(PreviewModeErr);
    end;

    procedure MessageIfPostingPreviewMultipleDocuments(RecordRefToPreview: RecordRef; DocumentNo: Code[20])
    begin
        if not GuiAllowed() then
            exit;

        if RecordRefToPreview.Count() <= 1 then
            exit;

        Message(PreviewCalledForMultipleDocumentsMsg, DocumentNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPreview(Subscriber: Variant; RecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreview(var Result: Boolean; Subscriber: Variant; RecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBindSubscription(var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnbindSubscription()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSystemSetPostingPreviewActive(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsActive(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAllEntries(var TempDocumentEntry: Record "Document Entry" temporary; var IsHandled: Boolean; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeThrowError()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowAllEntries()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowAllEntriesOnCaseElse(var TempDocumentEntry: Record "Document Entry" temporary; var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;
}

