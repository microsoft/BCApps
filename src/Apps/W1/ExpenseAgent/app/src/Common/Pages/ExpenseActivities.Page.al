// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7140 "Expense Activities"
{
    Caption = 'Expense Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Expense Activities Cue";

    layout
    {
        area(Content)
        {
            cuegroup("Expense Reports")
            {
                Caption = 'Expense Reports';

                field("Opened Expense Reports"; Rec."Opened Expense Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of open expense reports.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::Open);
                    end;
                }
                field("Released Expense Reports"; Rec."Released Expense Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of released expense reports.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::Released);
                    end;
                }
                field("Pending Approval Exp. Reports"; Rec."Pending Approval Exp. Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of expense reports that are pending approval.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::"Pending Approval");
                    end;
                }
                field("Approved Expense Reports"; Rec."Approved Expense Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of approved expense reports.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::Approved);
                    end;
                }
                field("Rejected Expense Reports"; Rec."Rejected Expense Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of rejected expense reports.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::Rejected);
                    end;
                }
                field("Processed for Payment Exp."; Rec."Processed for Payment Exp.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of expense reports that are processed for payment.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::"Processed for Payment");
                    end;
                }
                field("Completed Expense Reports"; Rec."Completed Expense Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of completed expense reports.';

                    trigger OnDrillDown()
                    begin
                        DrillDownExpenseReports("Expense Report Status"::Completed);
                    end;
                }
            }
            cuegroup(Expenses)
            {
                Caption = 'Expenses';

                field("Released Expenses"; Rec."Released Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of released expenses.';

                    trigger OnDrillDown()
                    var
                        Expense: Record Expense;
                    begin
                        Expense.SetRange(Status, "Expense Status"::Released);
                        Page.Run(Page::Expenses, Expense);
                    end;
                }
                field("Policy Violated Expenses"; Rec."Policy Violated Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of expenses with policy violations.';

                    trigger OnDrillDown()
                    var
                        Expense: Record Expense;
                    begin
                        Expense.SetRange("Rule Violations", true);
                        Page.Run(Page::Expenses, Expense);
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    local procedure DrillDownExpenseReports(ReportStatus: Enum "Expense Report Status")
    var
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        ExpenseReportHeader.SetRange(Status, ReportStatus);
        Page.Run(Page::"Expense Reports", ExpenseReportHeader);
    end;
}
