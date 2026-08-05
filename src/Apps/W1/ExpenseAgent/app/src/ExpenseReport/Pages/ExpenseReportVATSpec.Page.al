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
                field("Reclaim Status"; Rec."Reclaim Status")
                {
                    Caption = 'Reclaim Status';
                    ToolTip = 'Specifies whether the VAT reclaim for this row is pending, approved, or rejected.';
                }
            }
        }
    }
}
