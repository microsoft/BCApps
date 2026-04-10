// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Purchases.Vendor;
using System.Threading;

codeunit 882 "OCR - Sync Master Data"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        SyncMasterData();
    end;

    var
        JobDelayMinutesTxt: Label '5', Locked = true;
        MaxNoOfAttemptsTxt: Label '3', Locked = true;

    local procedure SyncMasterData()
    var
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
    begin
        ReadSoftOCRMasterDataSync.SyncMasterData(false, true);
    end;

    local procedure ResetLastSyncTime()
    var
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
    begin
        ReadSoftOCRMasterDataSync.ResetLastSyncTime();
    end;

    procedure ScheduleJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ReadSoftOCRMasterDataSync: Codeunit "ReadSoft OCR Master Data Sync";
    begin
        if not ReadSoftOCRMasterDataSync.IsSyncEnabled() then
            exit;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"OCR - Sync Master Data");
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindFirst() then begin
            RestartJob(JobQueueEntry);
            exit;
        end;

        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::Finished);
        if JobQueueEntry.FindFirst() then begin
            RestartJob(JobQueueEntry);
            exit;
        end;

        CreateNewJob();
    end;

    procedure CancelJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"OCR - Sync Master Data");
        while JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"OCR - Sync Master Data") do
            JobQueueEntry.Cancel();
    end;

    local procedure RestartJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if ModifiedByUser(JobQueueEntry) then begin
            CancelJob();
            CreateNewJob();
        end else
            if JobQueueEntry.Status <> JobQueueEntry.Status::Ready then
                JobQueueEntry.Restart();
    end;

    local procedure ModifiedByUser(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        case true of
            JobQueueEntry."Maximum No. of Attempts to Run" <> MaxNoOfAttempts():
                exit(true);
            JobQueueEntry."Rerun Delay (sec.)" <> JobDelayMinutes() * 60:
                exit(true);
            JobQueueEntry."Earliest Start Date/Time" > CurrentDateTime + JobDelayMinutes() * 60000:
                exit(true);
        end;
        exit(false);
    end;

    local procedure CreateNewJob()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.LockTable();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"OCR - Sync Master Data";
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + JobDelayMinutes() * 60000;
        JobQueueEntry."Maximum No. of Attempts to Run" := MaxNoOfAttempts();
        JobQueueEntry."Rerun Delay (sec.)" := JobDelayMinutes() * 60;
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
    end;

    local procedure JobDelayMinutes(): Integer
    var
        Result: Integer;
    begin
        Evaluate(Result, JobDelayMinutesTxt);
        exit(Result);
    end;

    local procedure MaxNoOfAttempts(): Integer
    var
        Result: Integer;
    begin
        Evaluate(Result, MaxNoOfAttemptsTxt);
        exit(Result);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteVendor(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then begin
            ResetLastSyncTime();
            ScheduleJob();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertVendor(var Rec: Record Vendor; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            ScheduleJob();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyVendor(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            ScheduleJob();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameVendor(var Rec: Record Vendor; var xRec: Record Vendor; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then begin
            ResetLastSyncTime();
            ScheduleJob();
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteVendorBankAccount(var Rec: Record "Vendor Bank Account"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            ScheduleJob();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertVendorBankAccount(var Rec: Record "Vendor Bank Account"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            ScheduleJob();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyVendorBankAccount(var Rec: Record "Vendor Bank Account"; var xRec: Record "Vendor Bank Account"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            ScheduleJob();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Vendor Bank Account", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameVendorBankAccount(var Rec: Record "Vendor Bank Account"; var xRec: Record "Vendor Bank Account"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary then
            ScheduleJob();
    end;
}

