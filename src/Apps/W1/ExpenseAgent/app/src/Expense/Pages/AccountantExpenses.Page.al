// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7090 "Accountant Expenses"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Accountant Expenses';
    PageType = List;
    CardPageID = Expense;
    SourceTable = Expense;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;

    AboutTitle = 'About Accountant Expenses';
    AboutText = 'Review incoming expenses and their vendor matching status. Expenses that arrive from the AI Agent are automatically matched to existing vendors. Unmatched expenses require an Expense Vendor record to be reviewed and approved before a new Business Central vendor is created.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies a unique number that identifies the expense.';
                }
                field("Expense Date"; Rec."Expense Date")
                {
                    ToolTip = 'Specifies the date the expense occurred.';
                }
                field("Expense User No."; Rec."Expense User No.")
                {
                    ToolTip = 'Specifies the expense user who incurred the expense.';
                }
                field("Merchant Name"; Rec."Merchant Name")
                {
                    ToolTip = 'Specifies the name of the merchant where the expense occurred, as extracted from the receipt.';
                }
                field("Merchant Registration No."; Rec."Merchant Registration No.")
                {
                    ToolTip = 'Specifies the registration number of the merchant, as extracted from the receipt.';
                }
                field("Merchant VAT Registration No."; Rec."Merchant VAT Registration No.")
                {
                    ToolTip = 'Specifies the VAT registration number of the merchant, as extracted from the receipt.';
                }
                field("Expense Vendor No."; Rec."Expense Vendor No.")
                {
                    ToolTip = 'Specifies the expense vendor record created for this expense. Open the expense vendor to review and approve vendor creation.';
                }
                field(VendorStatus; ExpenseVendorStatus)
                {
                    Caption = 'Vendor Status';
                    ToolTip = 'Specifies the matching and approval status of the linked expense vendor.';
                    Editable = false;
                    StyleExpr = VendorStatusStyleExpr;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the total amount of the expense.';
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the current status of the expense.';
                }
            }
        }
        area(factboxes)
        {
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
        area(Navigation)
        {
            action("Expense Vendor")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Expense Vendor';
                Image = Vendor;
                ToolTip = 'Open the expense vendor record linked to this expense to review matching status and approve or reject vendor creation.';
                Enabled = Rec."Expense Vendor No." <> '';

                trigger OnAction()
                var
                    ExpenseVendor: Record "Expense Vendor";
                begin
                    if ExpenseVendor.Get(Rec."Expense Vendor No.") then
                        Page.RunModal(Page::"Expense Vendor Card", ExpenseVendor);
                end;
            }
        }
        area(processing)
        {
            action("Match Vendor")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Match Vendor';
                Image = Process;
                ToolTip = 'Run the vendor matching process for the selected expenses. Matches each expense to an existing Business Central vendor or creates an Expense Vendor record for accountant review.';

                trigger OnAction()
                var
                    Expense: Record Expense;
                    ExpenseVendorMatching: Codeunit "Expense Vendor Matching";
                begin
                    CurrPage.SetSelectionFilter(Expense);
                    if Expense.FindSet(true) then
                        repeat
                            ExpenseVendorMatching.FindOrCreateExpenseVendor(Expense);
                        until Expense.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Navigate)
            {
                Caption = 'Navigate';
                actionref("Expense Vendor_Promoted"; "Expense Vendor") { }
            }
            group(Category_Process)
            {
                Caption = 'Process';
                actionref("Match Vendor_Promoted"; "Match Vendor") { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetVendorStatus();
    end;

    var
        ExpenseVendorStatus: Enum "Expense Vendor Status";
        VendorStatusStyleExpr: Text;

    local procedure SetVendorStatus()
    var
        ExpenseVendor: Record "Expense Vendor";
    begin
        Clear(ExpenseVendorStatus);
        VendorStatusStyleExpr := '';

        if Rec."Expense Vendor No." = '' then begin
            if Rec."Merchant Name" <> '' then
                VendorStatusStyleExpr := 'Attention'
            else
                VendorStatusStyleExpr := '';
            exit;
        end;

        if ExpenseVendor.Get(Rec."Expense Vendor No.") then begin
            ExpenseVendorStatus := ExpenseVendor.Status;
            case ExpenseVendor.Status of
                ExpenseVendor.Status::Unmatched:
                    VendorStatusStyleExpr := 'Attention';
                ExpenseVendor.Status::Matched:
                    VendorStatusStyleExpr := 'Favorable';
                ExpenseVendor.Status::"Pending Approval":
                    VendorStatusStyleExpr := 'StandardAccent';
                ExpenseVendor.Status::Approved:
                    VendorStatusStyleExpr := 'Strong';
                ExpenseVendor.Status::Rejected:
                    VendorStatusStyleExpr := 'Unfavorable';
            end;
        end;
    end;
}
