// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Sales.Document;

table 1022 "Job Planning Line Invoice"
{
    Caption = 'Project Planning Line Invoice';
    DrillDownPageID = "Job Invoices";
    LookupPageID = "Job Invoices";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            Editable = false;
            TableRelation = Job;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            Editable = false;
            TableRelation = "Job Task"."Job Task No." where("Job No." = field("Job No."));
        }
        field(3; "Job Planning Line No."; Integer)
        {
            Caption = 'Project Planning Line No.';
            Editable = false;
            TableRelation = "Job Planning Line"."Line No." where("Job No." = field("Job No."),
                                                                  "Job Task No." = field("Job Task No."));
        }
        field(4; "Document Type"; Enum "Job Planning Line Invoice Document Type")
        {
            Caption = 'Document Type';
            ToolTip = 'Specifies the information about the type of document. There are four options:';
            Editable = false;
        }
        field(5; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the number associated with the document. For example, if you have created an invoice, the field Specifies the invoice number.';
            Editable = false;
        }
        field(6; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the line number that is linked to the document. Numbers are created sequentially.';
        }
        field(7; "Quantity Transferred"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity Transferred';
            ToolTip = 'Specifies the quantity transferred from the project planning line to the invoice or credit memo.';
            Editable = false;
        }
        field(8; "Transferred Date"; Date)
        {
            Caption = 'Transferred Date';
            ToolTip = 'Specifies the date on which the invoice or credit document was created. The date is set to the posting date you specified when you created the invoice or credit memo.';
            Editable = false;
        }
        field(9; "Invoiced Date"; Date)
        {
            Caption = 'Invoiced Date';
            ToolTip = 'Specifies the date on which the invoice or credit memo was posted.';
            Editable = false;
        }
        field(10; "Invoiced Amount (LCY)"; Decimal)
        {
            Caption = 'Invoiced Amount (LCY)';
            Editable = false;
            AutoFormatType = 0;
            AutoFormatExpression = '';
        }
        field(11; "Invoiced Cost Amount (LCY)"; Decimal)
        {
            Caption = 'Invoiced Cost Amount (LCY)';
            Editable = false;
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(12; "Job Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Ledger Entry No.';
            ToolTip = 'Specifies a link to the project ledger entry that was created when the document was posted.';
            Editable = false;
            TableRelation = "Job Ledger Entry";
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Job Planning Line No.", "Document Type", "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document Type", "Document No.", "Job Ledger Entry No.")
        {
        }
        key(Key3; "Job No.", "Job Planning Line No.", "Job Task No.", "Document Type")
        {
            MaintainSqlIndex = false;
            SumIndexFields = "Quantity Transferred", "Invoiced Amount (LCY)", "Invoiced Cost Amount (LCY)";
        }
    }

    fieldgroups
    {
    }

    procedure InitFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        "Job No." := JobPlanningLine."Job No.";
        "Job Task No." := JobPlanningLine."Job Task No.";
        "Job Planning Line No." := JobPlanningLine."Line No.";
        "Quantity Transferred" := JobPlanningLine."Qty. to Transfer to Invoice";

        OnAfterInitFromJobPlanningLine(Rec, JobPlanningLine);
    end;

    procedure InitFromSales(SalesHeader: Record "Sales Header"; PostingDate: Date; LineNo: Integer)
    begin
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Invoice then
            "Document Type" := "Document Type"::Invoice;
        if SalesHeader."Document Type" = SalesHeader."Document Type"::"Credit Memo" then
            "Document Type" := "Document Type"::"Credit Memo";
        "Document No." := SalesHeader."No.";
        "Line No." := LineNo;
        "Transferred Date" := PostingDate
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromJobPlanningLine(var JobPlanningLineInvoice: Record "Job Planning Line Invoice"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;
}
