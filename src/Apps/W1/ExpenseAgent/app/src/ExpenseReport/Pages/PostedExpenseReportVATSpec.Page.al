// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Compact read-only summary of "Posted Exp. Rep. Line VAT Spec" rows for a given Posted Expense Report.
/// Used as a part on the Posted Expense Report Statistics page.
/// </summary>
page 7093 "Posted Expense Report VAT Spec"
{
    Caption = 'VAT Specification';
    PageType = ListPart;
    SourceTable = "Posted Exp. Rep. Line VAT Spec";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    ApplicationArea = Basic, Suite;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Category"; Rec."Expense Category")
                {
                    Caption = 'Expense Category Code';
                    ToolTip = 'Specifies the expense category code for this VAT row.';
                }
                field("Expense Subcategory"; Rec."Expense Subcategory")
                {
                    Caption = 'Expense Subcategory Code';
                    ToolTip = 'Specifies the expense subcategory code for this VAT row.';
                }
                field("VAT %"; Rec."VAT %")
                {
                    Caption = 'VAT %';
                    ToolTip = 'Specifies the VAT rate.';
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    Caption = 'VAT Base Amount';
                    ToolTip = 'Specifies the net amount this VAT rate applies to.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the VAT amount for this rate.';
                }
                field("Amount (RCY)"; Rec."Amount (RCY)")
                {
                    Caption = 'Amount (RCY)';
                    ToolTip = 'Specifies the total amount for this rate in reimbursement currency.';
                    Visible = ShowRCYFields;
                }
                field("VAT Base Amount (RCY)"; Rec."VAT Base Amount (RCY)")
                {
                    Caption = 'VAT Base Amount (RCY)';
                    ToolTip = 'Specifies the net amount this VAT rate applies to in reimbursement currency.';
                    Visible = ShowRCYFields;
                }
                field("VAT Amount (RCY)"; Rec."VAT Amount (RCY)")
                {
                    Caption = 'VAT Amount (RCY)';
                    ToolTip = 'Specifies the VAT amount for this rate in reimbursement currency.';
                    Visible = ShowRCYFields;
                }
                field(Reclaimable; Rec.Reclaimable)
                {
                    Caption = 'Reclaimable';
                    ToolTip = 'Specifies whether this VAT row is reclaimable.';
                }
                field("Reclaim %"; Rec."Reclaim %")
                {
                    Caption = 'Reclaim %';
                    ToolTip = 'Specifies the reclaim percentage.';
                }
                field("Reclaim VAT Amount"; Rec."Reclaim VAT Amount")
                {
                    Caption = 'Reclaim VAT Amount';
                }
                field("Reclaim VAT Amount (LCY)"; Rec."Reclaim VAT Amount (LCY)")
                {
                    Caption = 'Reclaim VAT Amount (LCY)';
                }
                field("Reclaim VAT Amount (RCY)"; Rec."Reclaim VAT Amount (RCY)")
                {
                    Caption = 'Reclaim VAT Amount (RCY)';
                    ToolTip = 'Specifies the reclaimable VAT amount for this row in reimbursement currency.';
                    Visible = ShowRCYFields;
                }
                field("Reclaim Status"; Rec."Reclaim Status")
                {
                    Caption = 'Reclaim Status';
                    ToolTip = 'Specifies whether the VAT reclaim for this row is pending, approved, or rejected.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PostedExpenseReportHeader: Record "Posted Expense Report Header";
    begin
        if Rec.GetFilter("Expense Report No.") = '' then
            exit;

        PostedExpenseReportHeader.SetLoadFields("Reimbursement Currency Code");
        if PostedExpenseReportHeader.Get(Rec.GetRangeMin("Expense Report No.")) then
            ShowRCYFields := PostedExpenseReportHeader."Reimbursement Currency Code" <> '';
    end;

    var
        ShowRCYFields: Boolean;
}
