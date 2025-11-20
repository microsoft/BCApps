// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Threading;
using System.Utilities;

codeunit 85 "Sales Post Batch via Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        PostSalesBatch(Rec);
    end;

    var
        UnpostedDocumentsErr: Label '%1 sales documents out of %2 have errors during posting.', Comment = '%1 - number of documents with errors, %2 - total number of documents';
        UnprintedDocumentsErr: Label '%1 sales documents out of %2 have errors during printing.', Comment = '%1 - number of documents with errors, %2 - total number of documents';
        DefaultCategoryCodeLbl: Label 'SALESBCKGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background Sales Posting', Locked = true;
        PostingDescriptionTxt: Label 'Post sales documents batch.';
        PostAndPrintDescriptionTxt: Label 'Post and print sales documents batch.';
        PrintingDescriptionTxt: Label 'Print Sales %1 No. %2', Comment = '%1 - document type, %2 - document no.';

    local procedure PostSalesBatch(var JobQueueEntry: Record "Job Queue Entry")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        ErrorMessageManagement: Codeunit "Error Message Management";
        SavedLockTimeout: Boolean;
        TotalDocumentsCount: Integer;
        ErrorPostDocumentsCount: Integer;
        ErrorPrintDocumentsCount: Integer;
    begin
        SalesReceivablesSetup.Get();
        SavedLockTimeout := LockTimeout;
        SalesHeader.SetRange("Job Queue Entry ID", JobQueueEntry.ID);
        SalesHeader.SetRange("Job Queue Status", SalesHeader."Job Queue Status"::"Scheduled for Posting");
        if SalesHeader.FindSet() then
            repeat
                TotalDocumentsCount += 1;
                SetJobQueueStatus(SalesHeader, SalesHeader."Job Queue Status"::Posting);
                OnPostSalesBatchOnBeforeRunSalesPost(SalesHeader);
                if not Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then begin
                    SetJobQueueStatus(SalesHeader, SalesHeader."Job Queue Status"::Error);
                    ErrorMessageManagement.LogLastError();
                    ErrorPostDocumentsCount += 1;
                end else begin
                    OnPostSalesBatchOnAfterRunSalesPost(SalesHeader);
                    SetJobQueueStatus(SalesHeader, SalesHeader."Job Queue Status"::" ");
                    if SalesReceivablesSetup."Post & Print with Job Queue" then
                        if SalesHeader."Print Posted Documents" then
                            if not PrintSalesDocument(SalesHeader, JobQueueEntry) then
                                ErrorPrintDocumentsCount += 1;
                end;
            until SalesHeader.Next() = 0;
        LockTimeout(SavedLockTimeout);

        if (ErrorPostDocumentsCount <> 0) or (ErrorPrintDocumentsCount <> 0) then
            ThrowErrorMessage(TotalDocumentsCount, ErrorPostDocumentsCount, ErrorPrintDocumentsCount);
    end;

    procedure EnqueueSalesBatch(var SalesHeader: Record "Sales Header"; var JobQueueEntry: Record "Job Queue Entry")
    begin
        EnqueueJobQueueEntry(JobQueueEntry);
    end;

    local procedure EnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Sales Post Batch via Job Queue";
        JobQueueEntry."Notify On Success" := SalesReceivablesSetup."Notify On Success";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueCategoryCode();
        JobQueueEntry.Description := GetDescription();
        JobQueueEntry."User Session ID" := SessionId();
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure SetJobQueueStatus(var SalesHeader: Record "Sales Header"; NewStatus: Enum "Document Job Queue Status")
    begin
        SalesHeader.LockTable();
        if SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.") then begin
            SalesHeader."Job Queue Status" := NewStatus;
            SalesHeader.Modify();
            Commit();
        end;
    end;

    local procedure GetJobQueueCategoryCode(): Code[10]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobQueueCategory: Record "Job Queue Category";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Job Queue Category Code" <> '' then
            exit(SalesReceivablesSetup."Job Queue Category Code");

        JobQueueCategory.InsertRec(
            CopyStr(DefaultCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(DefaultCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
        exit(JobQueueCategory.Code);
    end;

    local procedure GetDescription(): Text[250]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Post & Print with Job Queue" then
            exit(PostAndPrintDescriptionTxt);
        exit(PostingDescriptionTxt);
    end;

    local procedure PrintSalesDocument(SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    if SalesHeader.Ship then
                        Result := PrintShipmentDocument(SalesHeader, JobQueueEntry);
                    if SalesHeader.Invoice then
                        Result := Result or PrintInvoiceDocument(SalesHeader, JobQueueEntry);
                end;
            SalesHeader."Document Type"::Invoice:
                Result := PrintInvoiceDocument(SalesHeader, JobQueueEntry);
            SalesHeader."Document Type"::"Credit Memo":
                Result := PrintCrMemoDocument(SalesHeader, JobQueueEntry);
        end;
    end;

    local procedure PrintShipmentDocument(SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        RecRef: RecordRef;
    begin
        SalesShipmentHeader."No." := SalesHeader."Last Shipping No.";
        SalesShipmentHeader.SetRecFilter();
        RecRef.GetTable(SalesShipmentHeader);
        Result := PrintDocument(Enum::"Report Selection Usage"::"S.Shipment", RecRef, SalesHeader, JobQueueEntry);
    end;

    local procedure PrintInvoiceDocument(SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RecRef: RecordRef;
    begin
        if SalesHeader."Last Posting No." = '' then
            SalesInvoiceHeader."No." := SalesHeader."No."
        else
            SalesInvoiceHeader."No." := SalesHeader."Last Posting No.";
        SalesInvoiceHeader.SetRecFilter();
        RecRef.GetTable(SalesInvoiceHeader);
        Result := PrintDocument(Enum::"Report Selection Usage"::"S.Invoice", RecRef, SalesHeader, JobQueueEntry);
    end;

    local procedure PrintCrMemoDocument(SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        RecRef: RecordRef;
    begin
        if SalesHeader."Last Posting No." = '' then
            SalesCrMemoHeader."No." := SalesHeader."No."
        else
            SalesCrMemoHeader."No." := SalesHeader."Last Posting No.";
        SalesCrMemoHeader.SetRecFilter();
        RecRef.GetTable(SalesCrMemoHeader);
        Result := PrintDocument(Enum::"Report Selection Usage"::"S.Cr.Memo", RecRef, SalesHeader, JobQueueEntry);
    end;

    local procedure PrintDocument(ReportUsage: Enum "Report Selection Usage"; RecRef: RecordRef; SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        ReportSelections: Record "Report Selections";
        ErrorMessageManagement: Codeunit "Error Message Management";
        PrintingErrorExists: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintDocument(ReportUsage, RecRef, SalesHeader, JobQueueEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.FindSet();
        repeat
            if CheckReportId(ReportSelections) then begin
                if not PrintToPDF(ReportSelections."Report ID", RecRef, SalesHeader, JobQueueEntry) then begin
                    ErrorMessageManagement.LogLastError();
                    PrintingErrorExists := true;
                end;
            end else begin
                ErrorMessageManagement.LogLastError();
                PrintingErrorExists := true;
            end;
        until ReportSelections.Next() = 0;

        Result := not PrintingErrorExists;
    end;

    local procedure PrintToPDF(ReportId: Integer; RecRef: RecordRef; SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        ReportInbox: Record "Report Inbox";
        OStream: OutStream;
        IsSuccess: Boolean;
        IsHandled: Boolean;
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := CopyStr(StrSubstNo(PrintingDescriptionTxt, SalesHeader."Document Type", SalesHeader."No."), 1, MaxStrLen(ReportInbox.Description));
        ReportInbox."Report Output".CreateOutStream(OStream);
        IsHandled := false;
        IsSuccess := false;
        OnPrintToPDFOnBeforeReportRun(ReportId, RecRef, OStream, IsSuccess, IsHandled);
        if not IsHandled then
            IsSuccess := Report.SaveAs(ReportId, '', ReportFormat::Pdf, OStream, RecRef);
        if not IsSuccess then
            exit(false);
        ReportInbox."Created Date-Time" := RoundDateTime(CurrentDateTime, 60000);
        ReportInbox.Insert(true);
        OnPrintToPDFOnAfterReportInboxInsert(ReportInbox, SalesHeader, RecRef);

        exit(true);
    end;

    [TryFunction]
    local procedure CheckReportId(ReportSelections: Record "Report Selections")
    begin
        ReportSelections.TestField("Report ID");
    end;

    local procedure ThrowErrorMessage(TotalDocumentsCount: Integer; ErrorPostDocumentsCount: Integer; ErrorPrintDocumentsCount: Integer)
    var
        ErrorMessage: Text;
    begin
        Commit();
        if ErrorPostDocumentsCount <> 0 then
            ErrorMessage := StrSubstNo(UnpostedDocumentsErr, ErrorPostDocumentsCount, TotalDocumentsCount) + ' ';
        if ErrorPrintDocumentsCount <> 0 then
            ErrorMessage += StrSubstNo(UnprintedDocumentsErr, ErrorPrintDocumentsCount, TotalDocumentsCount);
        ErrorMessage := DelChr(ErrorMessage, '>', ' ');
        Error(ErrorMessage);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintToPDFOnAfterReportInboxInsert(var ReportInbox: Record "Report Inbox"; var SalesHeader: Record "Sales Header"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintToPDFOnBeforeReportRun(ReportId: Integer; RecRef: RecordRef; var OStream: OutStream; var IsSuccess: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesBatchOnBeforeRunSalesPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalesBatchOnAfterRunSalesPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocument(ReportUsage: Enum "Report Selection Usage"; RecRef: RecordRef; SalesHeader: Record "Sales Header"; JobQueueEntry: Record "Job Queue Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
