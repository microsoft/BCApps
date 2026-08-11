// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;

codeunit 10600 "Create Expense Posting Grp GB"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpensePostingGroup(ExpensePerDiem(), ExpensePerDiemLbl);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Posting Group", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnInsertRecord(var Rec: Record "Expense Posting Group")
    var
        CreateGBGLAccounts: Codeunit "Create GB GL Accounts";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
        CreateExpensePostingGroup: Codeunit "Create Expense Posting Group";
    begin
        case Rec.Code of
            CreateExpensePostingGroup.ExpenseEntertainment():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.BusinessEntertainingDeductibleName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMeals():
                ValidateRecordFields(Rec, ExpenseGLAccount.MealExpensesDeductibleAccount(), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseMileage():
                ValidateRecordFields(Rec, ExpenseGLAccount.MileageTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseOther():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.MiscExternalExpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
            ExpensePerDiem():
                ValidateRecordFields(Rec, ExpenseGLAccount.PerDiemTravelExpensesAccount(), '', ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseTravel():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherTravelExpensesName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
            CreateExpensePostingGroup.ExpenseRentalCars():
                ValidateRecordFields(Rec, ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.RentalVehiclesName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherIncidentalRevenueName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.OtherPrepaidExpensesAndAccruedIncomeName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()), ExpenseGLAccount.FindGLAccountByName(CreateGBGLAccounts.PayableInvoiceRoundingName()));
        end;
    end;

    local procedure ValidateRecordFields(var ExpensePostingGroup: Record "Expense Posting Group"; RefundableDebitAccount: Code[20]; NonRefundableDebitAccount: Code[20]; PrepaymentCreditAccount: Code[20]; ExpenseDebitRoundingAccount: Code[20]; ExpenseCreditRoundingAccount: Code[20])
    begin
        ExpensePostingGroup.Validate("Refundable Debit Account", RefundableDebitAccount);
        ExpensePostingGroup.Validate("Non-Refundable Debit Account", NonRefundableDebitAccount);
        ExpensePostingGroup.Validate("Prepayment Credit Account", PrepaymentCreditAccount);
        ExpensePostingGroup.Validate("Debit Rounding Account", ExpenseDebitRoundingAccount);
        ExpensePostingGroup.Validate("Credit Rounding Account", ExpenseCreditRoundingAccount);
    end;

    var
        ExpensePERDIEMTok: Label 'EXPENSE-PERDIEM', MaxLength = 20, Locked = true;
        ExpensePerDiemLbl: Label 'Expense - Per Diem', MaxLength = 100;

    procedure ExpensePerDiem(): Code[20]
    begin
        exit(ExpensePERDIEMTok);
    end;
}