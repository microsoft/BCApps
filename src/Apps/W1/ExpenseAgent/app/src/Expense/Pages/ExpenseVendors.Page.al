// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7089 "Expense Vendors"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Expense Vendors';
    PageType = List;
    CardPageID = "Expense Vendor Card";
    SourceTable = "Expense Vendor";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor. The field is either filled automatically from a defined number series, or you enter the number manually because you have enabled manual number entry in the number-series setup.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s name. You can enter a maximum of 30 characters, both numbers and letters.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the matching and approval status of the expense vendor.';
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
                field("Approval Date"; Rec."Approval Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the expense vendor was approved or rejected.';
                }
                field("Approved By"; Rec."Approved By")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the user ID of the accountant who approved or rejected the expense vendor.';
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

                action(Approve)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the selected expense vendor. A new Business Central vendor will be created if not already matched.';

                    trigger OnAction()
                    var
                        ExpenseVendor: Record "Expense Vendor";
                        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                    begin
                        CurrPage.SetSelectionFilter(ExpenseVendor);
                        if ExpenseVendor.FindSet() then
                            repeat
                                ExpenseVendorMatching.Approve(ExpenseVendor);
                            until ExpenseVendor.Next() = 0;
                        CurrPage.Update(false);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the selected expense vendor. Open the card to enter a rejection reason first.';

                    trigger OnAction()
                    var
                        ExpenseVendor: Record "Expense Vendor";
                        ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                    begin
                        CurrPage.SetSelectionFilter(ExpenseVendor);
                        if ExpenseVendor.FindSet() then
                            repeat
                                ExpenseVendorMatching.Reject(ExpenseVendor, ExpenseVendor."Rejection Reason");
                            until ExpenseVendor.Next() = 0;
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
