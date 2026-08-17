// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Compact read-only summary of the captured "Expense VAT Specification" rows for a given
/// Expense. Surfaced as a FactBox on the Expense card so users can see the original-invoice
/// VAT box at a glance without opening the full specification page.
/// </summary>
page 7080 "Expense VAT Spec. FactBox"
{
    Caption = 'VAT Specification';
    PageType = ListPart;
    SourceTable = "Expense VAT Specification";
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
                    ToolTip = 'Specifies the VAT rate captured from the invoice.';
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                    Caption = 'VAT Base Amount';
                    ToolTip = 'Specifies the net amount this VAT rate applies to.';
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    Caption = 'VAT Amount';
                    ToolTip = 'Specifies the VAT amount captured from the invoice for this rate.';
                }
                field(Source; Rec.Source)
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies the provenance of this row (Agent / Manual / Override).';
                }
            }
        }
    }
}
