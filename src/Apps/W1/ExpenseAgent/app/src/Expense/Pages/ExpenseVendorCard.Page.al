// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7088 "Expense Vendor Card"
{
    Caption = 'Expense Vendor Card';
    PageType = Card;
    SourceTable = "Expense Vendor";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s name. You can enter a maximum of 30 characters, both numbers and letters.';
                    ShowMandatory = true;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the matching and approval status of this expense vendor.';
                    StyleExpr = StatusStyleExpr;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Business Central vendor number linked to this expense vendor after matching or approval.';
                }
                field("Registration Number"; Rec."Registration Number")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration number of the vendor. You can enter a maximum of 20 characters, both numbers and letters.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s VAT registration number.';
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID of the accountant who approved or rejected the expense vendor.';
                }
                field("Approval Date"; Rec."Approval Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the expense vendor was approved or rejected.';
                }
                field("Rejection Reason"; Rec."Rejection Reason")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason the expense vendor was rejected. Fill this in before clicking Reject.';
                    MultiLine = true;
                    Editable = Rec.Status <> Rec.Status::Approved;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
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

                action("Request Approval")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Request Approval';
                    Image = SendApprovalRequest;
                    ToolTip = 'Submit this expense vendor for accountant review and approval.';
                    Enabled = (Rec.Status = Rec.Status::Unmatched) or (Rec.Status = Rec.Status::Rejected);

                    trigger OnAction()
                    var
                        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                    begin
                        ExpenseVendorMatching.RequestApproval(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve this expense vendor. A new Business Central vendor will be created if not already matched.';
                    Enabled = Rec.Status <> Rec.Status::Approved;

                    trigger OnAction()
                    var
                        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                    begin
                        ExpenseVendorMatching.Approve(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject this expense vendor. Enter a rejection reason in the Rejection Reason field before clicking this action.';
                    Enabled = Rec.Status <> Rec.Status::Rejected;

                    trigger OnAction()
                    var
                        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                    begin
                        ExpenseVendorMatching.Reject(Rec, Rec."Rejection Reason");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref("Request Approval_Promoted"; "Request Approval") { }
                actionref(Approve_Promoted; Approve) { }
                actionref(Reject_Promoted; Reject) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetStatusStyle();
    end;

    var
        StatusStyleExpr: Text;

    local procedure SetStatusStyle()
    begin
        case Rec.Status of
            Rec.Status::Unmatched:
                StatusStyleExpr := 'Attention';
            Rec.Status::Matched:
                StatusStyleExpr := 'Favorable';
            Rec.Status::"Pending Approval":
                StatusStyleExpr := 'StandardAccent';
            Rec.Status::Approved:
                StatusStyleExpr := 'Strong';
            Rec.Status::Rejected:
                StatusStyleExpr := 'Unfavorable';
        end;
    end;
}
