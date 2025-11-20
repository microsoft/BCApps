// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Resources.Resource;

table 1034 "Job Planning Line - Calendar"
{
    Caption = 'Project Planning Line - Calendar';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = "Job Planning Line"."Job No.";
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            TableRelation = "Job Planning Line"."Job Task No.";
        }
        field(3; "Planning Line No."; Integer)
        {
            Caption = 'Planning Line No.';
            TableRelation = "Job Planning Line"."Line No.";
        }
        field(4; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource."No.";
        }
        field(6; "Planning Date"; Date)
        {
            Caption = 'Planning Date';
        }
        field(7; Quantity; Decimal)
        {
            Caption = 'Quantity';
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; UID; Guid)
        {
            Caption = 'UID';
        }
        field(10; Sequence; Integer)
        {
            Caption = 'Sequence';
            InitValue = 1;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Planning Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        UID := CreateGuid();
    end;

    trigger OnModify()
    begin
        Sequence += 1;
    end;

    procedure HasBeenSent(JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        exit(Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No."));
    end;

    procedure InsertOrUpdate(JobPlanningLine: Record "Job Planning Line")
    begin
        if not HasBeenSent(JobPlanningLine) then begin
            Init();
            "Job No." := JobPlanningLine."Job No.";
            "Job Task No." := JobPlanningLine."Job Task No.";
            "Planning Line No." := JobPlanningLine."Line No.";
            "Resource No." := JobPlanningLine."No.";
            Quantity := JobPlanningLine.Quantity;
            "Planning Date" := JobPlanningLine."Planning Date";
            Description := JobPlanningLine.Description;
            Insert(true);
        end else begin
            Quantity := JobPlanningLine.Quantity;
            "Planning Date" := JobPlanningLine."Planning Date";
            Description := JobPlanningLine.Description;
            Modify(true);
        end;
    end;

    procedure ShouldSendCancellation(JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        LocalJobPlanningLine: Record "Job Planning Line";
    begin
        if not LocalJobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.") then
            exit(true);
        if HasBeenSent(JobPlanningLine) then
            exit(JobPlanningLine."No." <> "Resource No.");
    end;

    procedure ShouldSendRequest(JobPlanningLine: Record "Job Planning Line") ShouldSend: Boolean
    var
        LocalJobPlanningLine: Record "Job Planning Line";
    begin
        ShouldSend := true;
        if not LocalJobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.") then
            exit(false);
        if HasBeenSent(JobPlanningLine) then
            ShouldSend :=
              ("Resource No." <> JobPlanningLine."No.") or
              ("Planning Date" <> JobPlanningLine."Planning Date") or
              (Quantity <> JobPlanningLine.Quantity) or
              (Description <> JobPlanningLine.Description);
    end;
}

