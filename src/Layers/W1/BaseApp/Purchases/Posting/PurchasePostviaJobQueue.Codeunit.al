// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Posting;

using Microsoft.Foundation.BatchProcessing;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using System.Threading;

codeunit 98 "Purchase Post via Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        PurchHeader: Record "Purchase Header";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        RecRef: RecordRef;
        RecRefToPrint: RecordRef;
        SavedLockTimeout: Boolean;
        IsHandled: Boolean;
    begin
        Rec.TestField("Record ID to Process");
        RecRef.Get(Rec."Record ID to Process");
        RecRef.SetTable(PurchHeader);
        PurchHeader.Find();

        BatchProcessingMgt.GetBatchFromSession(Rec."Record ID to Process", Rec."User Session ID");

        SavedLockTimeout := LockTimeout;
        SetJobQueueStatus(PurchHeader, PurchHeader."Job Queue Status"::Posting, Rec);
        if not Codeunit.Run(Codeunit::"Purch.-Post", PurchHeader) then begin
            SetJobQueueStatus(PurchHeader, PurchHeader."Job Queue Status"::Error, Rec);
            IsHandled := false;
            OnBeforeBatchProcessingErrorReset(Rec, IsHandled);
            if not IsHandled then
                BatchProcessingMgt.ResetBatchID();
            Error(GetLastErrorText);
        end;
        if PurchHeader."Print Posted Documents" then begin
            RecRefToPrint.GetTable(PurchHeader);
            BatchPostingPrintMgt.PrintPurchaseDocument(RecRefToPrint);
        end;
        if not AreOtherJobQueueEntriesScheduled(Rec) then
            BatchProcessingMgt.ResetBatchID();
        BatchProcessingMgt.DeleteBatchProcessingSessionMapForRecordId(PurchHeader.RecordId);
        SetJobQueueStatus(PurchHeader, PurchHeader."Job Queue Status"::" ", Rec);
        LockTimeout(SavedLockTimeout);
    end;

    var
#pragma warning disable AA0074
        PostDescription: Label 'Post Purchase %1 %2.', Comment = '%1 = document type, %2 = document number. Example: Post Purchase Order 1234.';
        PostAndPrintDescription: Label 'Post and Print Purchase %1 %2.', Comment = '%1 = document type, %2 = document number. Example: Post Purchase Order 1234.';
        Confirmation: Label '%1 %2 has been scheduled for posting.', Comment = '%1=document type, %2=number, e.g. Order 123  or Invoice 234.';
        WrongJobQueueStatus: Label '%1 %2 cannot be posted because it has already been scheduled for posting. Choose the Remove from Job Queue action to reset the job queue status and then post again.', Comment = '%1 = document type, %2 = document number. Example: Purchase Order 1234 or Invoice 1234.';
#pragma warning restore AA0074
        DefaultCategoryCodeLbl: Label 'PURCHBCKGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background Purch. Posting', Locked = true;

    local procedure SetJobQueueStatus(var PurchHeader: Record "Purchase Header"; NewStatus: Enum "Document Job Queue Status"; JobQueueEntry: Record "Job Queue Entry")
    begin
        OnBeforeSetJobQueueStatus(PurchHeader, NewStatus.AsInteger(), JobQueueEntry);
        PurchHeader.LockTable();
        if PurchHeader.Find() then begin
            PurchHeader."Job Queue Status" := NewStatus;
            PurchHeader.Modify();
            Commit();
        end;
    end;

    procedure EnqueuePurchDoc(var PurchHeader: Record "Purchase Header")
    begin
        EnqueuePurchDocWithUI(PurchHeader, true);
    end;

    procedure EnqueuePurchDocWithUI(var PurchHeader: Record "Purchase Header"; WithUI: Boolean)
    var
        TempInvoice: Boolean;
        TempRcpt: Boolean;
        TempShip: Boolean;
        Handled: Boolean;
    begin
        OnBeforeEnqueuePurchDoc(PurchHeader, Handled);
        if Handled then
            exit;

        if not (PurchHeader."Job Queue Status" in [PurchHeader."Job Queue Status"::" ", PurchHeader."Job Queue Status"::Error]) then
            Error(WrongJobQueueStatus, PurchHeader."Document Type", PurchHeader."No.");
        TempInvoice := PurchHeader.Invoice;
        TempRcpt := PurchHeader.Receive;
        TempShip := PurchHeader.Ship;
        OnBeforeReleasePurchDoc(PurchHeader);
        if PurchHeader.Status = PurchHeader.Status::Open then
            CODEUNIT.Run(CODEUNIT::"Release Purchase Document", PurchHeader);
        PurchHeader.Invoice := TempInvoice;
        PurchHeader.Receive := TempRcpt;
        PurchHeader.Ship := TempShip;
        PurchHeader."Job Queue Status" := PurchHeader."Job Queue Status"::"Scheduled for Posting";
        PurchHeader."Job Queue Entry ID" := EnqueueJobEntry(PurchHeader);
        PurchHeader.Modify();

        if GuiAllowed then
            if WithUI then
                Message(Confirmation, PurchHeader."Document Type", PurchHeader."No.");
    end;

    local procedure EnqueueJobEntry(PurchHeader: Record "Purchase Header"): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Clear(JobQueueEntry.ID);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Purchase Post via Job Queue";
        JobQueueEntry."Record ID to Process" := PurchHeader.RecordId;
        FillJobEntryFromPurchSetup(JobQueueEntry);
        FillJobEntryPurchDescription(JobQueueEntry, PurchHeader);
        JobQueueEntry."User Session ID" := SessionId();
        OnEnqueueJobEntryOnBeforeRunJobQueueEnqueue(PurchHeader, JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(JobQueueEntry.ID);
    end;

    local procedure FillJobEntryFromPurchSetup(var JobQueueEntry: Record "Job Queue Entry")
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        JobQueueEntry."Notify On Success" := PurchSetup."Notify On Success";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueCategoryCode();
    end;

    local procedure FillJobEntryPurchDescription(var JobQueueEntry: Record "Job Queue Entry"; PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader."Print Posted Documents" then
            JobQueueEntry.Description := PostAndPrintDescription
        else
            JobQueueEntry.Description := PostDescription;
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(JobQueueEntry.Description, PurchHeader."Document Type", PurchHeader."No."), 1, MaxStrLen(JobQueueEntry.Description));
    end;

    procedure CancelQueueEntry(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader."Job Queue Status" <> PurchHeader."Job Queue Status"::" " then begin
            DeleteJobs(PurchHeader);
            PurchHeader."Job Queue Status" := PurchHeader."Job Queue Status"::" ";
            PurchHeader.Modify();
        end;
    end;

    local procedure DeleteJobs(PurchHeader: Record "Purchase Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsNullGuid(PurchHeader."Job Queue Entry ID") then
            JobQueueEntry.SetRange(ID, PurchHeader."Job Queue Entry ID");
        JobQueueEntry.SetRange("Record ID to Process", PurchHeader.RecordId);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll(true);
    end;

    local procedure AreOtherJobQueueEntriesScheduled(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        JobQueueEntryFilter: Record "Job Queue Entry";
        result: Boolean;
    begin
        JobQueueEntryFilter.SetFilter("Job Queue Category Code", GetJobQueueCategoryCode());
        JobQueueEntryFilter.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntryFilter.SetRange("Object ID to Run", JobQueueEntry."Object ID to Run");
        JobQueueEntryFilter.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run");
        JobQueueEntryFilter.SetFilter(
            Status, '%1|%2|%3|%4',
            JobQueueEntry.Status::"In Process", JobQueueEntry.Status::"On Hold",
            JobQueueEntry.Status::"On Hold with Inactivity Timeout", JobQueueEntry.Status::Ready);
        result := not JobQueueEntryFilter.IsEmpty();

        exit(result);
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

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnqueuePurchDoc(var PurchaseHeader: Record "Purchase Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleasePurchDoc(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetJobQueueStatus(PurchaseHeader: Record "Purchase Header"; NewJobQueueStatus: Option " ","Scheduled for Posting",Error,Posting; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnqueueJobEntryOnBeforeRunJobQueueEnqueue(PurchaseHeader: Record "Purchase Header"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBatchProcessingErrorReset(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
}

