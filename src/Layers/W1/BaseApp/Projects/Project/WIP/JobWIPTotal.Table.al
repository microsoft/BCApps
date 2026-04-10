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
            ToolTip = 'Specifies the number of the project task that is associated with the project WIP total. The project task number is generally the final task in a group of tasks that is set to Total or the last project task line.';
            NotBlank = true;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
            ValidateTableRelation = false;
        }
        field(4; "WIP Method"; Code[20])
        {
            Caption = 'WIP Method';
            ToolTip = 'Specifies the name of the work in process (WIP) calculation method that is associated with a project. The value in the field comes from the WIP method specified on the project card.';
            Editable = false;
            TableRelation = "Job WIP Method".Code;
        }
        field(5; "WIP Posting Date"; Date)
        {
            Caption = 'WIP Posting Date';
            ToolTip = 'Specifies the date when work in process (WIP) was last calculated and entered in the Project WIP Entries window.';
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
            ToolTip = 'Specifies if there are WIP warnings associated with a project for which you have calculated WIP.';
            FieldClass = FlowField;
        }
        field(9; "Posted to G/L"; Boolean)
        {
            Caption = 'Posted to G/L';
        }
        field(10; "Schedule (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Budget (Total Cost)';
            Editable = false;
        }
        field(11; "Schedule (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Budget (Total Price)';
            Editable = false;
        }
        field(12; "Usage (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Usage (Total Cost)';
            Editable = false;
        }
        field(13; "Usage (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Usage (Total Price)';
            Editable = false;
        }
        field(14; "Contract (Total Cost)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Billable (Total Cost)';
            Editable = false;
        }
        field(15; "Contract (Total Price)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Billable (Total Price)';
            Editable = false;
        }
        field(16; "Contract (Invoiced Price)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Billable (Invoiced Price)';
            Editable = false;
        }
        field(17; "Contract (Invoiced Cost)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Billable (Invoiced Cost)';
            Editable = false;
        }
        field(20; "Calc. Recog. Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Calc. Recog. Sales Amount';
            ToolTip = 'Specifies the calculated sum of recognized sales amounts in the current WIP calculation.';
            Editable = false;
        }
        field(21; "Calc. Recog. Costs Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Calc. Recog. Costs Amount';
            ToolTip = 'Specifies the calculated sum of recognized costs amounts in the current WIP calculation.';
            Editable = false;
        }
        field(30; "Cost Completion %"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Cost Completion %';
            ToolTip = 'Specifies the cost completion percentage for project tasks that have been budgeted in the current WIP calculation.';
            Editable = false;
        }
        field(31; "Invoiced %"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Invoiced %';
            ToolTip = 'Specifies the percentage of contracted project tasks that have been invoiced in the current WIP calculation.';
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

