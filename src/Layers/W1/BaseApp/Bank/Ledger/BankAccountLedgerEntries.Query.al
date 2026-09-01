// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Ledger;

using Microsoft.Bank.BankAccount;

/// <summary>
/// Query object providing optimized read-only access to bank account ledger entry data.
/// Exposes key bank account ledger entry fields for reporting, analysis, and external integrations
/// with improved performance compared to table-based data access.
/// </summary>
query 264 "Bank Account Ledger Entries"
{
    Caption = 'Bank Account Ledger Entries';

    elements
    {
        dataitem(Bank_Account_Ledger_Entry; "Bank Account Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Transaction_No; "Transaction No.")
            {
            }
            column(Bank_Account_No; "Bank Account No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Source_Code; "Source Code")
            {
            }
            column(Reason_Code; "Reason Code")
            {
            }
            column(Open; Open)
            {
            }
            column(Currency_Code; "Currency Code")
            {
            }
            column(Amount; Amount)
            {
            }
            column(Debit_Amount; "Debit Amount")
            {
            }
            column(Credit_Amount; "Credit Amount")
            {
            }
            column(Remaining_Amount; "Remaining Amount")
            {
            }
            column(Amount_LCY; "Amount (LCY)")
            {
            }
            column(Debit_Amount_LCY; "Debit Amount (LCY)")
            {
            }
            column(Credit_Amount_LCY; "Credit Amount (LCY)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Bank_Account; "Bank Account")
            {
                DataItemLink = "No." = Bank_Account_Ledger_Entry."Bank Account No.";
                column(Bank_Account_Name; Name)
                {
                }
            }
        }
    }
}

