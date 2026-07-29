// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

pageextension 11318 VendorLedgerEntriesNL extends "Vendor Ledger Entries"
{
    layout
    {
        addafter("Remaining Amt. (LCY)")
        {
            field("Payments in Process"; Rec."Payments in Process")
            {
                ApplicationArea = Basic, Suite;
            }
        }

        addafter("Payment Method Code")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
            }
            field("Recipient Bank Account"; Rec."Recipient Bank Account")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }
}
