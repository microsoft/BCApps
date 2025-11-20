// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Finance.Analysis;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Intercompany.Outbox;
using Microsoft.Inventory.Analysis;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Automation;
using System.Threading;
using System.Utilities;

codeunit 1371 "Sales Batch Post Mgt."
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Batch Processing Parameter" = rimd,
                  TableData "Batch Processing Session Map" = rimd;
    TableNo = "Sales Header";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        UpdateAnalysisView: Codeunit "Update Analysis View";
        UpdateItemAnalysisView: Codeunit "Update Item Analysis View";
    begin
        SalesHeader.Copy(Rec);

        BindSubscription(SalesBatchPostMgt);  // also disables automatic update of Analysis Views
        SalesBatchPostMgt.SetPostingCodeunitId(PostingCodeunitId);
        SalesBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        SalesBatchPostMgt.Code(SalesHeader);
        Rec := SalesHeader;
        UnBindSubscription(SalesBatchPostMgt);  // reenable automatic update of Analysis Views

        UpdateAnalysisView.UpdateAll(0, true);
        UpdateItemAnalysisView.UpdateAll(0, true);
    end;

    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        PostingCodeunitId: Integer;
        PostingDateIsNotSetErr: Label 'Enter the posting date.';
        BatchPostingMsg: Label 'Batch posting of sales documents.';
        ApprovalPendingErr: Label 'Cannot post sales document no. %1 of type %2 because it is pending approval.', Comment = '%1 = Document No.; %2 = Document Type';
        ApprovalWorkflowErr: Label 'Cannot post sales document no. %1 of type %2 due to the approval workflow.', Comment = '%1 = Document No.; %2 = Document Type';
        InterCompanyZipFileNamePatternTok: Label 'Sales IC Batch - %1.zip', Comment = '%1 - today date, Sample: Sales IC Batch - 23-01-2024.zip';
        ProcessBarMsg: Label 'Processing: @1@@@@@@@', Comment = '1 - overall progress';

    procedure RunBatch(var SalesHeader: Record "Sales Header"; ReplacePostingDate: Boolean; PostingDate: Date; ReplaceDocumentDate: Boolean; CalcInvoiceDiscount: Boolean; Ship: Boolean; Invoice: Boolean)
    var
        TempErrorMessage: Record "Error Message" temporary;
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        ErrorMessages: Page "Error Messages";
    begin
        OnBeforeRunBatch(SalesHeader, ReplacePostingDate, PostingDate, ReplaceDocumentDate, Ship, Invoice);

        if ReplacePostingDate and (PostingDate = 0D) then
            Error(PostingDateIsNotSetErr);

        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Invoice, Invoice);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::Ship, Ship);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);
        OnRunBatchOnAfterAddParameters(BatchProcessingMgt, SalesBatchPostMgt, PostingCodeunitId);

        SalesBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if SalesBatchPostMgt.Run(SalesHeader) then;
        BatchProcessingMgt.ResetBatchID();
        if GuiAllowed then begin
            BatchProcessingMgt.GetErrorMessages(TempErrorMessage);

            if TempErrorMessage.FindFirst() then begin
                ErrorMessages.SetRecords(TempErrorMessage);
                ErrorMessages.Run();
            end;
        end;
    end;

    procedure RunWithUI(var SalesHeader: Record "Sales Header"; TotalCount: Integer; Question: Text)
    var
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWithUI(SalesHeader, TotalCount, Question, IsHandled);
        if IsHandled then
            exit;

        if not Confirm(StrSubstNo(Question, SalesHeader.Count, TotalCount), true) then
            exit;

        ErrorMessageMgt.Activate(ErrorMessageHandler);
        ErrorMessageMgt.PushContext(ErrorContextElement, DATABASE::"Sales Header", 0, BatchPostingMsg);
        SalesBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
        Commit();
        if SalesBatchPostMgt.Run(SalesHeader) then;
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

    procedure "Code"(var SalesHeader: Record "Sales Header")
    var
        RecRef: RecordRef;
    begin
        if PostingCodeunitId = 0 then
            PostingCodeunitId := CODEUNIT::"Sales-Post";

        RecRef.GetTable(SalesHeader);

        BatchProcessingMgt.SetProcessingCodeunit(PostingCodeunitId);
        BatchProcessingMgt.BatchProcess(RecRef);

        RecRef.SetTable(SalesHeader);
    end;

    local procedure GetICBatchFileName() Result: Text
    begin
        Result := StrSubstNo(InterCompanyZipFileNamePatternTok, Format(WorkDate(), 10, '<Year4>-<Month,2>-<Day,2>'));

        OnGetICBatchFileName(Result);
    end;

    local procedure PrepareSalesHeader(var SalesHeader: Record "Sales Header"; var BatchConfirm: Option)
    var
        CalcInvoiceDiscount: Boolean;
        ReplacePostingDate, ReplaceVATDate, ReplaceDocumentDate : Boolean;
        ManualReopen: Boolean;
        PostingDate, VATDate : Date;
    begin
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Calculate Invoice Discount", CalcInvoiceDiscount);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Posting Date", ReplacePostingDate);
        BatchProcessingMgt.GetDateParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Posting Date", PostingDate);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace VAT Date", ReplaceVATDate);
        BatchProcessingMgt.GetDateParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::"VAT Date", VATDate);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::"Replace Document Date", ReplaceDocumentDate);

        if CalcInvoiceDiscount then
            CalculateInvoiceDiscount(SalesHeader);

        SalesHeader.BatchConfirmUpdateDeferralDate(BatchConfirm, ReplacePostingDate, PostingDate, ReplaceVATDate, VATDate);
        PerformManualReleaseOrReopenSalesHeader(SalesHeader, ManualReopen, ReplacePostingDate, PostingDate);
        SalesHeader.BatchConfirmUpdatePostingDate(ReplacePostingDate, PostingDate, ReplaceVATDate, VATDate, ReplaceDocumentDate);
        PerformManualReleaseOrReopenSalesHeader(SalesHeader, ManualReopen, ReplacePostingDate, PostingDate);
        OnPrepareSalesHeaderOnAfterBatchConfirmUpdateDeferralDate(SalesHeader, BatchProcessingMgt);

        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::Ship, SalesHeader.Ship);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::Invoice, SalesHeader.Invoice);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::Receive, SalesHeader.Receive);
        BatchProcessingMgt.GetBooleanParameter(SalesHeader.RecordId, Enum::"Batch Posting Parameter Type"::Print, SalesHeader."Print Posted Documents");

        OnAfterPrepareSalesHeader(SalesHeader, BatchProcessingMgt);
    end;

    procedure SetPostingCodeunitId(NewPostingCodeunitId: Integer)
    begin
        PostingCodeunitId := NewPostingCodeunitId;
    end;

    local procedure CalculateInvoiceDiscount(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindFirst() then begin
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            Commit();
            SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        end;
    end;

    local procedure CanPostDocument(var SalesHeader: Record "Sales Header") Result: Boolean
    begin
        if not CheckApprovalWorkflow(SalesHeader) then
            exit(false);

        if not SalesHeader.IsApprovedForPostingBatch() then
            exit(false);

        Result := true;
        OnAfterCanPostDocument(SalesHeader, BatchProcessingMgt, Result);
    end;

    [TryFunction]
    local procedure CheckApprovalWorkflow(var SalesHeader: Record "Sales Header")
    var
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
    begin
        if ApprovalsMgmt.IsSalesApprovalsWorkflowEnabled(SalesHeader) then
            Error(ApprovalWorkflowErr, SalesHeader."No.", SalesHeader."Document Type");

        if SalesHeader.Status = SalesHeader.Status::"Pending Approval" then
            Error(ApprovalPendingErr, SalesHeader."No.", SalesHeader."Document Type");
    end;

    procedure SetParameter(ParameterId: Enum "Batch Posting Parameter Type"; ParameterValue: Variant)
    var
        ResultBatchProcessingMgt: Codeunit "Batch Processing Mgt.";
    begin
        GetBatchProcessor(ResultBatchProcessingMgt);
        ResultBatchProcessingMgt.SetParameter(ParameterId, ParameterValue);
    end;

    local procedure ProcessBatchInBackground(var SalesHeader: Record "Sales Header"; var SkippedRecordExists: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        SalesPostBatchviaJobQueue: Codeunit "Sales Post Batch via Job Queue";
    begin
        PrepareBatch(SalesHeader, JobQueueEntry, SkippedRecordExists);
        SalesPostBatchviaJobQueue.EnqueueSalesBatch(SalesHeader, JobQueueEntry);
    end;

    local procedure PrepareBatch(var SalesHeader: Record "Sales Header"; var JobQueueEntry: Record "Job Queue Entry"; var SkippedRecordExists: Boolean)
    var
        ErrorMessageManagement: Codeunit "Error Message Management";
        Window: Dialog;
        BatchConfirm: Option;
        DocCounter: array[2] of Integer;
    begin
        if SalesHeader.FindSet() then begin
            if GuiAllowed then begin
                DocCounter[1] := SalesHeader.Count;
                Window.Open(ProcessBarMsg);
            end;

            repeat
                if GuiAllowed then begin
                    DocCounter[2] += 1;
                    Window.Update(1, Round(DocCounter[2] / DocCounter[1] * 10000, 1));
                end;

                if CanProcessSalesHeader(SalesHeader) then begin
                    PrepareSalesHeader(SalesHeader, BatchConfirm);
                    PrepareJobQueueEntry(JobQueueEntry);
                    SalesHeader."Job Queue Entry ID" := JobQueueEntry.ID;
                    SalesHeader."Job Queue Status" := SalesHeader."Job Queue Status"::"Scheduled for Posting";
                    SalesHeader.Modify();
                    Commit();
                end else begin
                    SkippedRecordExists := true;
                    if GetLastErrorText <> '' then begin
                        ErrorMessageManagement.LogError(SalesHeader.RecordId, GetLastErrorText, '');
                        ClearLastError();
                    end;
                end;
            until SalesHeader.Next() = 0;

            if GuiAllowed then
                Window.Close();
        end;
    end;

    local procedure CanProcessSalesHeader(var SalesHeader: Record "Sales Header"): Boolean
    begin
        if not CheckSalesHeaderJobQueueStatus(SalesHeader) then
            exit(false);

        if not CanPostDocument(SalesHeader) then
            exit(false);

        if not ReleaseSalesHeader(SalesHeader) then
            exit(false);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckSalesHeaderJobQueueStatus(var SalesHeader: Record "Sales Header")
    begin
        if not (SalesHeader."Job Queue Status" in [SalesHeader."Job Queue Status"::" ", SalesHeader."Job Queue Status"::Error]) then
            SalesHeader.FieldError("Job Queue Status");
    end;

    local procedure ReleaseSalesHeader(var SalesHeader: Record "Sales Header") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReleaseSalesHeader(SalesHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SalesHeader.Status = SalesHeader.Status::Open then
            if not Codeunit.Run(Codeunit::"Release Sales Document", SalesHeader) then
                exit(false);
        exit(true);
    end;

    local procedure PrepareJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsNullGuid(JobQueueEntry.ID) then
            exit;

        Clear(JobQueueEntry);
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry.Insert(true);
    end;

    local procedure PerformManualReleaseOrReopenSalesHeader(var SalesHeader: Record "Sales Header"; var ManualReopen: Boolean; ReplacePostingDate: Boolean; PostingDate: Date)
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        if (not ReplacePostingDate) or (SalesHeader."Currency Code" = '') then
            exit;
        if (SalesHeader."Posting Date" = PostingDate) and (not ManualReopen) then
            exit;
        if not SalesHeader.Invoice and not (SalesHeader."Document Type" in [SalesHeader."Document Type"::Invoice, SalesHeader."Document Type"::Order]) then
            exit;

        if ManualReopen then
            ReleaseSalesHeader(SalesHeader)
        else
            if SalesHeader.Status = SalesHeader.Status::Released then begin
                ReleaseSalesDoc.PerformManualReopen(SalesHeader);
                ManualReopen := true;
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBeforeBatchProcessing', '', false, false)]
    local procedure PrepareSalesHeaderOnBeforeBatchProcessing(var RecRef: RecordRef; var BatchConfirm: Option)
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        PrepareSalesHeader(SalesHeader, BatchConfirm);
        RecRef.GetTable(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnVerifyRecord', '', false, false)]
    local procedure CheckSalesHeaderOnVerifyRecord(var RecRef: RecordRef; var Result: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        Result := CanPostDocument(SalesHeader);
        RecRef.GetTable(SalesHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnCustomProcessing', '', false, false)]
    local procedure HandleOnCustomProcessing(var RecRef: RecordRef; var Handled: Boolean; var KeepParameters: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesPostViaJobQueue: Codeunit "Sales Post via Job Queue";
    begin
        RecRef.SetTable(SalesHeader);

        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Post with Job Queue" then begin
            SalesHeader."Print Posted Documents" :=
              SalesHeader."Print Posted Documents" and SalesReceivablesSetup."Post & Print with Job Queue";
            SalesPostViaJobQueue.EnqueueSalesDocWithUI(SalesHeader, false);
            if not IsNullGuid(SalesHeader."Job Queue Entry ID") then begin
                Commit();
                KeepParameters := true;
            end;
            SalesHeader."Print Posted Documents" := false;
            RecRef.GetTable(SalesHeader);
            Handled := true;
        end;

        OnAfterHandleOnCustomProcessing(RecRef, SalesHeader, BatchProcessingMgt, Handled, KeepParameters);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCanPostDocument(var SalesHeader: Record "Sales Header"; var BatchProcessingMgt: Codeunit "Batch Processing Mgt."; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHandleOnCustomProcessing(var RecRef: RecordRef; var SalesHeader: Record "Sales Header"; var BatchProcessingMgt: Codeunit "Batch Processing Mgt."; var Handled: Boolean; var KeepParameters: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareSalesHeader(var SalesHeader: Record "Sales Header"; var BatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunBatch(var SalesHeader: Record "Sales Header"; var ReplacePostingDate: Boolean; var PostingDate: Date; var ReplaceDocumentDate: Boolean; var Ship: Boolean; var Invoice: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrepareSalesHeaderOnAfterBatchConfirmUpdateDeferralDate(var SalesHeader: Record "Sales Header"; var BatchProcessingMgt: Codeunit "Batch Processing Mgt.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunBatchOnAfterAddParameters(var BatchProcessingMgt: Codeunit "Batch Processing Mgt."; var SalesBatchPostMgt: Codeunit "Sales Batch Post Mgt."; PostingCodeunitId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetICBatchFileName(var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesHeader(var SalesHeader: Record "Sales Header"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeRunWithUI(var SalesHeader: Record "Sales Header"; TotalCount: Integer; Question: Text; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnIsPostWithJobQueueEnabled', '', false, false)]
    local procedure OnIsPostWithJobQueueEnabledHandler(var Result: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        Result := SalesReceivablesSetup."Post with Job Queue";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnProcessBatchInBackground', '', false, false)]
    local procedure OnProcessBatchInBackgroundHandler(var RecRef: RecordRef; var SkippedRecordExists: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        RecRef.SetTable(SalesHeader);
        ProcessBatchInBackground(SalesHeader, SkippedRecordExists);
        RecRef.GetTable(SalesHeader);
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

