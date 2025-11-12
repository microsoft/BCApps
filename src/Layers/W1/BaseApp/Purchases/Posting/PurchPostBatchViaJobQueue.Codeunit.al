// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using System.Threading;
using System.Utilities;

codeunit 95 "Purch Post Batch via Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        PostPurchaseBatch(Rec);
    end;

    var
        UnpostedDocumentsErr: Label '%1 purchase documents out of %2 have errors during posting.', Comment = '%1 - number of documents with errors, %2 - total number of documents';
        UnprintedDocumentsErr: Label '%1 purchase documents out of %2 have errors during printing.', Comment = '%1 - number of documents with errors, %2 - total number of documents';
        DefaultCategoryCodeLbl: Label 'PURCHBCKGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background Purch. Posting', Locked = true;
        PostingDescriptionTxt: Label 'Post purchase documents batch.';
        PostAndPrintDescriptionTxt: Label 'Post and print purchase documents batch.';
        PrintingDescriptionTxt: Label 'Print Purchase %1 No. %2', Comment = '%1 - document type, %2 - document no.';

    local procedure PostPurchaseBatch(var JobQueueEntry: Record "Job Queue Entry")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseHeader: Record "Purchase Header";
        ErrorMessageManagement: Codeunit "Error Message Management";
        SavedLockTimeout: Boolean;
        TotalDocumentsCount: Integer;
        ErrorPostDocumentsCount: Integer;
        ErrorPrintDocumentsCount: Integer;
    begin
        PurchasesPayablesSetup.Get();
        SavedLockTimeout := LockTimeout;
        PurchaseHeader.SetRange("Job Queue Entry ID", JobQueueEntry.ID);
        PurchaseHeader.SetRange("Job Queue Status", PurchaseHeader."Job Queue Status"::"Scheduled for Posting");
        if PurchaseHeader.FindSet() then
            repeat
                TotalDocumentsCount += 1;
                SetJobQueueStatus(PurchaseHeader, PurchaseHeader."Job Queue Status"::Posting);
                if not Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader) then begin
                    SetJobQueueStatus(PurchaseHeader, PurchaseHeader."Job Queue Status"::Error);
                    ErrorMessageManagement.LogLastError();
                    ErrorPostDocumentsCount += 1;
                end else begin
                    SetJobQueueStatus(PurchaseHeader, PurchaseHeader."Job Queue Status"::" ");
                    if PurchasesPayablesSetup."Post & Print with Job Queue" then
                        if PurchaseHeader."Print Posted Documents" then
                            if not PrintPurchaseDocument(PurchaseHeader, JobQueueEntry) then
                                ErrorPrintDocumentsCount += 1;
                end;
            until PurchaseHeader.Next() = 0;
        LockTimeout(SavedLockTimeout);

        if (ErrorPostDocumentsCount <> 0) or (ErrorPrintDocumentsCount <> 0) then
            ThrowErrorMessage(TotalDocumentsCount, ErrorPostDocumentsCount, ErrorPrintDocumentsCount);
    end;

    procedure EnqueuePurchaseBatch(var PurchaseHeader: Record "Purchase Header"; var JobQueueEntry: Record "Job Queue Entry")
    begin
        EnqueueJobQueueEntry(JobQueueEntry);
    end;

    local procedure EnqueueJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Purch Post Batch via Job Queue";
        JobQueueEntry."Notify On Success" := PurchasesPayablesSetup."Notify On Success";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueCategoryCode();
        JobQueueEntry.Description := GetDescription();
        JobQueueEntry."User Session ID" := SessionId();
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure SetJobQueueStatus(var PurchaseHeader: Record "Purchase Header"; NewStatus: Enum "Document Job Queue Status")
    begin
        PurchaseHeader.LockTable();
        if PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.") then begin
            PurchaseHeader."Job Queue Status" := NewStatus;
            PurchaseHeader.Modify();
            Commit();
        end;
    end;

    local procedure GetJobQueueCategoryCode(): Code[10]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        JobQueueCategory: Record "Job Queue Category";
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Job Queue Category Code" <> '' then
            exit(PurchasesPayablesSetup."Job Queue Category Code");

        JobQueueCategory.InsertRec(
            CopyStr(DefaultCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(DefaultCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
        exit(JobQueueCategory.Code);
    end;

    local procedure GetDescription(): Text[250]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        if PurchasesPayablesSetup."Post & Print with Job Queue" then
            exit(PostAndPrintDescriptionTxt);
        exit(PostingDescriptionTxt);
    end;

    local procedure PrintPurchaseDocument(PurchaseHeader: Record "Purchase Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    begin
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                begin
                    if PurchaseHeader.Receive then
                        Result := PrintReceiptDocument(PurchaseHeader, JobQueueEntry);
                    if PurchaseHeader.Invoice then
                        Result := Result or PrintInvoiceDocument(PurchaseHeader, JobQueueEntry);
                end;
            PurchaseHeader."Document Type"::Invoice:
                Result := PrintInvoiceDocument(PurchaseHeader, JobQueueEntry);
            PurchaseHeader."Document Type"::"Credit Memo":
                Result := PrintCrMemoDocument(PurchaseHeader, JobQueueEntry);
        end;
    end;

    local procedure PrintReceiptDocument(PurchaseHeader: Record "Purchase Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        RecRef: RecordRef;
    begin
        PurchRcptHeader."No." := PurchaseHeader."Last Receiving No.";
        PurchRcptHeader.SetRecFilter();
        RecRef.GetTable(PurchRcptHeader);
        Result := PrintDocument(Enum::"Report Selection Usage"::"P.Receipt", RecRef, PurchaseHeader, JobQueueEntry);
    end;

    local procedure PrintInvoiceDocument(PurchaseHeader: Record "Purchase Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RecRef: RecordRef;
    begin
        if PurchaseHeader."Last Posting No." = '' then
            PurchInvHeader."No." := PurchaseHeader."No."
        else
            PurchInvHeader."No." := PurchaseHeader."Last Posting No.";
        PurchInvHeader.SetRecFilter();
        RecRef.GetTable(PurchInvHeader);
        Result := PrintDocument(Enum::"Report Selection Usage"::"P.Invoice", RecRef, PurchaseHeader, JobQueueEntry);
    end;

    local procedure PrintCrMemoDocument(PurchaseHeader: Record "Purchase Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        RecRef: RecordRef;
    begin
        if PurchaseHeader."Last Posting No." = '' then
            PurchCrMemoHdr."No." := PurchaseHeader."No."
        else
            PurchCrMemoHdr."No." := PurchaseHeader."Last Posting No.";
        PurchCrMemoHdr.SetRecFilter();
        RecRef.GetTable(PurchCrMemoHdr);
        Result := PrintDocument(Enum::"Report Selection Usage"::"P.Cr.Memo", RecRef, PurchaseHeader, JobQueueEntry);
    end;

    local procedure PrintDocument(ReportUsage: Enum "Report Selection Usage"; RecRef: RecordRef; PurchaseHeader: Record "Purchase Header"; JobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        ReportSelections: Record "Report Selections";
        ErrorMessageManagement: Codeunit "Error Message Management";
        PrintingErrorExists: Boolean;
    begin
        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.FindSet();
        repeat
            if CheckReportId(ReportSelections) then begin
                if not PrintToPDF(ReportSelections."Report ID", RecRef, PurchaseHeader, JobQueueEntry) then begin
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

    local procedure PrintToPDF(ReportId: Integer; RecRef: RecordRef; PurchaseHeader: Record "Purchase Header"; JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        ReportInbox: Record "Report Inbox";
        OStream: OutStream;
        IsHandled: Boolean;
        IsSuccess: Boolean;
    begin
        ReportInbox.Init();
        ReportInbox."User ID" := JobQueueEntry."User ID";
        ReportInbox."Job Queue Log Entry ID" := JobQueueEntry.ID;
        ReportInbox."Report ID" := ReportID;
        ReportInbox.Description := CopyStr(StrSubstNo(PrintingDescriptionTxt, PurchaseHeader."Document Type", PurchaseHeader."No."), 1, MaxStrLen(ReportInbox.Description));
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
        OnPrintToPDFOnAfterReportInboxInsert(ReportInbox, PurchaseHeader, RecRef);

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
    local procedure OnPrintToPDFOnAfterReportInboxInsert(var ReportInbox: Record "Report Inbox"; var PurchaseHeader: Record "Purchase Header"; var RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPrintToPDFOnBeforeReportRun(ReportId: Integer; RecRef: RecordRef; var OStream: OutStream; var IsSuccess: Boolean; var IsHandled: Boolean)
    begin
    end;
}
