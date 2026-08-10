// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7091 "Accountant Expense Reports"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Accountant Expense Reports';
    PageType = List;
    CardPageID = "Manager Expense Report";
    SourceTable = "Expense Report Header";
    UsageCategory = Tasks;
    RefreshOnActivate = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    AboutTitle = 'About Accountant Expense Reports';
    AboutText = 'Review and approve expense reports submitted by employees. Reports with Pending Approval status are awaiting your decision. You can approve or reject individual reports from this page.';

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
                field("Expense Report Date"; Rec."Expense Report Date")
                {
                    ToolTip = 'Specifies the date of the expense report.';
                }
                field("Submission DateTime"; Rec."Submission DateTime")
                {
                    ToolTip = 'Specifies when the expense report was submitted for approval.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the approval status of the expense report.';
                    StyleExpr = StatusStyleExpr;
                }
                field("Approver Expense User No."; Rec."Approver Expense User No.")
                {
                    ToolTip = 'Specifies the expense user number of the designated approver.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Specifies the total amount of all expenses in the report, in the local currency.';
                }
                field("Has VAT Specification"; Rec."Has VAT Specification")
                {
                    ToolTip = 'Specifies whether this expense report contains VAT specification lines eligible for reclaim.';
                    StyleExpr = VATSpecStyleExpr;
                }
                field("Approved Reclaim VAT (LCY)"; Rec."Approved Reclaim VAT (LCY)")
                {
                    ToolTip = 'Specifies the total VAT amount approved for reclaim for this expense report, in local currency.';
                }
                field("Approved/Rejected DateTime"; Rec."Approved/Rejected DateTime")
                {
                    ToolTip = 'Specifies when the expense report was approved or rejected.';
                }
                field("Approved/Rejected By"; Rec."Approved/Rejected By")
                {
                    ToolTip = 'Specifies the user who approved or rejected the expense report.';
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
            systempart(Links; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(ApprovalActions)
            {
                Caption = 'Approval';
                Image = Approval;

                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the selected expense report.';
                    Enabled = Rec.Status = Rec.Status::"Pending Approval";

                    trigger OnAction()
                    var
                        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
                    begin
                        if ExpenseReportApprovalMgt.ConfirmAction(Enum::"Expense Approval Action"::Approve) then
                            ExpenseReportApprovalMgt.Approve(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the selected expense report.';
                    Enabled = Rec.Status = Rec.Status::"Pending Approval";

                    trigger OnAction()
                    var
                        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
                    begin
                        if ExpenseReportApprovalMgt.ConfirmAction(Enum::"Expense Approval Action"::Reject) then
                            ExpenseReportApprovalMgt.Reject(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Reopen")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reopen';
                    Image = ReOpen;
                    ToolTip = 'Reopen an approved expense report for further processing.';
                    Enabled = (Rec.Status = Rec.Status::Approved) or (Rec.Status = Rec.Status::Rejected);

                    trigger OnAction()
                    var
                        ExpenseReportApprovalMgt: Codeunit "Expense Report Approval Mgmt";
                    begin
                        if ExpenseReportApprovalMgt.ConfirmAction(Enum::"Expense Approval Action"::"Reopen Approved") then
                            ExpenseReportApprovalMgt.ReopenApproved(Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(Comments)
            {
                ApplicationArea = Comments;
                Caption = 'Comments';
                Image = ViewComments;
                RunObject = Page "Expense Report Comment Sheet";
                RunPageLink = "Document Type" = const("Expense Report"), "No." = field("No."), "Document Line No." = const(0);
                ToolTip = 'View or add comments for the selected expense report.';
            }
            action(VATSpecification)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Specification';
                Image = VATLedger;
                ToolTip = 'View and manage VAT specification lines and their reclaim approval for the selected expense report.';
                Enabled = Rec."Has VAT Specification";

                trigger OnAction()
                var
                    ExpRepLineVATSpec: Record "Expense Report Line VAT Spec.";
                    ExpRepLineVATSpecPage: Page "Expense Report Line VAT Spec.";
                begin
                    ExpRepLineVATSpec.SetRange("Document No.", Rec."No.");
                    ExpRepLineVATSpecPage.SetTableView(ExpRepLineVATSpec);
                    ExpRepLineVATSpecPage.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(Statistics)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Statistics';
                Image = Statistics;
                ShortCutKey = 'F7';
                RunObject = Page "Expense Report Stats";
                RunPageLink = "No." = field("No.");
                ToolTip = 'View statistical information, such as VAT amounts, for the selected expense report.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(Approve_Promoted; Approve) { }
                actionref(Reject_Promoted; Reject) { }
                actionref(Reopen_Promoted; Reopen) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navigate';
                actionref(Comments_Promoted; Comments) { }
                actionref(VATSpecification_Promoted; VATSpecification) { }
                actionref(Statistics_Promoted; Statistics) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
        SetVATSpecStyle();
    end;

    var
        StatusStyleExpr: Text;
        VATSpecStyleExpr: Text;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Open:
                StatusStyleExpr := 'Standard';
            Rec.Status::Released:
                StatusStyleExpr := 'Favorable';
            Rec.Status::"Pending Approval":
                StatusStyleExpr := 'Attention';
            Rec.Status::Approved:
                StatusStyleExpr := 'Strong';
            Rec.Status::Rejected:
                StatusStyleExpr := 'Unfavorable';
            else
                StatusStyleExpr := 'Standard';
        end;
    end;

    local procedure SetVATSpecStyle()
    begin
        Rec.CalcFields("Has VAT Specification");
        if Rec."Has VAT Specification" then
            VATSpecStyleExpr := 'Favorable'
        else
            VATSpecStyleExpr := 'Standard';
    end;
}
