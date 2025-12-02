// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Purchases.Payables;

pageextension 685 "Vend. Ledg. Entries Paym. Prac" extends "Vendor Ledger Entries"
{
    layout
    {
        addafter("On Hold")
        {
            field("Overdue Due to Dispute"; Rec."Overdue Due to Dispute")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                Visible = false;
            }
            field("SCF Payment Date"; Rec."SCF Payment Date")
            {
                ApplicationArea = Basic, Suite;
                Editable = true;
                Visible = false;
            }
        }
    }
}
