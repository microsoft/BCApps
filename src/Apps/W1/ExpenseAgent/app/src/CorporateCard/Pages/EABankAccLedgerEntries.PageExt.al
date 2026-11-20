// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Ledger;

pageextension 7442 "EA Bank Acc. Ledger Entries" extends "Bank Account Ledger Entries"
{
    layout
    {
        addafter(Description)
        {
            field("EA Corp Card Trans Entry No."; Rec."EA Corp Card Trans Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the corporate card transaction that created this bank account ledger entry.';
            }
            field("EA Corp Card Settle Entry No."; Rec."EA Corp Card Settle Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the corporate card settlement that created this bank account ledger entry.';
            }
        }
    }
}
