// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Projects.Project.Job;

page 1029 "Job Invoices"
{
    Caption = 'Project Invoices';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Job Planning Line Invoice";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Jobs;
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Jobs;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Visible = ShowDetails;
                }
                field("Quantity Transferred"; Rec."Quantity Transferred")
                {
                    ApplicationArea = Jobs;
                }
                field("Transferred Date"; Rec."Transferred Date")
                {
                    ApplicationArea = All;
                    Visible = ShowDetails;
                }
                field("Invoiced Date"; Rec."Invoiced Date")
                {
                    ApplicationArea = All;
                    Visible = ShowDetails;
                }
                field("Invoiced Amount (LCY)"; Rec."Invoiced Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount (LCY) that was posted from the invoice or credit memo. The amount is calculated based on Quantity, Line Discount %, and Unit Price.';
                }
                field("Invoiced Cost Amount (LCY)"; Rec."Invoiced Cost Amount (LCY)")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the amount of the unit costs that has been posted from the invoice or credit memo. The amount is calculated based on Quantity, Unit Cost, and Line Discount %.';
                }
                field("Job Ledger Entry No."; Rec."Job Ledger Entry No.")
                {
                    ApplicationArea = All;
                    Visible = ShowDetails;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(OpenSalesInvoiceCreditMemo)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Open Sales Invoice/Credit Memo';
                    Ellipsis = true;
                    Image = GetSourceDoc;
                    ToolTip = 'Open the sales invoice or sales credit memo for the selected line.';

                    trigger OnAction()
                    var
                        JobCreateInvoice: Codeunit "Job Create-Invoice";
                    begin
                        JobCreateInvoice.OpenSalesInvoice(Rec);
                        JobCreateInvoice.FindInvoices(Rec, JobNo, JobTaskNo, JobPlanningLineNo, DetailLevel);
                        if Rec.Get(Rec."Job No.", Rec."Job Task No.", Rec."Job Planning Line No.", Rec."Document Type", Rec."Document No.", Rec."Line No.") then;
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(OpenSalesInvoiceCreditMemo_Promoted; OpenSalesInvoiceCreditMemo)
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        ShowDetails := true;
    end;

    trigger OnOpenPage()
    var
        JobCreateInvoice: Codeunit "Job Create-Invoice";
    begin
        JobCreateInvoice.FindInvoices(Rec, JobNo, JobTaskNo, JobPlanningLineNo, DetailLevel);
    end;

    var
        JobNo: Code[20];
        JobTaskNo: Code[20];
        JobPlanningLineNo: Integer;
        DetailLevel: Option All,"Per Job","Per Job Task","Per Job Planning Line";
        ShowDetails: Boolean;

    procedure SetPrJob(Job: Record Job)
    begin
        DetailLevel := DetailLevel::"Per Job";
        JobNo := Job."No.";
    end;

    procedure SetPrJobTask(JobTask: Record "Job Task")
    begin
        DetailLevel := DetailLevel::"Per Job Task";
        JobNo := JobTask."Job No.";
        JobTaskNo := JobTask."Job Task No.";
    end;

    procedure SetPrJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        DetailLevel := DetailLevel::"Per Job Planning Line";
        JobNo := JobPlanningLine."Job No.";
        JobTaskNo := JobPlanningLine."Job Task No.";
        JobPlanningLineNo := JobPlanningLine."Line No.";
    end;

    procedure SetShowDetails(NewShowDetails: Boolean)
    begin
        ShowDetails := NewShowDetails;
    end;
}

