// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.Integration.SyncEngine;
using System.Threading;

codeunit 5371 "CRM Synch. Job Management"
{

    trigger OnRun()
    begin
    end;

    procedure SetInitialState(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue")
    begin
        CRMSynchJobStatusCue.Reset();
        if not CRMSynchJobStatusCue.FindFirst() then begin
            CRMSynchJobStatusCue.Init();
            CRMSynchJobStatusCue.Code := GetDefaultPkValue();
            CRMSynchJobStatusCue.Insert();
        end;
        SetFilters(CRMSynchJobStatusCue);
    end;

    procedure OnReset(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue")
    begin
        CRMSynchJobStatusCue.Reset();
        CRMSynchJobStatusCue.FindFirst();
        CRMSynchJobStatusCue."Reset Date" := GetLastFailedDate(GetDefaultJobRunner());
        CRMSynchJobStatusCue.Modify();
        SetFilters(CRMSynchJobStatusCue);
    end;

    local procedure FindLastJobQueue(var JobQueueEntry: Record "Job Queue Entry"; JobToRun: Integer): Boolean
    begin
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
        JobQueueEntry.SetRange("Object ID to Run", JobToRun);
        exit(JobQueueEntry.FindLast());
    end;

    local procedure GetLastFailedDate(JobToRun: Integer): DateTime
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if FindLastJobQueue(JobQueueEntry, JobToRun) then
            exit(JobQueueEntry."Last Ready State");
        exit(CreateDateTime(Today, Time));
    end;

    local procedure GetDefaultPkValue(): Code[10]
    begin
        exit('0');
    end;

    local procedure SetFilters(var CRMSynchJobStatusCue: Record "CRM Synch. Job Status Cue")
    begin
        CRMSynchJobStatusCue.SetRange("Object ID to Run", GetDefaultJobRunner());
        CRMSynchJobStatusCue.SetFilter("Date Filter", '>%1', CRMSynchJobStatusCue."Reset Date");
    end;

    procedure GetDefaultJobRunner(): Integer
    begin
        exit(CODEUNIT::"Integration Synch. Job Runner");
    end;
}

