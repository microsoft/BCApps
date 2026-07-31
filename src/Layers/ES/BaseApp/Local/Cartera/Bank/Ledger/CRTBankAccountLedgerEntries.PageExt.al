// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

pageextension 7000157 "CRT BankAccountLedgerEntries" extends "Bank Account Ledger Entries"
{
    layout
    {
        addafter("Document No.")
        {
            field("Bill No."; Rec."Bill No.")
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ToolTip = 'Specifies the number of the bill related to this bank ledger entry.';
            }
        }
    }
}
