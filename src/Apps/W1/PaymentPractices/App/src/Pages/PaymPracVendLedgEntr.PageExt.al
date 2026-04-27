// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;

pageextension 681 "Paym. Prac. Vend. Ledg. Entr." extends "Vendor Ledger Entries"
{
    layout
    {
        addafter("Invoice Received Date")
        {
            field("SCF Payment Date"; Rec."SCF Payment Date")
            {
                ApplicationArea = Basic, Suite;
                Visible = false;
            }
        }
    }
}
