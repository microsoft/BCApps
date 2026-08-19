// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Compact read-only summary of "Exp. Report Line VAT Spec." rows for a given Expense Report Line.
/// Used as a FactBox on the Expense Report Lines page.
/// </summary>
page 7096 "Expense Report VAT Spec."
{
    Caption = 'VAT Specification';
    PageType = ListPart;
    SourceTable = "Expense Report Line VAT Spec.";
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
                    ToolTip = 'Specifies the reclaimable VAT amount for this row.';
                }
                field("Reclaim VAT Amount (LCY)"; Rec."Reclaim VAT Amount (LCY)")
                {
                    Caption = 'Reclaim VAT Amount (LCY)';
                    ToolTip = 'Specifies the reclaimable VAT amount for this row.';
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
        ExpenseReportHeader: Record "Expense Report Header";
    begin
        if Rec.GetFilter("Document No.") = '' then
            exit;

        ExpenseReportHeader.SetLoadFields("Reimbursement Currency Code");
        if ExpenseReportHeader.Get(Rec.GetRangeMin("Document No.")) then
            ShowRCYFields := ExpenseReportHeader."Reimbursement Currency Code" <> '';
    end;

    var
        ShowRCYFields: Boolean;
}
