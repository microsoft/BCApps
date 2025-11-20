// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Navigate;
using Microsoft.Utilities;
using System.Utilities;

codeunit 373 "Bank. Acc. Recon. Post Preview"
{

    trigger OnRun()
    begin
        RunPreview();
    end;

    var
        PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler";
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        PreviewExitStateErr: Label 'The posting preview has stopped because of a state that is not valid.';
        PreviewSubscriber: Variant;
        PreviewRecord: Variant;
        LastErrorText: Text;
        HideDialogs: Boolean;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure RunPreview()
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        HideDialogs := true;
        Clear(PostingPreviewEventHandler);
        Preview(PreviewSubscriber, PreviewRecord);
        Clear(HideDialogs);
        LastErrorText := GetLastErrorText();
        ClearLastError();
        if not IsSuccess() then
            ErrorMessageMgt.LogError(PreviewRecord, LastErrorText, '');
    end;

    procedure Preview(var Subscriber: Codeunit "Bank Acc. Reconciliation Post"; var BankAccReconciliationSource: Record "Bank Acc. Reconciliation")
    begin
        OnBeforeRunPreview(Subscriber, BankAccReconciliationSource);
        PreviewStart(Subscriber, BankAccReconciliationSource);
    end;

    [CommitBehavior(CommitBehavior::Ignore)]
    local procedure PreviewStart(var Subscriber: Codeunit "Bank Acc. Reconciliation Post"; var BankAccReconciliationSource: Record "Bank Acc. Reconciliation")
    var
        DummyErrorMessage: Record "Error Message";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorMessageMgt: Codeunit "Error Message Management";
        RunResult: Boolean;
    begin
        BindSubscription(PostingPreviewEventHandler);
        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(
            ErrorContextElement,
            BankAccReconciliationSource,
            0,
            CopyStr(DocumentErrorsMgt.GetNothingToPostErrorMsg(), 1, MaxStrLen(DummyErrorMessage."Additional Information")));
        OnAfterBindSubscription(PostingPreviewEventHandler);

        RunResult := RunPreview(Subscriber, BankAccReconciliationSource);
        if not RunResult then
            if ThrowExpectedPreviewError() then;

        UnbindSubscription(PostingPreviewEventHandler);
        OnAfterUnbindSubscription(PostingPreviewEventHandler);

        // The OnRunPreview event expects subscriber following template: Result := <Codeunit>.RUN
        // So we assume RunPreview returns FALSE with the error.
        if RunResult then
            Error(PreviewExitStateErr);

        if not HideDialogs then begin
            if GetLastErrorText <> DocumentErrorsMgt.GetNothingToPostErrorMsg() then
                if ErrorMessageHandler.ShowErrors() then
                    exit;
            ShowAllEntries();
        end;

        Error('');
    end;

    [TryFunction]
    local procedure ThrowExpectedPreviewError()
    begin
        Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
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
        exit(LastErrorText = DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    local procedure RunPreview(var Subscriber: Codeunit "Bank Acc. Reconciliation Post"; var BankAccReconciliationSource: Record "Bank Acc. Reconciliation"): Boolean
    var
        Result: Boolean;
    begin
        OnRunPreview(Result, Subscriber, BankAccReconciliationSource);
        exit(Result);
    end;

    procedure SetContext(var Subscriber: Codeunit "Bank Acc. Reconciliation Post"; var BankAccReconciliationSource: Record "Bank Acc. Reconciliation")
    begin
        PreviewSubscriber := Subscriber;
        PreviewRecord := BankAccReconciliationSource;
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
            if GuiAllowed() and not HideDialogs then
                Message(DocumentErrorsMgt.GetNothingToPostErrorMsg());

        OnAfterShowAllEntries();
    end;

    procedure ShowDimensions(TableID: Integer; EntryNo: Integer; DimensionSetID: Integer)
    var
        DimMgt: Codeunit DimensionManagement;
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        DimMgt.ShowDimensionSet(DimensionSetID, CopyStr(RecRef.Caption + Format(EntryNo), 1, 250));
    end;

    procedure ThrowError()
    begin
        OnBeforeThrowError();
        Error(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunPreview(var Subscriber: Codeunit "Bank Acc. Reconciliation Post"; var BankAccReconciliationSource: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunPreview(var Result: Boolean; var Subscriber: Codeunit "Bank Acc. Reconciliation Post"; var BankAccReconciliationSource: Record "Bank Acc. Reconciliation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBindSubscription(var PostingPreviewEventHandler: Codeunit "Posting Preview Event Handler")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUnbindSubscription(var EventHandlerCodeunit: Codeunit "Posting Preview Event Handler")
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

