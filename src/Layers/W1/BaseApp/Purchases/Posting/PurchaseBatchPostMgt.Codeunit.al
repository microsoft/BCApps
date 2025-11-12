// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Intercompany.Outbox;
using Microsoft.Inventory.Analysis;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using System.Automation;
using System.Threading;
using System.Utilities;

codeunit 1372 "Purchase Batch Post Mgt."
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    TableNo = "Purchase Header";

    trigger OnRun()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        PurchaseHeader.Copy(Rec);

        BindSubscription(PurchaseBatchPostMgt);  // also disables automatic update of Analysis Views
        PurchaseBatchPostMgt.SetPostingCodeunitId(PostingCodeunitId);
        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        PurchaseBatchPostMgt.Code(PurchaseHeader);
        Rec := PurchaseHeader;
        UnBindSubscription(PurchaseBatchPostMgt);  // reenable automatic update of Analysis Views

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingCodeunitId: Integer;
        PostingDateIsNotSetErr: Label 'Enter the posting date.';
        BatchPostingMsg: Label 'Batch posting of purchase documents.';
        ApprovalPendingErr: Label 'Cannot post purchase document no. %1 of type %2 because it is pending approval.', Comment = '%1 = Document No.; %2 = Document Type';
        ApprovalWorkflowErr: Label 'Cannot post purchase document no. %1 of type %2 due to the approval workflow.', Comment = '%1 = Document No.; %2 = Document Type';
        InterCompanyZipFileNamePatternTok: Label 'Purchase IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';
        ProcessBarMsg: Label 'Processing: @1@@@@@@@', Comment = '1 - overall progress';

    procedure RunBatch(var PurchaseHeader: Record "Purchase Header"; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; CalcInvoiceDiscount: Boolean; Receive: Boolean; Invoice: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
        ErrorMessages: Page "Error Messages";
    begin
        OnBeforeRunBatch(PurchaseHeader, ReplacePostingDate, PostingDate, ReplaceDocumentDate, Receive, Invoice);

        if ReplacePostingDate and (PostingDate = 0D) then
            Error(PostingDateIsNotSetErr);

        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Invoice, Invoice);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Receive, Receive);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);
        OnRunBatchOnAfterAddParameters(BatchProcessingMgt);

        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if PurchaseBatchPostMgt.Run(PurchaseHeader) then;
        BatchProcessingMgt.ResetBatchID();
        if GuiAllowed then begin
            BatchProcessingMgt.GetErrorMessages(TempErrorMessage);

            if TempErrorMessage.FindFirst() then begin
                ErrorMessages.SetRecords(TempErrorMessage);
                ErrorMessages.Run();
            end;
        end;

        OnAfterRunBatch(PurchaseHeader, TempErrorMessage);
    end;

    procedure RunWithUI(var PurchaseHeader: Record "Purchase Header"; TotalCount: Integer; Question: Text)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        PurchaseBatchPostMgt: Codeunit "Purchase Batch Post Mgt.";
    begin
        if not Confirm(StrSubstNo(Question, PurchaseHeader.Count, TotalCount), true) then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, DATABASE::"Purchase Header", 0, BatchPostingMsg);
        PurchaseBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if PurchaseBatchPostMgt.Run(PurchaseHeader) then;
        BatchProcessingMgt.ResetBatchID();

        if ErrorMessageMgt.GetLastErrorID() > 0 then
            ErrorMessageHandler.ShowErrors();
    end;

    procedure GetBatchProcessor(var ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        ResultBatchProcessingMgt := BatchProcessingMgt;
    end;

    procedure SetBatchProcessor(NewBatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
        BatchProcessingMgt := NewBatchProcessingMgt;
    end;

    procedure "Code"(var PurchaseHeader: Record "Purchase Header")
    var
        RecRef: RecordRef;
    begin
        if PostingCodeunitId = 0 then
            PostingCodeunitId := CODEUNIT::"Purch.-Post";

        RecRef.GetTable(PurchaseHeader);

        BatchProcessingMgt.SetProcessingCodeunit(PostingCodeunitId);
        BatchProcessingMgt.BatchProcess(RecRef);

        RecRef.SetTable(PurchaseHeader);
    end;

    local procedure GetICBatchFileName() Result: Text
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
    end;

    local procedure PreparePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var BatchConfirm: Option)
    var
        CalcInvoiceDiscount: Boolean;
        ReplacePostingDate, ReplaceVATDate, ReplaceDocumentDate : Boolean;
        PostingDate, VATDate : Date;
    begin
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.GetDateParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDate);
        BatchProcessingMgt.GetDateParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"VAT Date", VATDate);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);

        if CalcInvoiceDiscount then
            CalculateInvoiceDiscount(PurchaseHeader);

        PurchaseHeader.BatchConfirmUpdateDeferralDate(BatchConfirm, ReplacePostingDate, PostingDate, ReplaceVATDate, VATDate);
        PurchaseHeader.BatchConfirmUpdatePostingDate(ReplacePostingDate, PostingDate, ReplaceDocumentDate);

        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::Receive, PurchaseHeader.Receive);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::Invoice, PurchaseHeader.Invoice);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::Ship, PurchaseHeader.Ship);
        BatchProcessingMgt.GetBooleanParameter(PurchaseHeader.RecordId, Enum::"Batch Posting Parameter Type"::Print, PurchaseHeader."Print Posted Documents");

        OnAfterPreparePurchaseHeader(PurchaseHeader);
    end;

    procedure SetPostingCodeunitId(NewPostingCodeunitId: Integer)
    begin
        PostingCodeunitId := NewPostingCodeunitId;
    end;

    local procedure CalculateInvoiceDiscount(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchaseLine.FindFirst() then begin
            CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
            Commit();
            PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        end;
    end;

    local procedure CanPostDocument(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if not CheckApprovalWorkflow(PurchaseHeader) then
            exit(false);

        if not PurchaseHeader.IsApprovedForPostingBatch() then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckApprovalWorkflow(var PurchaseHeader: Record "Purchase Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsPurchaseApprovalsWorkflowEnabled(PurchaseHeader) then
            Error(ApprovalWorkflowErr, PurchaseHeader."No.", PurchaseHeader."Document Type");

        if PurchaseHeader.Status = PurchaseHeader.Status::"Pending Approval" then
            Error(ApprovalPendingErr, PurchaseHeader."No.", PurchaseHeader."Document Type");
    end;

    procedure SetParameter(ParameterId: Enum "Batch Posting Parameter Type"; ParameterValue: Variant)
    var
        ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        GetBatchProcessor(ResultBatchProcessingMgt);
        ResultBatchProcessingMgt.SetParameter(ParameterId, ParameterValue);
    end;

    local procedure ProcessBatchInBackground(var PurchaseHeader: Record "Purchase Header"; var SkippedRecordExists: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        PurchPostBatchviaJobQueue: Codeunit "Purch Post Batch via Job Queue";
    begin
        PrepareBatch(PurchaseHeader, JobQueueEntry, SkippedRecordExists);
        PurchPostBatchviaJobQueue.EnqueuePurchaseBatch(PurchaseHeader, JobQueueEntry);
    end;

    local procedure PrepareBatch(var PurchaseHeader: Record "Purchase Header"; var JobQueueEntry: Record "Job Queue Entry"; var SkippedRecordExists: Boolean)
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        Window: Dialog;
        BatchConfirm: Option;
        DocCounter: array[2] of Integer;
    begin
        if PurchaseHeader.FindSet() then begin
            if GuiAllowed then begin
                DocCounter[1] := PurchaseHeader.Count;
                Window.Open(ProcessBarMsg);
            end;

            repeat
                if GuiAllowed then begin
                    DocCounter[2] += 1;
                    Window.Update(1, Round(DocCounter[2] / DocCounter[1] * 10000, 1));
                end;

                if CanProcessPurchaseHeader(PurchaseHeader) then begin
                    PreparePurchaseHeader(PurchaseHeader, BatchConfirm);
                    PrepareJobQueueEntry(JobQueueEntry);
                    PurchaseHeader."Job Queue Entry ID" := JobQueueEntry.ID;
                    PurchaseHeader."Job Queue Status" := PurchaseHeader."Job Queue Status"::"Scheduled for Posting";
                    PurchaseHeader.Modify();
                    Commit();
                end else begin
                    SkippedRecordExists := true;
                    if GetLastErrorText <> '' then begin
                        ErrorMessageManagement.LogError(PurchaseHeader.RecordId, GetLastErrorText, '');
                        ClearLastError();
                    end;
                end;
            until PurchaseHeader.Next() = 0;

            if GuiAllowed then
                Window.Close();
        end;
    end;

    local procedure CanProcessPurchaseHeader(var PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if not CheckPurchaseHeaderJobQueueStatus(PurchaseHeader) then
            exit(false);

        if not CanPostDocument(PurchaseHeader) then
            exit(false);

        if not ReleasePurchaseHeader(PurchaseHeader) then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckPurchaseHeaderJobQueueStatus(var PurchaseHeader: Record "Purchase Header")
    begin
        if not (PurchaseHeader."Job Queue Status" in [PurchaseHeader."Job Queue Status"::" ", PurchaseHeader."Job Queue Status"::Error]) then
            PurchaseHeader.FieldError("Job Queue Status");
    end;

    local procedure ReleasePurchaseHeader(var PurchaseHeader: Record "Purchase Header"): Boolean
    var
        Result: Boolean;
    begin
        if PurchaseHeader.Status = PurchaseHeader.Status::Open then
            if not Codeunit.Run(Codeunit::"Release Purchase Document", PurchaseHeader) then
                exit(false);

        Result := true;
        OnAfterReleasePurchaseHeader(PurchaseHeader, Result);
        exit(Result);
    end;

    local procedure PrepareJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsNullGuid(JobQueueEntry.ID) then
            exit;

        Clear(JobQueueEntry);
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Insert(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBeforeBatchProcessing', '', false, false)]
    local procedure PreparePurchaseHeaderOnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        PreparePurchaseHeader(PurchaseHeader, BatchConfirm);
        RecRef.GetTable(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnVerifyRecord', '', false, false)]
    local procedure CheckPurchaseHeaderOnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        Result := CanPostDocument(PurchaseHeader);
        RecRef.GetTable(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnCustomProcessing', '', false, false)]
    local procedure HandleOnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchasePostViaJobQueue: Codeunit "Purchase Post via Job Queue";
    begin
        RecRef.SetTable(PurchaseHeader);

        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Post with Job Queue" then begin
            PurchaseHeader."Print Posted Documents" :=
                PurchaseHeader."Print Posted Documents" and PurchasesPayablesSetup."Post & Print with Job Queue";
            PurchasePostViaJobQueue.EnqueuePurchDocWithUI(PurchaseHeader, false);
            if not IsNullGuid(PurchaseHeader."Job Queue Entry ID") then begin
                Commit();
                KeepParameters := true;
            end;
            PurchaseHeader."Print Posted Documents" := false;
            RecRef.GetTable(PurchaseHeader);
            Handled := true;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPreparePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunBatch(var PurchaseHeader: Record "Purchase Header"; var TempErrorMessage: Record "Error Message" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunBatch(var PurchaseHeader: Record "Purchase Header"; var ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; Receive: Boolean; Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunBatchOnAfterAddParameters(var BatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleasePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; var Result: Boolean);
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnIsPostWithJobQueueEnabled', '', false, false)]
    local procedure OnIsPostWithJobQueueEnabledHandler(var Result: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        Result := PurchasesPayablesSetup."Post with Job Queue";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnProcessBatchInBackground', '', false, false)]
    local procedure OnProcessBatchInBackgroundHandler(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        RecRef.SetTable(PurchaseHeader);
        ProcessBatchInBackground(PurchaseHeader, SkippedRecordExists);
        RecRef.GetTable(PurchaseHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBatchProcessOnBeforeResetBatchID', '', false, false)]
    local procedure OnBatchProcessOnBeforeResetBatchID(var RecRef: RecordRef; ProcessingCodeunitID: Integer)
    var
        ICOutboxExport: Codeunit "IC Outbox Export";
    begin
        ICOutboxExport.DownloadBatchFiles(GetICBatchFileName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update Analysis View", 'OnBeforeUpdateAll', '', false, false)]
    local procedure OnBeforeUpdateAnalysisView(Which: Option "Ledger Entries","Budget Entries",Both; DirectlyFromPosting: Boolean; var AnalysisView: Record "Analysis View"; var InBatchPosting: Boolean)
    begin
        InBatchPosting := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Update Item Analysis View", 'OnBeforeUpdateAll', '', false, false)]
    local procedure OnBeforeUpdateItemAnalysisView(var IsHandled: Boolean)
    begin
        IsHandled := true;
    end;
}

