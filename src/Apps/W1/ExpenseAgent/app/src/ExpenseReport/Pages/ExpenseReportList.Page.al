// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Utilities;
using System.Security.User;

page 6979 "Expense Report List"
{
    Caption = 'Expense Report List';
    PageType = List;
    SourceTable = "Expense Report Header";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Expense User Number field.';
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Expense User Name field.';
                }
                field("Employee Posting Group"; Rec."Employee Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Employee Posting Group field.';
                }
                field("Expense Report Date"; Rec."Expense Report Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Expense Report Date field.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Posting Date field.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Shortcut Dimension 1 Code field.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Shortcut Dimension 2 Code field.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the Status field.';
                }
            }
        }
        area(factboxes)
        {

#if not CLEAN29
#pragma warning disable AL0432
            part("Expense Report Statistics"; "Expense Report Statistics")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
                ObsoleteReason = 'Replaced by Expense Report FactBox';
                ObsoleteState = Pending;
                ObsoleteTag = '29.0';
                Visible = false;
            }
#pragma warning restore AL0432
#endif
            part("Expense Report FactBox"; "Expense Report FactBox")
            {
                ApplicationArea = Basic, Suite;
                UpdatePropagation = Both;
                SubPageLink = "No." = field("No.");
            }
            part(expenseFactbox; "Expense Factbox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expense';
                UpdatePropagation = Both;
                SubPageLink = "Expense Report No." = field("No.");
                Visible = Rec."No." <> '';
            }
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Line")
            {
                Caption = 'Line';
                Image = Line;
                action(ShowDocument)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = EditLines;
                    ShortCutKey = 'Return';
                    ToolTip = 'View or change detailed information about the expense report.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        PageManagement.PageRun(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Card_Promoted; ShowDocument)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UserSetup: Record "User Setup";
        ExpenseReportApprovalMgmt: Codeunit "Expense Report Approval Mgmt";
    begin
        ExpenseAgentSetup.GetRecordOnce();

        if ExpenseAgentSetup."Enable Approval Workflow" then begin
            ExpenseReportApprovalMgmt.GetCurrentUserSetupForApproval(UserSetup);
            if not UserSetup."Unlimited Expense Approval" then
                ExpenseReportApprovalMgmt.FilterExpenseReports(Rec, Rec.FieldNo("Created By"));
        end;
    end;
}