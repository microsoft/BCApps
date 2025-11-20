// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Projects.Project.Job;

table 1007 "Job WIP Warning"
{
    Caption = 'Project WIP Warning';
    DrillDownPageID = "Job WIP Warnings";
    LookupPageID = "Job WIP Warnings";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Task"."Job Task No.";
        }
        field(4; "Job WIP Total Entry No."; Integer)
        {
            Caption = 'Project WIP Total Entry No.';
            Editable = false;
            TableRelation = "Job WIP Total";
        }
        field(5; "Warning Message"; Text[250])
        {
            Caption = 'Warning Message';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Job No.", "Job Task No.")
        {
        }
        key(Key3; "Job WIP Total Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 is 0.';
#pragma warning restore AA0470
        Text002: Label 'Cost completion is greater than 100%.';
#pragma warning disable AA0470
        Text003: Label '%1 is negative.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateEntries(JobWIPTotal: Record "Job WIP Total")
    var
        Job: Record Job;
        ShouldInsertWarnings: Boolean;
    begin
        Job.Get(JobWIPTotal."Job No.");
        ShouldInsertWarnings := not Job.Complete;
        OnCreateEntriesOnAfterCalcShouldInsertWarnings(JobWIPTotal, Job, ShouldInsertWarnings);
        if ShouldInsertWarnings then begin
            if JobWIPTotal."Contract (Total Price)" = 0 then
                InsertWarning(JobWIPTotal, StrSubstNo(Text001, JobWIPTotal.FieldCaption("Contract (Total Price)")));

            if JobWIPTotal."Schedule (Total Cost)" = 0 then
                InsertWarning(JobWIPTotal, StrSubstNo(Text001, JobWIPTotal.FieldCaption("Schedule (Total Cost)")));

            if JobWIPTotal."Schedule (Total Price)" = 0 then
                InsertWarning(JobWIPTotal, StrSubstNo(Text001, JobWIPTotal.FieldCaption("Schedule (Total Price)")));

            if JobWIPTotal."Usage (Total Cost)" > JobWIPTotal."Schedule (Total Cost)" then
                InsertWarning(JobWIPTotal, Text002);

            if JobWIPTotal."Calc. Recog. Sales Amount" < 0 then
                InsertWarning(JobWIPTotal, StrSubstNo(Text003, JobWIPTotal.FieldCaption("Calc. Recog. Sales Amount")));

            if JobWIPTotal."Calc. Recog. Costs Amount" < 0 then
                InsertWarning(JobWIPTotal, StrSubstNo(Text003, JobWIPTotal.FieldCaption("Calc. Recog. Costs Amount")));
        end;
        OnAfterCreateEntries(JobWIPTotal, Job);
    end;

    procedure DeleteEntries(JobWIPTotal: Record "Job WIP Total")
    begin
        SetRange("Job WIP Total Entry No.", JobWIPTotal."Entry No.");
        if not IsEmpty() then
            DeleteAll(true);
    end;

    procedure InsertWarning(JobWIPTotal: Record "Job WIP Total"; Message: Text[250])
    begin
        Reset();
        if FindLast() then
            "Entry No." += 1
        else
            "Entry No." := 1;
        "Job WIP Total Entry No." := JobWIPTotal."Entry No.";
        "Job No." := JobWIPTotal."Job No.";
        "Job Task No." := JobWIPTotal."Job Task No.";
        "Warning Message" := Message;
        OnInsertWarningOnBeforeInsert(Rec);
        Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateEntries(JobWIPTotal: Record "Job WIP Total"; Job: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateEntriesOnAfterCalcShouldInsertWarnings(JobWIPTotal: Record "Job WIP Total"; Job: Record Job; var ShouldInsertWarnings: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWarningOnBeforeInsert(var JobWIPWarning: Record "Job WIP Warning")
    begin
    end;
}

