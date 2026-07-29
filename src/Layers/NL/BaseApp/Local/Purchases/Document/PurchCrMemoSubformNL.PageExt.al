// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

pageextension 11324 PurchCrMemoSubformNL extends "Purch. Cr. Memo Subform"
{
    layout
    {
        addafter(NonDeductibleVATAmount)
        {
            field(Amount; Rec.Amount)
            {
                ApplicationArea = Basic, Suite;
                BlankZero = true;
                ToolTip = 'Specifies the sum of amounts in the Line Amount field on the document lines.';
                Visible = false;
            }
            field("Amount Including VAT"; Rec."Amount Including VAT")
            {
                ApplicationArea = Basic, Suite;
                BlankZero = true;
                ToolTip = 'Specifies the net amount, including VAT, for this line.';
                Visible = false;

                trigger OnValidate()
                begin
                    DeltaUpdateTotals();
                end;
            }
        }
    }
}
