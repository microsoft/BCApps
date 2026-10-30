// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Extends the Customer Ledger Entries page with NL-specific telebanking fields.
/// </summary>
pageextension 11470 "Customer Ledger Entries NL" extends "Customer Ledger Entries"
{
    layout
    {
        addafter("Remaining Amt. (LCY)")
        {
            field("Payments in Process"; Rec."Payments in Process")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the total amount of payments/collections in process.';
            }
        }
        addafter("G/L Register No.")
        {
            field("Transaction Mode Code"; Rec."Transaction Mode Code")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the way a ledger entry can be paid or collected through telebanking.';
            }
        }
    }
}
