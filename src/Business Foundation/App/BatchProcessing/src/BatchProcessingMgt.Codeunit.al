// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.Outbox;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Utilities;
using System.Security.User;
using System.Utilities;

codeunit 1380 "Batch Processing Mgt."
{
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;

    trigger OnRun()
    begin
        RunCustomProcessing();
    end;

    var
        RecRefCustomerProcessing: RecordRef;
        ProcessingCodeunitID: Integer;
        BatchIDGlobal: Guid;
        IsCustomProcessingHandled: Boolean;
        IsHandled: Boolean;
        KeepParameters: Boolean;

        PostingTemplateMsg: Label 'Processing: @1@@@@@@@', Comment = '1 - overall progress';
        ProcessingCodeunitNotSetErr: Label 'A processing codeunit has not been selected.';
        BatchCompletedMsg: Label 'All of your selections were processed.';
        TelemetryCategoryTxt: Label 'GenJournal', Locked = true;
        GenJournalPostFailedTxt: Label 'General journal posting failed. Journal Template: %1, Journal Batch: %2', Locked = true;
        InterCompanyZipFileNamePatternTok: Label 'General Journal IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';
        BatchProcessingTxt: Label 'Batch processing of %1 records.', Comment = '%1 - a table caption';
        ProcessingMsg: Label 'Executing codeunit %1 on record %2.', Comment = '%1 - codeunit id,%2 - record id';
        ProcessConfirmWithSkipQst: Label 'You have selected multiple documents for processing. \Some of the documents are not available and will be skipped. (Selected %1, Skipping %2)\\Do you want to continue?', Comment = '%1=integer(number of rows selected) %2=integer(number of rows skipped)';
        ProcessConfirmWithoutSkipQst: Label 'You have selected multiple documents for processing. (Selected %1, Skipping 0)\\Do you want to continue?', Comment = '%1=integer(number of rows selected)';
        NotARecordErr: Label 'Something went wrong and we could not complete the process. Contact your administrator for assistance.';

    procedure BatchProcess(var RecRef: RecordRef)
    begin
        BatchProcess(RecRef, Enum::"Error Handling Options"::"Show Notification");
    end;

    procedure BatchProcess(SourceRecord: Variant; SourceRecordProcessingCodeunitId: Integer; ErrorHandlingOptions: Enum "Error Handling Options"; NoSelected: Integer; NoSkipped: Integer)
    var
        ConfirmManagement: Codeunit "Confirm Management";
        RecRef: RecordRef;
        ProcessConfirmQst: Text;
    begin
        if not SourceRecord.IsRecord then
            Error(NotARecordErr);

        RecRef.GetTable(SourceRecord);
        if RecRef.Count = 0 then
            exit;

        SetProcessingCodeunit(SourceRecordProcessingCodeunitId);
        if RecRef.Count = 1 then begin
            RecRef.FindFirst();
            RecRef.SetTable(SourceRecord);
            Codeunit.Run(ProcessingCodeunitID, SourceRecord)
        end else begin
            if (NoSkipped <> 0) or (NoSelected <> 0) then begin
                if NoSkipped <> 0 then
                    ProcessConfirmQst := StrSubstNo(ProcessConfirmWithSkipQst, NoSelected, NoSkipped)
                else
                    ProcessConfirmQst := StrSubstNo(ProcessConfirmWithoutSkipQst, NoSelected);
                if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ProcessConfirmQst, NoSelected, NoSkipped), true) then
                    exit;
            end;
            BatchProcess(RecRef, ErrorHandlingOptions);
        end;
    end;

    procedure BatchProcess(var RecRef: RecordRef; ErrorHandlingOptions: Enum "Error Handling Options")
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        BatchProcessingMgtHandler: Codeunit "Batch Processing Mgt. Handler";
        Window: Dialog;
        CounterTotal: Integer;
        CounterToPost: Integer;
        CounterPosted: Integer;
        BatchConfirm: Option " ",Skip,Update;
        FullBatchProcessed: Boolean;
    begin
        if ProcessingCodeunitID = 0 then
            Error(ProcessingCodeunitNotSetErr);

        OnBeforeBatchProcess(RecRef);

        if RecRef.IsEmpty() then
            exit;

        BindSubscription(BatchProcessingMgtHandler);

        FillBatchProcessingMap(RecRef);
        Commit();

        RecRef.CurrentKeyIndex(1);
        RecRef.FindSet();

        if GuiAllowed() then
            Window.Open(PostingTemplateMsg);
        CounterTotal := RecRef.Count();

        if ErrorMessageMgt.Activate(ErrorMessageHandler) then
            ErrorMessageMgt.PushContext(ErrorContextElement, RecRef.Number, 0, StrSubstNo(BatchProcessingTxt, RecRef.Caption));
        if not BatchShouldBeProcessedInBackground(RecRef, FullBatchProcessed) then
            repeat
                CounterToPost += 1;
                if GuiAllowed() then
                    Window.Update(1, Round(CounterToPost / CounterTotal * 10000, 1));

                if CanProcessRecord(RecRef) then
                    if ProcessRecord(RecRef, BatchConfirm) then begin
                        CounterPosted += 1;
                        OnBatchProcessOnAfterIncreaseCounterPosted(RecRef, ProcessingCodeunitID);
                    end;
            until RecRef.Next() = 0;

        OnBatchProcessOnBeforeResetBatchID(RecRef, ProcessingCodeunitID);

        UnbindSubscription(BatchProcessingMgtHandler);

        ResetBatchID();

        IsHandled := false;
        OnBatchProcessOnBeforeShowMessage(CounterPosted, CounterTotal, IsHandled, ErrorMessageHandler, ErrorMessageMgt, FullBatchProcessed);

        if GuiAllowed then begin
            Window.Close();
            if not IsHandled then
                if (CounterPosted <> CounterTotal) and not FullBatchProcessed then begin
                    ErrorMessageHandler.InformAboutErrors(ErrorHandlingOptions);
                    ErrorMessageMgt.PopContext(ErrorContextElement);
                end else
                    Message(BatchCompletedMsg);
        end;

        OnAfterBatchProcess(RecRef, CounterPosted, ProcessingCodeunitID);
    end;

    procedure BatchProcessGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingCodeunitId: Integer)
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        BatchProcessingMgtHandler: Codeunit "Batch Processing Mgt. Handler";
        ICOutboxExport: Codeunit "IC Outbox Export";
        PostingResult: Boolean;
    begin
        OnBeforeBatchProcessGenJournalLine(GenJournalLine);
        Commit();
        ErrorMessageMgt.Activate(ErrorMessageHandler);

        BindSubscription(BatchProcessingMgtHandler);
        PostingResult := Codeunit.Run(PostingCodeunitId, GenJournalLine);
        if PostingResult then
            ICOutboxExport.DownloadBatchFiles(GetICBatchFileName());
        UnbindSubscription(BatchProcessingMgtHandler);

        if not PostingResult then begin
            ErrorMessageHandler.ShowErrors();
            LogFailurePostTelemetry(GenJournalLine);
        end;
    end;

    local procedure GetICBatchFileName() Result: Text
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
    end;

    local procedure LogFailurePostTelemetry(var GenJournalLine: Record "Gen. Journal Line")
    var
        ErrorMessage: Record "Error Message";
        Dimensions: Dictionary of [Text, Text];
        ErrorMessageTxt: Text;
    begin
        ErrorMessage.SetRange("Context Table Number", Database::"Gen. Journal Line");
        if ErrorMessage.FindLast() then
            ErrorMessageTxt := ErrorMessage."Message";
        Dimensions.Add('Category', TelemetryCategoryTxt);
        Dimensions.Add('Error', ErrorMessageTxt);
        Session.LogMessage('0000F9J', StrSubstNo(GenJournalPostFailedTxt, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    local procedure CanProcessRecord(var RecRef: RecordRef): Boolean
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
        Result: Boolean;
    begin
        Result := true;
        OnVerifyRecord(RecRef, Result);

        if not Result then
            if GetLastErrorText <> '' then begin
                ErrorMessageMgt.LogError(RecRef.RecordId, GetLastErrorText, '');
                ClearLastError();
            end;
        exit(Result);
    end;

    procedure FillBatchProcessingMap(var RecRef: RecordRef)
    begin
        RecRef.FindSet();
        repeat
            DeleteLostParameters(RecRef.RecordId);
            InsertBatchProcessingSessionMapEntry(RecRef);
        until RecRef.Next() = 0;
    end;

    procedure GetErrorMessages(var TempErrorMessageResult: Record "Error Message" temporary)
    var
        ErrorMessageMgt: Codeunit "Error Message Management";
    begin
        ErrorMessageMgt.GetErrors(TempErrorMessageResult);
    end;

    local procedure InsertBatchProcessingSessionMapEntry(RecRef: RecordRef)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        if IsNullGuid(BatchIDGlobal) then
            exit;

        BatchProcessingSessionMap.Init();
        BatchProcessingSessionMap."Record ID" := RecRef.RecordId;
        BatchProcessingSessionMap."Batch ID" := BatchIDGlobal;
        BatchProcessingSessionMap."User ID" := UserSecurityId();
        BatchProcessingSessionMap."Session ID" := SessionId();
        BatchProcessingSessionMap.Insert();
    end;

    local procedure InvokeProcessing(var RecRef: RecordRef): Boolean
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        RecVar: Variant;
        Result: Boolean;
    begin
        ClearLastError();

        BatchProcessingMgt.SetRecRefForCustomProcessing(RecRef);
        Result := BatchProcessingMgt.Run();
        BatchProcessingMgt.GetRecRefForCustomProcessing(RecRef);

        RecVar := RecRef;

        if (GetLastErrorCallstack = '') and Result and not BatchProcessingMgt.GetIsCustomProcessingHandled() then begin
            ErrorMessageMgt.PushContext(
              ErrorContextElement, RecRef.RecordId, 0, StrSubstNo(ProcessingMsg, ProcessingCodeunitID, RecRef.RecordId));
            OnInvokeProcessingOnBeforeRunProcessingCodeunitID(RecRef);
            Result := CODEUNIT.Run(ProcessingCodeunitID, RecVar);
            OnInvokeProcessingOnAfterRunProcessingCodeunitID(RecRef);
        end;
        if BatchProcessingMgt.GetIsCustomProcessingHandled() then
            KeepParameters := BatchProcessingMgt.GetKeepParameters();
        if not Result then
            if GetLastErrorText <> '' then begin
                ErrorMessageMgt.LogError(RecVar, GetLastErrorText, '');
                ErrorMessageMgt.PopContext(ErrorContextElement);
                ClearLastError();
            end;

        RecRef.GetTable(RecVar);

        exit(Result);
    end;

    local procedure RunCustomProcessing()
    var
        Handled: Boolean;
        KeepParametersLocal: Boolean;
    begin
        OnCustomProcessing(RecRefCustomerProcessing, Handled, KeepParametersLocal);
        IsCustomProcessingHandled := Handled;
        KeepParameters := KeepParametersLocal;
    end;

    local procedure InitBatchID()
    begin
        if IsNullGuid(BatchIDGlobal) then
            BatchIDGlobal := CreateGuid();
    end;

    local procedure ProcessRecord(var RecRef: RecordRef; var BatchConfirm: Option): Boolean
    var
        ProcessingResult: Boolean;
    begin
        OnBeforeBatchProcessing(RecRef, BatchConfirm);

        ProcessingResult := InvokeProcessing(RecRef);

        OnAfterBatchProcessing(RecRef, ProcessingResult);

        exit(ProcessingResult);
    end;

    procedure ResetBatchID()
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        if not KeepParameters then begin
            BatchProcessingParameter.SetRange("Batch ID", BatchIDGlobal);
            BatchProcessingParameter.DeleteAll();

            BatchProcessingSessionMap.SetRange("Batch ID", BatchIDGlobal);
            BatchProcessingSessionMap.DeleteAll();
        end;

        Clear(BatchIDGlobal);

        Commit();
    end;

    procedure AddArtifact(ArtifactType: Enum "Batch Processing Artifact Type"; ArtifactName: Text[1024]; var TempBlobArtivactValue: Codeunit "Temp Blob")
    begin
        OnAddArtifact(BatchIDGlobal, ArtifactType, ArtifactName, TempBlobArtivactValue);
    end;

    procedure HasArtifacts(ArtifactType: Enum "Batch Processing Artifact Type") Result: Boolean
    begin
        OnHasArtifacts(ArtifactType, Result);
    end;

    procedure GetArtifacts(ArtifactType: Enum "Batch Processing Artifact Type"; var TempBatchProcessingArtifact: Record "Batch Processing Artifact" temporary) Result: Boolean
    begin
        OnGetArtifacts(ArtifactType, TempBatchProcessingArtifact, Result);
    end;

    procedure DeleteBatchProcessingSessionMapForRecordId(RecordIdToClean: RecordId)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Batch ID", BatchIDGlobal);
        BatchProcessingSessionMap.SetRange("Record ID", RecordIdToClean);
        BatchProcessingSessionMap.DeleteAll();
    end;

    local procedure DeleteLostParameters(RecordID: RecordID)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
        BatchProcessingParameter: Record "Batch Processing Parameter";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", RecordId);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId());
        BatchProcessingSessionMap.SetRange("Session ID", SessionId());
        BatchProcessingSessionMap.SetFilter("Batch ID", '<>%1', BatchIDGlobal);
        if BatchProcessingSessionMap.FindSet() then begin
            repeat
                BatchProcessingParameter.SetRange("Batch ID", BatchProcessingSessionMap."Batch ID");
                if not BatchProcessingParameter.IsEmpty() then
                    BatchProcessingParameter.DeleteAll();
            until BatchProcessingSessionMap.Next() = 0;
            BatchProcessingSessionMap.DeleteAll();
        end;
    end;

    procedure SetParameter(ParameterId: Enum "Batch Posting Parameter Type"; Value: Variant)
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        IsProcessed: Boolean;
    begin
        InitBatchID();

        BatchProcessingParameter.Init();
        BatchProcessingParameter."Batch ID" := BatchIDGlobal;
        BatchProcessingParameter."Parameter Id" := ParameterId.AsInteger();
        BatchProcessingParameter."Parameter Value" := Format(Value);

        IsProcessed := false;
        OnSetParameterOnBeforeParameterInsert(BatchProcessingParameter, IsProcessed);
        if not IsProcessed then
            BatchProcessingParameter.Insert();
    end;

    procedure SetParametersForPageID(PageID: Integer)
    var
        UserSetup: Record "User Setup";
        DoInvoicePurchase: Boolean;
        DoInvoiceSales: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetParametersForPageID(PageID, IsHandled);
        if IsHandled then
            exit;

        DoInvoicePurchase := true;
        DoInvoiceSales := true;
        if UserId <> '' then begin
            UserSetup.SetLoadFields("Purch. Invoice Posting Policy", "Sales Invoice Posting Policy");
            if UserSetup.Get(UserId) then begin
                DoInvoicePurchase := UserSetup."Purch. Invoice Posting Policy" <> UserSetup."Purch. Invoice Posting Policy"::Prohibited;
                DoInvoiceSales := UserSetup."Sales Invoice Posting Policy" <> UserSetup."Sales Invoice Posting Policy"::Prohibited;
            end;
        end;

        case PageID of
            Page::"Purchase Order List", Page::"Sales Return Order List":
                begin
                    SetParameter("Batch Posting Parameter Type"::Invoice, ((PageID = Page::"Purchase Order List") and DoInvoicePurchase) or ((PageID = Page::"Sales Return Order List") and DoInvoiceSales));
                    SetParameter("Batch Posting Parameter Type"::Receive, true);
                end;

            Page::"Sales Order List", Page::"Purchase Return Order List":
                begin
                    SetParameter("Batch Posting Parameter Type"::Invoice, ((PageID = Page::"Purchase Return Order List") and DoInvoicePurchase) or ((PageID = Page::"Sales Order List") and DoInvoiceSales));
                    SetParameter("Batch Posting Parameter Type"::Ship, true);
                end;
        end;
    end;

    procedure GetTextParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Text[250]): Boolean
    var
        BatchProcessingParameter: Record "Batch Processing Parameter";
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", RecordId);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId());
        BatchProcessingSessionMap.SetRange("Session ID", SessionId());

        if not BatchProcessingSessionMap.FindFirst() then
            exit(false);

        if not BatchProcessingParameter.Get(BatchProcessingSessionMap."Batch ID", ParameterId) then
            exit(false);

        ParameterValue := BatchProcessingParameter."Parameter Value";
        exit(true);
    end;

    procedure GetBooleanParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Boolean): Boolean
    var
        Result: Boolean;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure GetIntegerParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Integer): Boolean
    var
        Result: Integer;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure GetDateParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Date): Boolean
    var
        Result: Date;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure GetTimeParameter(RecordID: RecordID; ParameterId: Enum "Batch Posting Parameter Type"; var ParameterValue: Time): Boolean
    var
        Result: Time;
        Value: Text[250];
    begin
        if not GetTextParameter(RecordID, ParameterId, Value) then
            exit(false);

        if not Evaluate(Result, Value) then
            exit(false);

        ParameterValue := Result;
        exit(true);
    end;

    procedure IsActive() Result: Boolean
    begin
        OnSystemSetBatchProcessingActive(Result);
    end;

    procedure GetIsCustomProcessingHandled(): Boolean
    begin
        exit(IsCustomProcessingHandled);
    end;

    procedure GetKeepParameters(): Boolean
    begin
        exit(KeepParameters);
    end;

    procedure GetRecRefForCustomProcessing(var RecRef: RecordRef)
    begin
        RecRef := RecRefCustomerProcessing;
    end;

    procedure GetBatchFromSession(SourceRecordID: RecordID; SourceSessionID: Integer)
    var
        BatchProcessingSessionMap: Record "Batch Processing Session Map";
    begin
        BatchProcessingSessionMap.SetRange("Record ID", SourceRecordID);
        BatchProcessingSessionMap.SetRange("Session ID", SourceSessionID);
        BatchProcessingSessionMap.SetRange("User ID", UserSecurityId());
        if BatchProcessingSessionMap.FindFirst() then begin
            BatchProcessingSessionMap."Session ID" := SessionId();
            BatchProcessingSessionMap.Modify();
        end;
        BatchIDGlobal := BatchProcessingSessionMap."Batch ID";
    end;

    procedure SetRecRefForCustomProcessing(RecRef: RecordRef)
    begin
        RecRefCustomerProcessing := RecRef;
    end;

    procedure SetProcessingCodeunit(NewProcessingCodeunitID: Integer)
    begin
        ProcessingCodeunitID := NewProcessingCodeunitID;
    end;

    local procedure BatchShouldBeProcessedInBackground(var RecRef: RecordRef; var FullBatchProcessed: Boolean): Boolean
    var
        IsProcessed: Boolean;
        SkippedRecordExists: Boolean;
    begin
        IsProcessed := false;
        OnBeforeBatchShouldBeProcessedInBackground(RecRef, IsProcessed);
        if IsProcessed then
            exit(false);

        if not IsPostWithJobQueueEnabled() then
            exit(false);

        ProcessBatchInBackground(RecRef, SkippedRecordExists);
        FullBatchProcessed := not SkippedRecordExists;

        exit(true);
    end;

    local procedure IsPostWithJobQueueEnabled() Result: Boolean
    begin
        OnIsPostWithJobQueueEnabled(Result);
    end;

    local procedure ProcessBatchInBackground(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    begin
        OnProcessBatchInBackground(RecRef, SkippedRecordExists);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBatchProcess(var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBatchProcessGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetParametersForPageID(PageID: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBatchProcess(var RecRef: RecordRef; var CounterPosted: Integer; ProcessingCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterBatchProcessing(var RecRef: RecordRef; PostingResult: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBatchProcessOnBeforeShowMessage(CounterPosted: Integer; CounterTotal: Integer; var IsHandled: Boolean; var ErrorMessageHandler: Codeunit "Error Message Handler"; var ErrorMessageMgt: Codeunit "Error Message Management"; FullBatchProcessed: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBatchProcessOnBeforeResetBatchID(var RecRef: RecordRef; ProcessingCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBatchProcessOnAfterIncreaseCounterPosted(var RecRef: RecordRef; ProcessingCodeunitID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBatchShouldBeProcessedInBackground(var RecRef: RecordRef; var IsProcessed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsPostWithJobQueueEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetParameterOnBeforeParameterInsert(BatchProcessingParameter: Record "Batch Processing Parameter"; var IsProcessed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessBatchInBackground(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnSystemSetBatchProcessingActive(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnAddArtifact(BatchID: Guid; ArtifactType: Enum "Batch Processing Artifact Type"; ArtifactName: Text[1024]; var TempBlobArtifactValue: Codeunit "Temp Blob")
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnHasArtifacts(ArtifactType: Enum "Batch Processing Artifact Type"; var Result: Boolean)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnGetArtifacts(ArtifactType: Enum "Batch Processing Artifact Type"; var TempBatchProcessingArtifactResult: Record "Batch Processing Artifact" temporary; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeProcessingOnBeforeRunProcessingCodeunitID(RecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvokeProcessingOnAfterRunProcessingCodeunitID(RecordRef: RecordRef)
    begin
    end;

}

