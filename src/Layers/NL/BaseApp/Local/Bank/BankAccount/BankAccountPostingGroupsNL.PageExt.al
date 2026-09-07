// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

pageextension 11421 "Bank Acc. Posting Grps. NL" extends "Bank Account Posting Groups"
{
    layout
    {
        addafter("G/L Account No.")
        {
            field("Acc.No. Pmt./Rcpt. in Process"; Rec."Acc.No. Pmt./Rcpt. in Process")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the G/L account to which payments/receipts in process are to be posted.';
            }
        }
    }
}
