// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Projects.Project.Job;

table 1021 "Job WIP Total"
{
    Caption = 'Project WIP Total';
    DrillDownPageID = "Job WIP Totals";
    LookupPageID = "Job WIP Totals";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
            NotBlank = true;
            TableRelation = Job;
        }
        field(3; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ValidateTableRelation = false;
        }
        field(4; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            Editable = false;
            TableRelation = "Job WIP Method".Code;
        }
        field(5; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
            Editable = false;
        }
        field(6; "WIP Posting Date Filter"; Text[250])
        {
            Caption = 'WIP Posting Date Filter';
            Editable = false;
        }
        field(7; "WIP Planning Date Filter"; Text[250])
        {
            Caption = 'WIP Planning Date Filter';
            Editable = false;
        }
        field(8; "WIP Warnings"; Boolean)
        {
            CalcFormula = exist("Job WIP Warning" where("Job WIP Total Entry No." = field("Entry No.")));
            Caption = 'WIP Warnings';
            FieldClass = FlowField;
        }
        field(9; "Posted to G/L"; Boolean)
        {
            Caption = 'Posted to G/L';
        }
        field(10; "Schedule (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Budget (Total Cost)';
            Editable = false;
        }
        field(11; "Schedule (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Budget (Total Price)';
            Editable = false;
        }
        field(12; "Usage (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Usage (Total Cost)';
            Editable = false;
        }
        field(13; "Usage (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Usage (Total Price)';
            Editable = false;
        }
        field(14; "Contract (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Billable (Total Cost)';
            Editable = false;
        }
        field(15; "Contract (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Billable (Total Price)';
            Editable = false;
        }
        field(16; "Contract (Invoiced Price)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Billable (Invoiced Price)';
            Editable = false;
        }
        field(17; "Contract (Invoiced Cost)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Billable (Invoiced Cost)';
            Editable = false;
        }
        field(20; "Calc. Recog. Sales Amount"; Decimal)
        {
            Caption = 'Calc. Recog. Sales Amount';
            Editable = false;
        }
        field(21; "Calc. Recog. Costs Amount"; Decimal)
        {
            Caption = 'Calc. Recog. Costs Amount';
            Editable = false;
        }
        field(30; "Cost Completion %"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Cost Completion %';
            Editable = false;
        }
        field(31; "Invoiced %"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Invoiced %';
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
        key(Key3; "Job No.", "Posted to G/L")
        {
            SumIndexFields = "Calc. Recog. Sales Amount", "Calc. Recog. Costs Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        JobWIPWarning: Record "Job WIP Warning";
    begin
        JobWIPWarning.DeleteEntries(Rec);
    end;

    procedure DeleteEntriesForJobTask(JobTask: Record "Job Task")
    begin
        SetCurrentKey("Job No.", "Job Task No.");
        SetRange("Job No.", JobTask."Job No.");
        SetRange("Job Task No.", JobTask."Job Task No.");
        SetRange("Posted to G/L", false);
        if not IsEmpty() then
            DeleteAll(true);
    end;
}

