// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.HumanResources.Employee;

tableextension 6900 "Exp. Employee Posting Group" extends "Employee Posting Group"
{
    fields
    {
        field(6500; "Expense Report Payable Account"; Code[20])
        {
            Caption = 'Expense Payable Cash Account';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
        field(6501; "Exp. Report Prepayment Account"; Code[20])
        {
            Caption = 'Expense Prepayment Account';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
        field(6502; "Expense Payable Bank Paid Acc."; Code[20])
        {
            Caption = 'Expense Payable Bank Paid Account';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
        field(6503; "Expense Payable Card Paid Acc."; Code[20])
        {
            Caption = 'Expense Payable Card Paid Account';
            TableRelation = "G/L Account";
            DataClassification = CustomerContent;
        }
    }

    var
        PostingSetupMgt: Codeunit PostingSetupManagement;

    procedure GetExpenseReportPayablesAccount(): Code[20]
    begin
        if "Expense Report Payable Account" = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Expense Report Payable Account"));

        exit("Expense Report Payable Account");
    end;

    procedure GetExpensePayableBankPaidAccount(): Code[20]
    begin
        if "Expense Payable Bank Paid Acc." = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Expense Payable Bank Paid Acc."));

        exit("Expense Payable Bank Paid Acc.");
    end;

    procedure GetExpensePayableCardPaidAccount(): Code[20]
    begin
        if "Expense Payable Card Paid Acc." = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Expense Payable Card Paid Acc."));

        exit("Expense Payable Card Paid Acc.");
    end;

    procedure GetExpenseReportPrepaymentAccount(): Code[20]
    begin
        if "Exp. Report Prepayment Account" = '' then
            PostingSetupMgt.LogEmplPostingGroupFieldError(Rec, FieldNo("Exp. Report Prepayment Account"));

        exit("Exp. Report Prepayment Account");
    end;
}