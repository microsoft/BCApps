// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.HumanResources.Employee;

pageextension 6901 "Exp. Employee Posting Groups" extends "Employee Posting Groups"
{
    layout
    {
        addafter("Credit Rounding Account")
        {
            field("Expense Report Payable Account"; Rec."Expense Report Payable Account")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies the general ledger account used to post cash transactions.';
            }
            field("Expense Payable Bank Paid Acc."; Rec."Expense Payable Bank Paid Acc.")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies the general ledger account used to post bank paid transactions.';
            }
            field("Expense Payable Card Paid Acc."; Rec."Expense Payable Card Paid Acc.")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies the general ledger account used to post card paid transactions.';
            }
            field("Exp. Report Prepayment Account"; Rec."Exp. Report Prepayment Account")
            {
                ApplicationArea = BasicHR;
                ToolTip = 'Specifies the general ledger account used to post expense prepayments.';
            }
        }
    }
}