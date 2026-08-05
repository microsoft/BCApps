// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Security.User;

page 6981 "Manager Expense Reports"
{
    Caption = 'Manager Expense Reports';
    PageType = List;
    ApplicationArea = Basic, Suite;
    CardPageID = "Manager Expense Report";
    UsageCategory = Tasks;
    RefreshOnActivate = true;
    SourceTable = "Expense Report Header";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the expense report number.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ToolTip = 'Specifies the expense user number for the report.';
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ToolTip = 'Specifies the expense user name for the report.';
                }
                field("Employee Posting Group"; Rec."Employee Posting Group")
                {
                    ToolTip = 'Specifies the posting group that determines how employee transactions are posted.';
                }
                field("Expense Report Date"; Rec."Expense Report Date")
                {
                    ToolTip = 'Specifies the date of the expense report.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date used when the report is posted.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies shortcut dimension 1 for categorizing the report.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies shortcut dimension 2 for categorizing the report.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the approval status of the expense report.';
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
        area(Navigation)
        {
            group("Expense")
            {
                Caption = 'Expense';

                action("Comments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Comments';
                    Image = ViewComments;
                    RunObject = Page "Expense Report Comment Sheet";
                    RunPageLink = "Document Type" = const("Expense Report"), "No." = field("No."), "Document Line No." = const(0);
                    ToolTip = 'Specifies comments for the selected report and lets you add new comments.';
                }
            }
        }
        area(processing)
        {
            group(Action12)
            {
                Caption = 'Release';
                Image = ReleaseDoc;
                action(Release)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Release';
                    Image = ReleaseDoc;
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Releases the selected reports so they continue to the next processing stage. Reopen a released report before changing it.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                    begin
                        CurrPage.SetSelectionFilter(ExpenseReportHeader);

                        Rec.PerformManualRelease(ExpenseReportHeader);
                    end;
                }
                action(Reopen)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Reopens the selected released reports so you can make changes.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                    begin
                        CurrPage.SetSelectionFilter(ExpenseReportHeader);

                        Rec.PerformManualReopen(ExpenseReportHeader);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Release)
            {
                Caption = 'Release';
                ShowAs = SplitButton;

                actionref(Release_Promoted; Release)
                {
                }
                actionref(Reopen_Promoted; Reopen)
                {
                }
            }
            group(Category_Expense)
            {
                Caption = 'Expense';

                actionref(Comments_Promoted; Comments)
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
            UserSetup.Get(UserId());
            if not UserSetup."Unlimited Expense Approval" then
                ExpenseReportApprovalMgmt.FilterExpenseReports(Rec, Rec.FieldNo("Approver Expense User ID"))
        end;
    end;
}