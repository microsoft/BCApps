// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Foundation.BatchProcessing;
using System.Security.User;

page 6997 "Expense Reports"
{
    Caption = 'Expense Reports';
    PageType = List;
    ApplicationArea = Basic, Suite;
    CardPageID = "Expense Report";
    UsageCategory = Lists;
    RefreshOnActivate = true;
    SourceTable = "Expense Report Header";
    Editable = false;

    AboutTitle = 'About expense reports';
    AboutText = 'Create and manage expense reports to document company expenses. Track refundable, reimbursable, and billable expenses, and manage amounts payable to employees.';
    AdditionalSearchTerms = 'Expense Statement, Expense Order, Expense Document, Expense Form, Reimbursement Request, Reimbursement Statement, Cost Report, Spend Report, Receipts Collection';

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
                    ToolTip = 'Specifies the name of the expense user for the report.';
                }
                field("Employee Posting Group"; Rec."Employee Posting Group")
                {
                    ToolTip = 'Specifies the employee posting group used for posting transactions.';
                }
                field("Expense Report Date"; Rec."Expense Report Date")
                {
                    ToolTip = 'Specifies the date of the expense report.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the posting date used when the report is posted.';
                }
                field("Reimbursement Currency Code"; Rec."Reimbursement Currency Code")
                {
                    ToolTip = 'Specifies the value of the Reimbursement Currency Code field.';
                    Visible = false;
                }
                field("Reimbursable Amount"; Rec."Reimbursable Amount")
                {
                    ToolTip = 'Specifies the value of the Reimbursable Amount field.';
                    Visible = false;
                }
                field("Reimbursable Amount (LCY)"; Rec."Reimbursable Amount (LCY)")
                {
                    ToolTip = 'Specifies the value of the Reimbursable Amount (LCY) field.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies dimension 1 used for analytics and posting.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies dimension 2 used for analytics and posting.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the current status of the expense report, for example Draft, Released, or Posted.';
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
                    ToolTip = 'View or add comments for the record.';
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    RunObject = Page "Expense Report Stats";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View statistical information, such as VAT amounts, for the expense report.';
                }
            }
        }
        area(Reporting)
        {
            action("Expense Report Details")
            {
                Caption = 'Expense Report Details';
                ApplicationArea = Basic, Suite;
                Image = Report;
                ToolTip = 'Run the detailed expense report for the selected records.';

                trigger OnAction()
                var
                    ExpenseReportHeader: Record "Expense Report Header";
                begin
                    CurrPage.SetSelectionFilter(ExpenseReportHeader);
                    Report.RunModal(Report::"Expense Report Details", true, false, ExpenseReportHeader);
                end;
            }
            action("Expense Report Summary Page")
            {
                Caption = 'Expense Report Summary Page';
                ApplicationArea = Basic, Suite;
                Image = Report;
                ToolTip = 'Run the summary page report for the selected records.';

                trigger OnAction()
                var
                    ExpenseReportHeader: Record "Expense Report Header";
                begin
                    CurrPage.SetSelectionFilter(ExpenseReportHeader);
                    Report.RunModal(Report::"Expense Report Summary Page", true, false, ExpenseReportHeader);
                end;
            }
            action("Expense Report Cover Page")
            {
                Caption = 'Expense Report Cover Page';
                ApplicationArea = Basic, Suite;
                Image = Report;
                ToolTip = 'Run the cover page report for the selected records.';

                trigger OnAction()
                var
                    ExpenseReportHeader: Record "Expense Report Header";
                begin
                    CurrPage.SetSelectionFilter(ExpenseReportHeader);
                    Report.RunModal(Report::"Expense Report Cover Page", true, false, ExpenseReportHeader);
                end;
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
                    ToolTip = 'Release the document to the next stage of processing. You must reopen the document before you can make changes to it.';

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
                    ToolTip = 'Reopen the document to change it after it has been approved. Approved documents have the Released status and must be opened before they can be changed.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                    begin
                        CurrPage.SetSelectionFilter(ExpenseReportHeader);

                        Rec.PerformManualReopen(ExpenseReportHeader);
                    end;
                }
            }
            group("Posting")
            {
                Caption = 'Posting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Ellipsis = true;
                    Image = PostOrder;
                    ShortCutKey = 'F9';
                    ToolTip = 'Finalize the selected expense reports by posting the amounts to the related accounts in your company books.';

                    trigger OnAction()
                    var
                        ExpenseReportHeader: Record "Expense Report Header";
                        ExpenseReportBatchPostMgt: Codeunit "Expense Report Batch Post Mgt.";
                        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(ExpenseReportHeader);
                        if ExpenseReportHeader.Count > 1 then begin
                            BatchProcessingMgt.SetParametersForPageID(Page::"Expense Reports");

                            ExpenseReportBatchPostMgt.SetBatchProcessor(BatchProcessingMgt);
                            ExpenseReportBatchPostMgt.RunWithUI(ExpenseReportHeader, ExpenseReportHeader.Count, ReadyToPostQst);
                        end else
                            PostDocument();
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
            group(Category_Posting)
            {
                Caption = 'Post';
                ShowAs = SplitButton;

                actionref(Post_Promoted; Post)
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

    var
        ReadyToPostQst: Label 'The number of expense reports that will be posted is %1. \Do you want to continue?', Comment = '%1 - selected count';

    local procedure PostDocument()
    var
        ExpenseReportPost: Codeunit "Expense Report-Post";
    begin
        ExpenseReportPost.PostExpenseReport(Rec);
        CurrPage.Update(false);
    end;
}