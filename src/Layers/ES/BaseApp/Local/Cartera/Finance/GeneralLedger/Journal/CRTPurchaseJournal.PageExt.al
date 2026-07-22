// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

pageextension 7000168 "CRT Purchase Journal" extends "Purchase Journal"
{
    layout
    {
        addafter("Document No.")
        {
            field("Bill No."; Rec."Bill No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies a number for this bill generated from the journal.';
                Visible = false;
            }
        }
        addafter("Applies-to Doc. No.")
        {
            field("Applies-to Bill No."; Rec."Applies-to Bill No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the bill to be settled.';
            }
        }
    }
}
