// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Posting;

using Microsoft.Foundation.BatchProcessing;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using System.Threading;
using Microsoft.Inventory.Setup;

codeunit 88 "Sales Post via Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        SalesHeader: Record "Sales Header";
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        BatchPostingPrintMgt: Codeunit "Batch Posting Print Mgt.";
        RecRef: RecordRef;
        RecRefToPrint: RecordRef;
        SavedLockTimeout: Boolean;
        IsHandled: Boolean;
    begin
        Rec.TestField("Record ID to Process");
        RecRef.Get(Rec."Record ID to Process");
        RecRef.SetTable(SalesHeader);
        SalesHeader.Find();

        BatchProcessingMgt.GetBatchFromSession(Rec."Record ID to Process", Rec."User Session ID");

        SavedLockTimeout := LockTimeout;
        SetJobQueueStatus(SalesHeader, SalesHeader."Job Queue Status"::Posting, Rec);
        OnRunOnBeforeRunSalesPost(SalesHeader);
        if not Codeunit.Run(Codeunit::"Sales-Post", SalesHeader) then begin
            SetJobQueueStatus(SalesHeader, SalesHeader."Job Queue Status"::Error, Rec);
            IsHandled := false;
            OnBeforeBatchProcessingErrorReset(Rec, IsHandled);
            if not IsHandled then
                BatchProcessingMgt.ResetBatchID();
            Error(GetLastErrorText);
        end;
        OnRunOnAfterRunSalesPost(SalesHeader);
        if SalesHeader."Print Posted Documents" then begin
            RecRefToPrint.GetTable(SalesHeader);
            BatchPostingPrintMgt.PrintSalesDocument(RecRefToPrint);
        end;
        if not AreOtherJobQueueEntriesScheduled(Rec) then
            BatchProcessingMgt.ResetBatchID();
        BatchProcessingMgt.DeleteBatchProcessingSessionMapForRecordId(SalesHeader.RecordId);
        SetJobQueueStatus(SalesHeader, SalesHeader."Job Queue Status"::" ", Rec);
        LockTimeout(SavedLockTimeout);
    end;

    var
#pragma warning disable AA0074
        PostDescription: Label 'Post Sales %1 %2.', Comment = '%1 = document type, %2 = document number. Example: Post Sales Order 1234.';
        PostAndPrintDescription: Label 'Post and Print Sales %1 %2.', Comment = '%1 = document type, %2 = document number. Example: Post Sales Order 1234.';
        Confirmation: Label '%1 %2 has been scheduled for posting.', Comment = '%1=document type, %2=number, e.g. Order 123  or Invoice 234.';
        WrongJobQueueStatus: Label '%1 %2 cannot be posted because it has already been scheduled for posting. Choose the Remove from Job Queue action to reset the job queue status and then post again.', Comment = '%1 = document type, %2 = document number. Example: Sales Order 1234 or Invoice 1234.';
#pragma warning restore AA0074
        DefaultCategoryCodeLbl: Label 'SALESBCKGR', Locked = true;
        DefaultCategoryDescLbl: Label 'Def. Background Sales Posting', Locked = true;

    local procedure SetJobQueueStatus(var SalesHeader: Record "Sales Header"; NewStatus: Enum "Document Job Queue Status"; JobQueueEntry: Record "Job Queue Entry")
    begin
        OnBeforeSetJobQueueStatus(SalesHeader, NewStatus.AsInteger(), JobQueueEntry);
        SalesHeader.LockTable();
        if SalesHeader.Find() then begin
            SalesHeader."Job Queue Status" := NewStatus;
            SalesHeader.Modify();
            Commit();
        end;
    end;

    procedure EnqueueSalesDoc(var SalesHeader: Record "Sales Header")
    begin
        EnqueueSalesDocWithUI(SalesHeader, true);
    end;

    procedure EnqueueSalesDocWithUI(var SalesHeader: Record "Sales Header"; WithUI: Boolean)
    var
        TempInvoice: Boolean;
        TempRcpt: Boolean;
        TempShip: Boolean;
        Handled: Boolean;
    begin
        OnBeforeEnqueueSalesDoc(SalesHeader, Handled);
        if Handled then
            exit;

        if not (SalesHeader."Job Queue Status" in [SalesHeader."Job Queue Status"::" ", SalesHeader."Job Queue Status"::Error]) then
            Error(WrongJobQueueStatus, SalesHeader."Document Type", SalesHeader."No.");
        TempInvoice := SalesHeader.Invoice;
        TempRcpt := SalesHeader.Receive;
        TempShip := SalesHeader.Ship;
        OnBeforeReleaseSalesDoc(SalesHeader);
        if SalesHeader.Status = SalesHeader.Status::Open then
            CODEUNIT.Run(CODEUNIT::"Release Sales Document", SalesHeader);
        SalesHeader.Invoice := TempInvoice;
        SalesHeader.Receive := TempRcpt;
        SalesHeader.Ship := TempShip;
        SalesHeader."Job Queue Status" := SalesHeader."Job Queue Status"::"Scheduled for Posting";
        SalesHeader."Job Queue Entry ID" := EnqueueJobEntry(SalesHeader);
        SalesHeader.Modify();

        if GuiAllowed then
            if WithUI then
                Message(Confirmation, SalesHeader."Document Type", SalesHeader."No.");
    end;

    local procedure EnqueueJobEntry(SalesHeader: Record "Sales Header"): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Clear(JobQueueEntry.ID);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Sales Post via Job Queue";
        JobQueueEntry."Record ID to Process" := SalesHeader.RecordId;
        FillJobEntryFromSalesSetup(JobQueueEntry);
        FillJobEntrySalesDescription(JobQueueEntry, SalesHeader);
        JobQueueEntry."User Session ID" := SessionId();
        OnEnqueueJobEntryOnBeforeEnqueue(SalesHeader, JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        exit(JobQueueEntry.ID)
    end;

    local procedure FillJobEntryFromSalesSetup(var JobQueueEntry: Record "Job Queue Entry")
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        JobQueueEntry."Notify On Success" := SalesSetup."Notify On Success";
        JobQueueEntry."Job Queue Category Code" := GetJobQueueCategoryCode();
    end;

    local procedure FillJobEntrySalesDescription(var JobQueueEntry: Record "Job Queue Entry"; SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Print Posted Documents" then
            JobQueueEntry.Description := PostAndPrintDescription
        else
            JobQueueEntry.Description := PostDescription;
        JobQueueEntry.Description :=
          CopyStr(StrSubstNo(JobQueueEntry.Description, SalesHeader."Document Type", SalesHeader."No."), 1, MaxStrLen(JobQueueEntry.Description));
    end;

    procedure CancelQueueEntry(var SalesHeader: Record "Sales Header")
    begin
        if SalesHeader."Job Queue Status" <> SalesHeader."Job Queue Status"::" " then begin
            DeleteJobs(SalesHeader);
            SalesHeader."Job Queue Status" := SalesHeader."Job Queue Status"::" ";
            SalesHeader.Modify();
        end;
    end;

    local procedure DeleteJobs(SalesHeader: Record "Sales Header")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not IsNullGuid(SalesHeader."Job Queue Entry ID") then
            JobQueueEntry.SetRange(ID, SalesHeader."Job Queue Entry ID");
        JobQueueEntry.SetRange("Record ID to Process", SalesHeader.RecordId);
        if not JobQueueEntry.IsEmpty() then
            JobQueueEntry.DeleteAll(true);
    end;

    local procedure AreOtherJobQueueEntriesScheduled(JobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobQueueEntryFilter: Record "Job Queue Entry";
        result: Boolean;
    begin
        SalesReceivablesSetup.Get();
        JobQueueEntryFilter.SetFilter("Job Queue Category Code", GetJobQueueCategoryCode());
        JobQueueEntryFilter.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntryFilter.SetRange("Object ID to Run", JobQueueEntry."Object ID to Run");
        JobQueueEntryFilter.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run");
        JobQueueEntryFilter.SetRange("User Session ID", JobQueueEntry."User Session ID");
        JobQueueEntryFilter.SetFilter(
            Status, '%1|%2|%3|%4',
            JobQueueEntry.Status::"In Process", JobQueueEntry.Status::"On Hold",
            JobQueueEntry.Status::"On Hold with Inactivity Timeout", JobQueueEntry.Status::Ready);
        result := not JobQueueEntryFilter.IsEmpty();

        exit(result);
    end;

    internal procedure GetJobQueueCategoryCode(): Code[10]
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        JobQueueCategory: Record "Job Queue Category";
        InventorySetup: Record "Inventory Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Job Queue Category Code" <> '' then
            exit(SalesReceivablesSetup."Job Queue Category Code");

        if not InventorySetup.UseLegacyPosting() then
            exit(''); // allow sales post to run concurrently.

        JobQueueCategory.InsertRec(
            CopyStr(DefaultCategoryCodeLbl, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(DefaultCategoryDescLbl, 1, MaxStrLen(JobQueueCategory.Description)));
        exit(JobQueueCategory.Code);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEnqueueSalesDoc(var SalesHeader: Record "Sales Header"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSalesDoc(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetJobQueueStatus(SalesHeader: Record "Sales Header"; NewJobQueueStatus: Option " ","Scheduled for Posting",Error,Posting; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnqueueJobEntryOnBeforeEnqueue(SalesHeader: Record "Sales Header"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnAfterRunSalesPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeRunSalesPost(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBatchProcessingErrorReset(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
}

