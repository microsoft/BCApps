// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using Microsoft.Integration.Dataverse;

table 5338 "Integration Synch. Job"
{
    Caption = 'Integration Synch. Job';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Guid)
        {
            Caption = 'ID';
        }
        field(2; "Start Date/Time"; DateTime)
        {
            Caption = 'Start Date/Time';
        }
        field(3; "Finish Date/Time"; DateTime)
        {
            Caption = 'Finish Date/Time';
        }
        field(4; Message; Text[250])
        {
            Caption = 'Message';
        }
        field(5; "Integration Table Mapping Name"; Code[20])
        {
            Caption = 'Integration Table Mapping Name';
            TableRelation = "Integration Table Mapping".Name;
        }
        field(6; Inserted; Integer)
        {
            Caption = 'Inserted';
        }
        field(7; Modified; Integer)
        {
            Caption = 'Modified';
        }
        field(8; Deleted; Integer)
        {
            Caption = 'Deleted';
        }
        field(9; Unchanged; Integer)
        {
            Caption = 'Unchanged';
        }
        field(10; Skipped; Integer)
        {
            Caption = 'Skipped';
        }
        field(11; Failed; Integer)
        {
            Caption = 'Failed';
        }
        field(12; "Synch. Direction"; Option)
        {
            Caption = 'Synch. Direction';
            OptionCaption = 'Bidirectional,ToIntegrationTable,FromIntegrationTable';
            OptionMembers = Bidirectional,ToIntegrationTable,FromIntegrationTable;
        }
        field(13; "Job Queue Log Entry No."; Integer)
        {
            Caption = 'Job Queue Log Entry No.';
        }
        field(14; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Synchronization,Uncoupling,Coupling';
            OptionMembers = Synchronization,Uncoupling,Coupling;
        }
        field(15; Uncoupled; Integer)
        {
            Caption = 'Uncoupled';
        }
        field(16; Coupled; Integer)
        {
            Caption = 'Coupled';
        }
    }
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Start Date/Time", ID)
        {
        }
        key(Key3; Type)
        {
        }
        key(Key4; "Job Queue Log Entry No.")
        {
        }
        key(Key5; "Integration Table Mapping Name")
        {
            SumIndexFields = Failed;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        IntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
    begin
        IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", ID);
        IntegrationSynchJobErrors.DeleteAll();
    end;

    var
        DeleteEntriesQst: Label 'Are you sure that you want to delete the %1 entries?', Comment = '%1 = Integration Synch. Job caption';

    procedure DeleteEntries(DaysOld: Integer)
    var
        IntegrationSynchJob: Record "Integration Synch. Job";
    begin
        if not Confirm(StrSubstNo(DeleteEntriesQst, TableCaption)) then
            exit;
        IntegrationSynchJob.Copy(Rec);
        IntegrationSynchJob.SetFilter("Finish Date/Time", '<=%1', CreateDateTime(Today - DaysOld, Time));
        IntegrationSynchJob.SetRange(Failed, 0);
        IntegrationSynchJob.DeleteAll();

        IntegrationSynchJob.SetRange(Failed);
        if IntegrationSynchJob.FindSet() then
            repeat
                if IntegrationSynchJob.CanBeRemoved() then
                    IntegrationSynchJob.Delete(true);
            until IntegrationSynchJob.Next() = 0;
    end;

    procedure GetErrorForRecordID(RecID: RecordID; var IntegrationSynchJobErrors: Record "Integration Synch. Job Errors"): Boolean
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        if not IsNullGuid(ID) then
            IntegrationSynchJobErrors.SetRange("Integration Synch. Job ID", ID);
        if CRMIntegrationManagement.IsCRMTable(RecID.TableNo) xor ("Synch. Direction" = "Synch. Direction"::FromIntegrationTable) then
            IntegrationSynchJobErrors.SetRange("Destination Record ID", RecID)
        else
            IntegrationSynchJobErrors.SetRange("Source Record ID", RecID);
        exit(IntegrationSynchJobErrors.FindLast());
    end;

    [Scope('Cloud')]
    procedure AreSomeRecordsFailed(): Boolean
    begin
        exit(Failed <> 0);
    end;

    procedure HaveJobsBeenIdle(JobQueueLogEntryNo: Integer): Boolean
    begin
        Reset();
        SetRange("Job Queue Log Entry No.", JobQueueLogEntryNo);
        if not IsEmpty() then begin
            CalcSums(Inserted, Modified, Deleted, Failed);
            exit(Inserted + Modified + Deleted + Failed = 0);
        end;
    end;

    procedure CanBeRemoved() AllowRemoval: Boolean
    begin
        OnCanBeRemoved(Rec, AllowRemoval);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCanBeRemoved(IntegrationSynchJob: Record "Integration Synch. Job"; var AllowRemoval: Boolean)
    begin
    end;
}

