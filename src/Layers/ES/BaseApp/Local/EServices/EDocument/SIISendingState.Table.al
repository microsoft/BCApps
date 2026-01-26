// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Threading;
using System.Utilities;

table 10799 "SII Sending State"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Permissions = tabledata "Job Queue Entry" = r;
    ReplicateData = false;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {

        }
        field(2; Status; Text[250])
        {

        }
        field(3; "Job Queue Entry Id"; Guid)
        {

        }
        field(4; "Schedule One More When Finish"; Boolean)
        {

        }
    }

    var
        PendingStatusTxt: Label 'Pending';
        ResetSendingQst: Label 'Do you want to reset sending state?';
        NoAccessToJobQueueEntryTxt: Label 'You do not have access to the job queue entry.';

    procedure Refresh()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        Rec.ReadIsolation := IsolationLevel::UpdLock;
        InitRecord();
        if IsNullGuid(Rec."Job Queue Entry Id") then begin
            Rec.Validate(Status, PendingStatusTxt);
            Rec.Modify(true);
            exit;
        end;
        JobQueueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        if not JobQueueEntry.Get(Rec."Job Queue Entry Id") then begin
            Rec."Job Queue Entry Id" := '{00000000-0000-0000-0000-000000000000}';
            Rec.Modify(true);
            exit;
        end;
        Rec.Validate(Status, Format(JobQueueEntry.Status));
        Rec.Modify(true);
    end;

    procedure LookupJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCardPage: Page "Job Queue Entry Card";
    begin
        if not JobQueueEntry.ReadPermission() then begin
            Message(NoAccessToJobQueueEntryTxt);
            exit;
        end;
        if IsNullGuid(Rec."Job Queue Entry Id") then
            exit;
        if not JobQueueEntry.Get(Rec."Job Queue Entry Id") then
            exit;
        JobQueueEntry.SetRecFilter();
        JobQueueEntryCardPage.SetTableView(JobQueueEntry);
        JobQueueEntryCardPage.Run();
    end;

    procedure ResetSending()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not ConfirmManagement.GetResponseOrDefault(ResetSendingQst, true) then
            exit;
        Rec.Init();
        Rec.Validate(Status, PendingStatusTxt);
        Rec.Modify(true);
    end;

    procedure InitRecord()
    begin
        if Rec.Get() then
            exit;
        Rec.Validate(Status, PendingStatusTxt);
        Rec.Insert(true);
    end;
}