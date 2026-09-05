// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

pageextension 11363 "General Ledger Entries NL" extends "General Ledger Entries"
{
    layout
    {
        addafter(NonDeductibleVATAmount)
        {
            field("Remaining Amount"; Rec."Remaining Amount")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the amount that remains to be applied to before the entry is fully applied.';
                Visible = false;
            }
        }
        addafter("Transaction No.")
        {
            field(Open; Rec.Open)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies if the general ledger entry is open.';
                Visible = false;
            }
        }
    }
}