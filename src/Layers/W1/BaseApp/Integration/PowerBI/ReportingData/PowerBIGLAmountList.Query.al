// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;

query 53 "Power BI GL Amount List"
{
    Caption = 'Power BI GL Amount List';

    elements
    {
        dataitem(G_L_Account; "G/L Account")
        {
            column(GL_Account_No; "No.")
            {
            }
            column(Name; Name)
            {
            }
            column(Account_Type; "Account Type")
            {
                ColumnFilter = Account_Type = const(Posting);
            }
            column(Debit_Credit; "Debit/Credit")
            {
            }
            dataitem(G_L_Entry; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = G_L_Account."No.";
                column(Posting_Date; "Posting Date")
                {
                }
                column(Amount; Amount)
                {
                }
                column(Entry_No; "Entry No.")
                {
                }
            }
        }
    }
}

