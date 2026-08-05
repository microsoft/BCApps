// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8201 "Create Expense Payment Method"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpensePaymentMethod(Bank(), BankTransferLbl, Enum::"Expense Reimbursement Type"::"Company Paid");
        ContosoExpenseAgent.InsertExpensePaymentMethod(Card(), CardPaymentLbl, Enum::"Expense Reimbursement Type"::"Credit Card");
        ContosoExpenseAgent.InsertExpensePaymentMethod(Cash(), CashPaymentLbl, Enum::"Expense Reimbursement Type"::"Employee Paid");
    end;

    var
        BankTok: Label 'BANK', MaxLength = 10, Locked = true;
        CardTok: Label 'CARD', MaxLength = 10, Locked = true;
        CashTok: Label 'CASH', MaxLength = 10, Locked = true;
        BankTransferLbl: Label 'Bank Transfer', MaxLength = 100;
        CardPaymentLbl: Label 'Card payment', MaxLength = 100;
        CashPaymentLbl: Label 'Cash payment', MaxLength = 100;

    procedure Bank(): Code[10]
    begin
        exit(BankTok);
    end;

    procedure Card(): Code[10]
    begin
        exit(CardTok);
    end;

    procedure Cash(): Code[10]
    begin
        exit(CashTok);
    end;
}