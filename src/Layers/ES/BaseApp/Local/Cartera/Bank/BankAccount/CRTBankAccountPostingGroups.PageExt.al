// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

pageextension 7000154 "CRT BankAccountPostingGroups" extends "Bank Account Posting Groups"
{
    layout
    {
        addafter("G/L Account No.")
        {
            field("Liabs. for Disc. Bills Acc."; Rec."Liabs. for Disc. Bills Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the general ledger account that will reflect the debt due to the discounting of bills for this bank general ledger group.';
            }
            field("Bank Services Acc."; Rec."Bank Services Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the general ledger account that will reflect the banking expenses for document discount management services for this group.';
            }
            field("Discount Interest Acc."; Rec."Discount Interest Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the general ledger account that will reflect the interest charged for discounting of bills/invoices, for this group.';
            }
            field("Rejection Expenses Acc."; Rec."Rejection Expenses Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the general ledger account that will reflect the costs derived from the rejection of documents for this group.';
            }
            field("Liabs. for Factoring Acc."; Rec."Liabs. for Factoring Acc.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the general ledger account that will reflect the debt due to the discounting of invoices for this group.';
            }
        }
    }
}
